#include "chat_list_model.h"

#include "core_bridge.h"
#include "formatting.h"

namespace cav {

ChatListModel::ChatListModel(CoreBridge* bridge, QObject* parent)
    : QAbstractListModel(parent), m_bridge(bridge)
{
    connect(m_bridge, &CoreBridge::chatsChanged, this, &ChatListModel::refresh);
    refresh();
}

int ChatListModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QHash<int, QByteArray> ChatListModel::roleNames() const
{
    return {
        {GuidRole, "guid"},
        {TitleRole, "title"},
        {SubtitleRole, "subtitle"},
        {ParticipantSummaryRole, "participantSummary"},
        {ServiceRole, "service"},
        {IsGroupRole, "isGroup"},
        {IsPinnedRole, "isPinned"},
        {IsArchivedRole, "isArchived"},
        {UnreadCountRole, "unreadCount"},
        {TimeLabelRole, "timeLabel"},
    };
}

QVariant ChatListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};
    const Row& r = m_rows.at(index.row());
    switch (role) {
    case GuidRole:               return r.guid;
    case TitleRole:              return r.title;
    case SubtitleRole:           return r.subtitle;
    case ParticipantSummaryRole: return r.participantSummary;
    case ServiceRole:           return r.service;
    case IsGroupRole:            return r.isGroup;
    case IsPinnedRole:           return r.isPinned;
    case IsArchivedRole:         return r.isArchived;
    case UnreadCountRole:        return r.unreadCount;
    case TimeLabelRole:          return timeLabel(r.lastMessageDate);
    default:                     return {};
    }
}

void ChatListModel::setIncludeArchived(bool v)
{
    if (m_includeArchived == v) return;
    m_includeArchived = v;
    emit includeArchivedChanged();
    refresh();
}

void ChatListModel::setFilter(const QString& f)
{
    if (m_filter == f) return;
    m_filter = f;
    emit filterChanged();
    refresh();
}

bool ChatListModel::matchesFilter(const Row& row) const
{
    if (m_filter.isEmpty()) return true;
    const auto cs = Qt::CaseInsensitive;
    return row.title.contains(m_filter, cs) || row.subtitle.contains(m_filter, cs) ||
           row.participantSummary.contains(m_filter, cs);
}

void ChatListModel::refresh()
{
    // A chat list is tens of rows and every field can change at once (preview,
    // unread, pin order), so a reset is both correct and cheap here. The
    // message list is the one that needs incremental updates.
    beginResetModel();
    m_rows.clear();

    auto chats = core::list_chats(m_bridge->state(), m_includeArchived);
    m_rows.reserve(static_cast<int>(chats.size()));
    for (const auto& c : chats) {
        Row r;
        r.guid = fromRust(c.guid);
        r.title = fromRust(c.title);
        r.subtitle = fromRust(c.subtitle);
        r.participantSummary = fromRust(c.participant_summary);
        r.service = fromRust(c.service);
        r.isGroup = c.is_group;
        r.isPinned = c.is_pinned;
        r.isArchived = c.is_archived;
        r.unreadCount = c.unread_count;
        r.lastMessageDate = c.last_message_date;
        if (matchesFilter(r)) m_rows.push_back(std::move(r));
    }

    endResetModel();
    emit countChanged();
}

int ChatListModel::indexOfGuid(const QString& guid) const
{
    for (int i = 0; i < m_rows.size(); ++i) {
        if (m_rows.at(i).guid == guid) return i;
    }
    return -1;
}

QVariantMap ChatListModel::chatByGuid(const QString& guid) const
{
    const int i = indexOfGuid(guid);
    if (i < 0) return {};
    const Row& r = m_rows.at(i);
    return {
        {QStringLiteral("guid"), r.guid},
        {QStringLiteral("title"), r.title},
        {QStringLiteral("subtitle"), r.subtitle},
        {QStringLiteral("participantSummary"), r.participantSummary},
        {QStringLiteral("isGroup"), r.isGroup},
        {QStringLiteral("service"), r.service},
    };
}

}  // namespace cav
