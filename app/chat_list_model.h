#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVariantMap>
#include <QVector>

namespace cav {

class CoreBridge;

// The conversation sidebar. Rows come straight from the core's list_chats,
// already ordered; the only thing this adds is the search filter, which is a
// plain substring match over title, preview and participants.
class ChatListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool includeArchived READ includeArchived WRITE setIncludeArchived
                   NOTIFY includeArchivedChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        GuidRole = Qt::UserRole + 1,
        TitleRole,
        SubtitleRole,
        ParticipantSummaryRole,
        ServiceRole,
        IsGroupRole,
        IsPinnedRole,
        IsArchivedRole,
        UnreadCountRole,
        TimeLabelRole,
    };

    explicit ChatListModel(CoreBridge* bridge, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool includeArchived() const { return m_includeArchived; }
    void setIncludeArchived(bool v);
    QString filter() const { return m_filter; }
    void setFilter(const QString& f);

    Q_INVOKABLE void refresh();
    // Index of a guid after a refresh, so QML can keep the selection put.
    Q_INVOKABLE int indexOfGuid(const QString& guid) const;
    // Row as a map, so the conversation header reads the same row the sidebar
    // selected instead of QML poking at raw role numbers.
    Q_INVOKABLE QVariantMap chatByGuid(const QString& guid) const;

signals:
    void includeArchivedChanged();
    void filterChanged();
    void countChanged();

private:
    struct Row {
        QString guid;
        QString title;
        QString subtitle;
        QString participantSummary;
        QString service;
        bool isGroup = false;
        bool isPinned = false;
        bool isArchived = false;
        int unreadCount = 0;
        qint64 lastMessageDate = 0;
    };

    bool matchesFilter(const Row& row) const;

    CoreBridge* m_bridge = nullptr;
    QVector<Row> m_rows;
    bool m_includeArchived = false;
    QString m_filter;
};

}  // namespace cav
