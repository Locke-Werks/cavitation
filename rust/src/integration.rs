use std::fs::File;
use std::io::Seek;
use std::path::Path;
use std::sync::Arc;

use anyhow::{anyhow, bail, Result};
use rustpush::{
    Attachment, ConversationData, IMClient, IndexedMessagePart, LoginState, MMCSFile, Message,
    MessageInst, MessagePart, MessageParts, MessageType, NormalMessage,
};
use uuid::Uuid;

use crate::session::{self, hash_password, AuthSession};

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AuthState {
    NeedsHardwarePairing,
    NeedsCredentials,
    AuthenticatingAccount,
    NeedsTwoFactor,
    NeedsSmsTwoFactor,
    NeedsDeviceTwoFactor,
    NeedsExtraStep(String),
    Ready,
    Errored(String),
}

impl AuthState {
    pub fn label(&self) -> String {
        match self {
            AuthState::NeedsHardwarePairing => "needs_pairing".into(),
            AuthState::NeedsCredentials => "needs_credentials".into(),
            AuthState::AuthenticatingAccount => "authenticating".into(),
            AuthState::NeedsTwoFactor => "needs_2fa".into(),
            AuthState::NeedsSmsTwoFactor => "needs_sms_2fa".into(),
            AuthState::NeedsDeviceTwoFactor => "needs_device_2fa".into(),
            AuthState::NeedsExtraStep(s) => format!("needs_extra:{s}"),
            AuthState::Ready => "ready".into(),
            AuthState::Errored(e) => format!("error:{e}"),
        }
    }

    pub fn from_login_state(ls: &LoginState) -> Self {
        match ls {
            LoginState::LoggedIn => AuthState::Ready,
            LoginState::Needs2FAVerification => AuthState::NeedsTwoFactor,
            LoginState::NeedsSMS2FA => AuthState::NeedsSmsTwoFactor,
            LoginState::NeedsSMS2FAVerification(_) => AuthState::NeedsSmsTwoFactor,
            LoginState::NeedsDevice2FA => AuthState::NeedsDeviceTwoFactor,
            LoginState::NeedsExtraStep(s) => AuthState::NeedsExtraStep(s.clone()),
            LoginState::NeedsLogin => AuthState::NeedsCredentials,
        }
    }
}

pub async fn authenticate_apple_id(
    session: &AuthSession,
    apple_id: &str,
    password: &str,
) -> Result<LoginState> {
    if apple_id.is_empty() || password.is_empty() {
        bail!("apple_id and password are required");
    }
    let hashed = hash_password(password);
    let mut account = session.account.lock().await;
    let state = account
        .login_email_pass(apple_id, &hashed)
        .await
        .map_err(|e| anyhow!("login_email_pass: {e:?}"))?;
    log::info!("login_email_pass → {}", session::login_state_label(&state));
    Ok(state)
}

pub async fn submit_2fa_code(session: &AuthSession, code: &str) -> Result<LoginState> {
    if code.is_empty() {
        bail!("2fa code is required");
    }
    let mut account = session.account.lock().await;
    let state = account
        .verify_2fa(code.to_string())
        .await
        .map_err(|e| anyhow!("verify_2fa: {e:?}"))?;
    log::info!("verify_2fa → {}", session::login_state_label(&state));
    Ok(state)
}

fn im_client(session: &AuthSession) -> Result<Arc<IMClient>> {
    session
        .im_client
        .lock()
        .clone()
        .ok_or_else(|| anyhow!("not signed in: complete pairing and Apple ID sign-in first"))
}

/// The handle we send as. IDS registers one or more (an Apple ID and any
/// verified phone numbers); the first is the account's own address.
async fn sender_handle(client: &IMClient) -> Result<String> {
    client
        .identity
        .get_handles()
        .await
        .first()
        .cloned()
        .ok_or_else(|| anyhow!("no registered IDS handle"))
}

/// Apple wants a Uniform Type Identifier alongside the MIME type. Getting it
/// wrong mostly costs the preview on the receiving side rather than the send,
/// so unknown types fall back to public.data rather than failing.
fn uti_for(mime: &str) -> &'static str {
    match mime {
        "image/png" => "public.png",
        "image/jpeg" => "public.jpeg",
        "image/gif" => "com.compuserve.gif",
        "image/heic" => "public.heic",
        "image/webp" => "org.webmproject.webp",
        "video/mp4" => "public.mpeg-4",
        "video/quicktime" => "com.apple.quicktime-movie",
        "audio/mpeg" => "public.mp3",
        "audio/mp4" => "public.mpeg-4-audio",
        "application/pdf" => "com.adobe.pdf",
        "text/plain" => "public.plain-text",
        _ => "public.data",
    }
}

