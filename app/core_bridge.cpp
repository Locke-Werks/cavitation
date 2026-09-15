#include "core_bridge.h"

#include <QDesktopServices>
#include <QFileDialog>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>

namespace cav {

namespace {
// The core reports through a channel, not a callback, so the UI has to ask.
// 120ms is under the ~150ms that reads as instant for an arriving message and
// costs nothing measurable when the channel is empty, which is almost always.
constexpr int kPollIntervalMs = 120;
}  // namespace

CoreBridge::CoreBridge(const QString& dataDir, QObject* parent)
    : QObject(parent), m_state(core::init_app(Utf8(dataDir)))
{
    m_authLabel = fromRust(core::auth_state(*m_state));

    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(kPollIntervalMs);
    connect(m_pollTimer, &QTimer::timeout, this, &CoreBridge::pollEvents);
    m_pollTimer->start();
}

CoreBridge::~CoreBridge() = default;

QString CoreBridge::relayHost() const { return fromRust(core::relay_host(*m_state)); }
QString CoreBridge::coreVersion() const { return fromRust(core::core_version()); }
QString CoreBridge::dataDir() const { return fromRust(core::data_dir(*m_state)); }
bool CoreBridge::hasOsConfig() const { return core::has_os_config(*m_state); }

QString CoreBridge::osConfigSummary() const
{
    return fromRust(core::os_config_summary(*m_state));
}

void CoreBridge::setStatusLine(const QString& line)
{
    if (m_statusLine == line) return;
    m_statusLine = line;
    emit statusLineChanged();
}

bool CoreBridge::guarded(const char* what, const std::function<void()>& fn)
{
    try {
        fn();
        return true;
    } catch (const std::exception& e) {
        emit toastPosted(QStringLiteral("%1: %2")
                             .arg(QString::fromLatin1(what), QString::fromUtf8(e.what())));
        return false;
    }
}

void CoreBridge::pollEvents()
{
    auto events = core::poll_events(*m_state);
    if (events.empty()) return;

    // Coalesce: a burst of arrivals in one tick should repaint the list once,
    // not once per message.
    bool chatsDirty = false;
    QString messagesDirtyFor;
    bool messagesDirtyAny = false;

    auto markMessages = [&](const QString& guid) {
        if (messagesDirtyAny && messagesDirtyFor != guid) {
            messagesDirtyFor.clear();  // more than one chat moved
        } else if (!messagesDirtyAny) {
            messagesDirtyFor = guid;
        }
        messagesDirtyAny = true;
    };

    for (const auto& ev : events) {
        const QString kind = fromRust(ev.kind);
        const QString text = fromRust(ev.text);
        const QString chatGuid = fromRust(ev.chat_guid);

        if (kind == QLatin1String("auth_state")) {
            if (m_authLabel != text) {
                m_authLabel = text;
                emit authLabelChanged();
            }
            setStatusLine(QStringLiteral("auth: %1").arg(text));
        } else if (kind == QLatin1String("error")) {
            emit toastPosted(QStringLiteral("error: %1").arg(text));
        } else if (kind == QLatin1String("warn")) {
            emit toastPosted(QStringLiteral("warn: %1").arg(text));
        } else if (kind == QLatin1String("info")) {
            setStatusLine(text);
        } else if (kind == QLatin1String("message_failed")) {
            emit toastPosted(QStringLiteral("send failed: %1").arg(text));
            chatsDirty = true;
            markMessages(chatGuid);
        } else if (kind == QLatin1String("message_arrived") ||
                   kind == QLatin1String("message_sent")) {
            chatsDirty = true;
            markMessages(chatGuid);
        } else if (kind == QLatin1String("chat_created") ||
                   kind == QLatin1String("chat_updated")) {
            chatsDirty = true;
        }
        // "typing" is carried but not surfaced yet; the indicator needs a
        // per-chat timeout the core does not emit.
    }

    if (chatsDirty) emit chatsChanged();
    if (messagesDirtyAny) emit messagesChanged(messagesDirtyFor);
}

// ── Messaging ────────────────────────────────────────────────────

void CoreBridge::sendMessage(const QString& chatGuid, const QString& text)
{
    if (chatGuid.isEmpty() || text.isEmpty()) return;
    guarded("send", [&] {
        core::send_message_local(*m_state, Utf8(chatGuid), Utf8(text));
    });
    emit messagesChanged(chatGuid);
    emit chatsChanged();
}

void CoreBridge::attachFile(const QString& chatGuid, const QString& text,
                            const QString& sourcePath)
{
    if (chatGuid.isEmpty() || sourcePath.isEmpty()) return;
    guarded("attach", [&] {
        core::attach_file_local(*m_state, Utf8(chatGuid), Utf8(text), Utf8(sourcePath));
    });
    emit messagesChanged(chatGuid);
    emit chatsChanged();
}

void CoreBridge::markChatRead(const QString& chatGuid)
{
    if (chatGuid.isEmpty()) return;
    guarded("mark read", [&] { core::mark_chat_read(*m_state, Utf8(chatGuid)); });
    emit chatsChanged();
}

void CoreBridge::pinChat(const QString& chatGuid, bool pinned, int order)
{
    guarded("pin", [&] { core::pin_chat(*m_state, Utf8(chatGuid), pinned, order); });
    emit chatsChanged();
}

void CoreBridge::archiveChat(const QString& chatGuid, bool archived)
{
    guarded("archive", [&] { core::archive_chat(*m_state, Utf8(chatGuid), archived); });
    emit chatsChanged();
}

void CoreBridge::tapback(const QString& messageGuid, const QString& reaction)
{
    guarded("react", [&] { core::tapback_local(*m_state, Utf8(messageGuid), Utf8(reaction)); });
    emit messagesChanged(QString());
}

void CoreBridge::editMessage(const QString& messageGuid, const QString& newText)
{
    guarded("edit", [&] {
        core::edit_message_local(*m_state, Utf8(messageGuid), Utf8(newText));
    });
    emit messagesChanged(QString());
}

void CoreBridge::unsendMessage(const QString& messageGuid)
{
    guarded("unsend", [&] { core::unsend_message_local(*m_state, Utf8(messageGuid)); });
    emit messagesChanged(QString());
}

// ── Account & device ─────────────────────────────────────────────

void CoreBridge::setRelayHost(const QString& host)
{
    if (guarded("relay host", [&] { core::set_relay_host(*m_state, Utf8(host)); })) {
        emit relayHostChanged();
        emit toastPosted(QStringLiteral("relay host saved"));
    }
}

void CoreBridge::completePairing(const QString& code, const QString& beeperToken)
{
    if (guarded("pair", [&] {
            core::complete_pairing(*m_state, Utf8(code), Utf8(beeperToken));
        })) {
        emit toastPosted(QStringLiteral("pairing saved"));
    }
    m_authLabel = fromRust(core::auth_state(*m_state));
    emit authLabelChanged();
}

void CoreBridge::clearPairing()
{
    guarded("clear pairing", [&] { core::clear_pairing(*m_state); });
    m_authLabel = fromRust(core::auth_state(*m_state));
    emit authLabelChanged();
}

void CoreBridge::startAppleIdAuth(const QString& appleId, const QString& password)
{
    guarded("auth", [&] {
        core::start_apple_id_auth(*m_state, Utf8(appleId), Utf8(password));
    });
}

void CoreBridge::submitTwoFactorCode(const QString& code)
{
    guarded("2fa", [&] { core::submit_two_factor_code(*m_state, Utf8(code)); });
}

QString CoreBridge::startFaceTimeCall(const QString& address)
{
    QString link;
    guarded("facetime", [&] {
        link = fromRust(core::start_facetime_call(*m_state, Utf8(address)));
    });
    return link;
}

// ── Misc ─────────────────────────────────────────────────────────

QVariantList CoreBridge::handles() const
{
    QVariantList out;
    for (const auto& h : core::list_handles(*m_state)) {
        QVariantMap map;
        map[QStringLiteral("address")] = fromRust(h.address);
        map[QStringLiteral("service")] = fromRust(h.service);
        map[QStringLiteral("displayName")] = fromRust(h.display_name);
        out.append(map);
    }
    return out;
}

void CoreBridge::openAttachment(const QString& localPath)
{
    if (localPath.isEmpty()) return;
    QDesktopServices::openUrl(QUrl::fromLocalFile(localPath));
}

QString CoreBridge::pickFile()
{
    return QFileDialog::getOpenFileName(nullptr, QStringLiteral("Attach a file"));
}

}  // namespace cav
