#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <functional>
#include <memory>

#include "core_api.h"

class QTimer;

namespace cav {

// Owns the Rust AppState and is the only object that talks to the core.
//
// The core pushes work onto its own threads and reports back through an
// unbounded channel that poll_events() drains. ImGui drained it once per
// frame; under Qt nothing redraws on a clock, so a timer drains it instead and
// turns each event into a signal. Everything QML reacts to comes from here.
class CoreBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString authLabel READ authLabel NOTIFY authLabelChanged)
    Q_PROPERTY(QString statusLine READ statusLine NOTIFY statusLineChanged)
    Q_PROPERTY(QString relayHost READ relayHost NOTIFY relayHostChanged)
    Q_PROPERTY(bool hasOsConfig READ hasOsConfig NOTIFY authLabelChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY authLabelChanged)
    Q_PROPERTY(QString osConfigSummary READ osConfigSummary NOTIFY authLabelChanged)
    Q_PROPERTY(QString coreVersion READ coreVersion CONSTANT)
    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)

public:
    // Throws std::exception if the core will not open; main() reports that and
    // exits rather than running a window with no state behind it.
    explicit CoreBridge(const QString& dataDir, QObject* parent = nullptr);
    ~CoreBridge() override;

    core::AppState& state() { return *m_state; }

    QString authLabel() const { return m_authLabel; }
    QString statusLine() const { return m_statusLine; }
    QString relayHost() const;
    bool hasOsConfig() const;
    bool ready() const { return m_authLabel == QStringLiteral("ready"); }
    QString osConfigSummary() const;
    QString coreVersion() const;
    QString dataDir() const;

    // ── Messaging ────────────────────────────────────────────────
    Q_INVOKABLE void sendMessage(const QString& chatGuid, const QString& text);
    Q_INVOKABLE void attachFile(const QString& chatGuid, const QString& text,
                                const QString& sourcePath);
    Q_INVOKABLE void markChatRead(const QString& chatGuid);
    Q_INVOKABLE void pinChat(const QString& chatGuid, bool pinned, int order = 0);
    Q_INVOKABLE void archiveChat(const QString& chatGuid, bool archived);
    Q_INVOKABLE void tapback(const QString& messageGuid, const QString& reaction);
    Q_INVOKABLE void editMessage(const QString& messageGuid, const QString& newText);
    Q_INVOKABLE void unsendMessage(const QString& messageGuid);

    // ── Account & device ─────────────────────────────────────────
    Q_INVOKABLE void setRelayHost(const QString& host);
    Q_INVOKABLE void completePairing(const QString& code, const QString& beeperToken);
    Q_INVOKABLE void clearPairing();
    Q_INVOKABLE void startAppleIdAuth(const QString& appleId, const QString& password);
    Q_INVOKABLE void submitTwoFactorCode(const QString& code);
    Q_INVOKABLE QString startFaceTimeCall(const QString& address);

    // ── Misc ─────────────────────────────────────────────────────
    // Cached handles as {address, service, displayName} maps, for Settings.
    Q_INVOKABLE QVariantList handles() const;
    Q_INVOKABLE void openAttachment(const QString& localPath);
    Q_INVOKABLE QString pickFile();

signals:
    void authLabelChanged();
    void statusLineChanged();
    void relayHostChanged();

    // A user-visible transient. QML stacks these as toasts.
    void toastPosted(const QString& text);

    // The chat list changed shape (new chat, pin, archive, unread count).
    void chatsChanged();

    // Messages within one chat changed. Empty guid means "could be any chat".
    void messagesChanged(const QString& chatGuid);

private:
    void pollEvents();
    void setStatusLine(const QString& line);
    // Runs fn, converting a Rust error into a toast rather than an unwind
    // through the QML engine. Returns false if it threw.
    bool guarded(const char* what, const std::function<void()>& fn);

    rust::Box<core::AppState> m_state;
    QTimer* m_pollTimer = nullptr;
    QString m_authLabel;
    QString m_statusLine;
};

}  // namespace cav