/// Uploads one file to MMCS and returns it as a message part.
///
/// The file is read twice on purpose: prepare_put streams it to compute the
/// chunk signature, then the upload streams it again. Hence the rewind, which
/// is what the upstream implementation does too.
async fn attachment_part(
    session: &AuthSession,
    path: &str,
    mime: &str,
) -> Result<IndexedMessagePart> {
    let p = Path::new(path);
    let name = p
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| "attachment".to_string());

    let mut file = File::open(p).map_err(|e| anyhow!("opening {path}: {e}"))?;
    let prepared = MMCSFile::prepare_put(&mut file)
        .await
        .map_err(|e| anyhow!("preparing upload for {name}: {e:?}"))?;
    file.rewind()?;

    let attachment = Attachment::new_mmcs(
        &session.conn,
        &prepared,
        file,
        mime,
        uti_for(mime),
        &name,
        |_sent, _total| {},
    )
    .await
    .map_err(|e| anyhow!("uploading {name}: {e:?}"))?;

    Ok(IndexedMessagePart { part: MessagePart::Attachment(attachment), idx: None, ext: None })
}

async fn send_parts(
    session: &AuthSession,
    participant_addresses: &[String],
    parts: Vec<IndexedMessagePart>,
) -> Result<String> {
    if participant_addresses.is_empty() {
        bail!("no participants for this conversation");
    }

    let client = im_client(session)?;
    let sender = sender_handle(&client).await?;

    let mut normal = NormalMessage::new(String::new(), MessageType::IMessage);
    normal.parts = MessageParts(parts);

    let conversation = ConversationData {
        participants: participant_addresses.to_vec(),
        cv_name: None,
        sender_guid: Some(Uuid::new_v4().to_string()),
        after_guid: None,
    };

    let mut msg = MessageInst::new(conversation, &sender, Message::Message(normal));
    let job = client
        .send(&mut msg)
        .await
        .map_err(|e| anyhow!("send: {e:?}"))?;

    // send() returns once the message is queued; the handle resolves when
    // every recipient has been delivered to. Awaiting it means a failed
    // delivery surfaces as a failed send rather than a silent drop.
    if let Some(handle) = job.handle {
        handle
            .await
            .map_err(|e| anyhow!("delivery task: {e:?}"))?
            .map_err(|e| anyhow!("delivery: {e:?}"))?;
    }

    Ok(msg.id)
}

pub async fn send_imessage(
    _chat_guid: &str,
    participant_addresses: &[String],
    text: &str,
    session: &AuthSession,
) -> Result<String> {
    let parts = vec![IndexedMessagePart {
        part: MessagePart::Text(text.to_string(), Default::default()),
        idx: None,
        ext: None,
    }];
    send_parts(session, participant_addresses, parts).await
}

pub async fn send_imessage_with_attachments(
    _chat_guid: &str,
    participant_addresses: &[String],
    text: &str,
    attachment_paths: &[String],
    mime_types: &[String],
    session: &AuthSession,
) -> Result<String> {
    let mut parts: Vec<IndexedMessagePart> = Vec::new();

    // Attachments lead, text trails. That is the order iMessage itself uses,
    // and a caption below the image is what the other end expects to see.
    for (i, path) in attachment_paths.iter().enumerate() {
        let mime = mime_types.get(i).map(String::as_str).unwrap_or("application/octet-stream");
        parts.push(attachment_part(session, path, mime).await?);
    }

    if !text.is_empty() {
        parts.push(IndexedMessagePart {
            part: MessagePart::Text(text.to_string(), Default::default()),
            idx: None,
            ext: None,
        });
    }

    if parts.is_empty() {
        bail!("nothing to send");
    }

    send_parts(session, participant_addresses, parts).await
}

pub async fn send_tapback(_message_guid: &str, _reaction: &str) -> Result<()> {
    bail!("send_tapback: not yet wired — tapback path in api.rs");
}

pub async fn send_edit(_message_guid: &str, _new_text: &str) -> Result<()> {
    bail!("send_edit: not yet wired — edit path in api.rs");
}

pub async fn send_unsend(_message_guid: &str) -> Result<()> {
    bail!("send_unsend: not yet wired — unsend path in api.rs");
}

pub async fn send_typing(_chat_guid: &str, _typing: bool) -> Result<()> {
    bail!("send_typing: not yet wired — typing indicator path in api.rs");
}

pub async fn start_facetime(_address: &str) -> Result<String> {
    bail!("start_facetime: not yet wired — FaceTime path in api.rs");
}

pub async fn poll_findmy_friends() -> Result<Vec<(String, f64, f64)>> {
    bail!("poll_findmy_friends: not yet wired — FindMy path in api.rs");
}

pub async fn list_shared_albums() -> Result<Vec<String>> {
    bail!("list_shared_albums: not yet wired — shared albums path in api.rs");
}
