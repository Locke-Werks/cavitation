//! The inbound half.
//!
//! Nothing in the app received anything before this: the APS connection was
//! established and the IMClient constructed, but no one pumped it. This task
//! drains APS, hands each frame to the IMClient to decrypt and assemble, and
//! writes whatever comes out into SQLite so the UI's existing storage-backed
//! models pick it up on the next refresh.

use std::sync::Arc;

use parking_lot::Mutex;
use rustpush::{Message, MessageInst, MessageParts};

use crate::events::{Event, EventBus};
use crate::session::AuthSession;
use crate::storage::{MessageRow, Storage, SERVICE_IMESSAGE, SERVICE_SMS};

/// A chat guid derived from who is in it.
///
/// Apple identifies a conversation by its participant set, not by an id we are
/// given, so the same set has to hash to the same guid every time or a reply
/// lands in a second copy of the thread. Sorting before joining is what makes
/// that stable.
fn chat_guid_for(participants: &[String], is_imessage: bool) -> String {
    let mut sorted: Vec<String> = participants.iter().map(|p| p.to_lowercase()).collect();
    sorted.sort();
    sorted.dedup();
    let prefix = if is_imessage { "imessage" } else { "sms" };
    format!("{prefix};{}", sorted.join(","))
}

fn epoch_seconds(sent_timestamp_ms: u64) -> i64 {
    (sent_timestamp_ms / 1000) as i64
}

/// Writes one assembled message into storage and announces it.
fn store_message(
    storage: &Arc<Mutex<Storage>>,
    events: &EventBus,
    inst: &MessageInst,
    parts: &MessageParts,
) -> anyhow::Result<()> {
    let conversation = inst
        .conversation
        .as_ref()
        .ok_or_else(|| anyhow::anyhow!("message with no conversation"))?;

    let is_imessage = !inst.message.is_sms();
    let chat_guid = chat_guid_for(&conversation.participants, is_imessage);
    let sender = inst.sender.clone().unwrap_or_default();

    let store = storage.lock();

    let title = conversation.cv_name.clone().unwrap_or_default();
    let service = if is_imessage { SERVICE_IMESSAGE } else { SERVICE_SMS };
    store.upsert_chat(
        &chat_guid,
        &title,
        service,
        conversation.participants.len() > 2,
    )?;

    // Every participant becomes a handle so the sidebar can show names rather
    // than raw addresses.
    let mut handle_ids = Vec::new();
    for address in &conversation.participants {
        handle_ids.push(store.upsert_handle(address, service, "")?);
    }
    store.set_chat_participants(&chat_guid, &handle_ids)?;

    let handle_id = if sender.is_empty() {
        None
    } else {
        Some(store.upsert_handle(&sender, service, "")?)
    };

    let text = parts.raw_text();
    let row = MessageRow {
        guid: inst.id.clone(),
        chat_guid: chat_guid.clone(),
        handle_id,
        sender_address: sender,
        sender_display_name: String::new(),
        text: text.clone(),
        subject: String::new(),
        is_from_me: false,
        date: epoch_seconds(inst.sent_timestamp),
        date_read: 0,
        date_edited: 0,
        is_unsent: false,
        has_attachments: parts.has_attachments(),
        thread_origin_guid: String::new(),
    };
    store.insert_message(&row)?;
    drop(store);

    events.send(Event::MessageArrived {
        chat_guid,
        message_guid: inst.id.clone(),
    });
    Ok(())
}

/// Runs until the APS connection closes. Spawned once, after the IMClient is
/// built.
pub async fn run(session: Arc<AuthSession>, storage: Arc<Mutex<Storage>>, events: EventBus) {
    let client = match session.im_client.lock().clone() {
        Some(c) => c,
        None => {
            events.send(Event::Warn("receive loop started with no IMClient".into()));
            return;
        }
    };

    let mut stream = session.conn.subscribe().await;
    events.send(Event::Info("listening for messages".into()));

    loop {
        let frame = match stream.recv().await {
            Ok(f) => f,
            // Lagged means frames were dropped because we fell behind; the
            // connection is still good, so keep going rather than tearing the
            // loop down.
            Err(tokio::sync::broadcast::error::RecvError::Lagged(n)) => {
                events.send(Event::Warn(format!("receive loop fell behind, dropped {n}")));
                continue;
            }
            Err(_) => break,
        };

        match client.handle(frame).await {
            Ok(Some(inst)) => {
                match &inst.message {
                    Message::Message(normal) => {
                        let parts = normal.parts.clone();
                        if let Err(e) = store_message(&storage, &events, &inst, &parts) {
                            events.send(Event::Error(format!("storing message: {e}")));
                        }
                    }
                    Message::Typing(is_typing, _) => {
                        if let Some(conv) = &inst.conversation {
                            events.send(Event::TypingStatusChanged {
                                chat_guid: chat_guid_for(&conv.participants, !inst.message.is_sms()),
                                is_typing: *is_typing,
                            });
                        }
                    }
                    // Delivery and read receipts, reactions, edits and unsends
                    // all arrive here too. They need their own storage
                    // handling; until then they are logged rather than
                    // silently dropped, so it is obvious they are landing.
                    other => {
                        log::debug!("unhandled inbound message: {:?}", std::mem::discriminant(other));
                    }
                }
            }
            Ok(None) => {}
            Err(e) => events.send(Event::Warn(format!("decoding inbound message: {e:?}"))),
        }
    }

    events.send(Event::Warn("receive loop stopped".into()));
}
