#include "message_list_model.h"

#include <QDateTime>
#include <QVariantMap>

#include "core_bridge.h"
#include "formatting.h"
#include "text_links.h"

namespace cav {

namespace {
// How far back the scrollback reaches. The core returns the most recent N.
constexpr qint64 kMessageLimit = 500;
}  // namespace

MessageListModel::MessageListModel(CoreBridge* bridge, QObject* parent)
    : QAbstractListModel(parent), m_bridge(bridge)
{
    connect(m_bridge, &CoreBridge::messagesChanged, this,
            &MessageListModel::onCoreMessagesChanged);
}

int MessageListModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : static_cast<int>(m_rows.size());
}

QHash<int, QByteArray> MessageListModel::roleNames() const
{
    return {
        {GuidRole, "guid"},
        {SenderDisplayNameRole, "senderDisplayName"},
        {TextRole, "text"},
        {RichTextRole, "richText"},
        {IsFromMeRole, "isFromMe"},
        {ClockLabelRole, "clockLabel"},
        {FullTimeLabelRole, "fullTimeLabel"},
        {IsUnsentRole, "isUnsent"},
        {IsEditedRole, "isEdited"},
        {AttachmentsRole, "attachments"},
        {IsRunStartRole, "isRunStart"},
        {ShowDaySeparatorRole, "showDaySeparator"},
        {DayLabelRole, "dayLabel"},
    };
}

QVariant MessageListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size()) return {};
    const Row& r = m_rows.at(index.row());
    switch (role) {
    case GuidRole:              return r.guid;
    case SenderDisplayNameRole: return r.senderDisplayName;
    case TextRole:              return r.text;
    case RichTextRole:          return r.richText;
    case IsFromMeRole:          return r.isFromMe;
    case ClockLabelRole:        return clockLabel(r.date);
    case FullTimeLabelRole:     return fullTimeLabel(r.date);
    case IsUnsentRole:          return r.isUnsent;
    case IsEditedRole:          return r.isEdited;
    case AttachmentsRole:       return r.attachments;
    case IsRunStartRole:        return r.isRunStart;
    case ShowDaySeparatorRole:  return r.showDaySeparator;
    case DayLabelRole:
        return QDateTime::fromSecsSinceEpoch(r.date).date().toString(
            QStringLiteral("dddd, d MMMM yyyy"));
    default: return {};
    }
}

void MessageListModel::setChatGuid(const QString& guid)
{
    if (m_chatGuid == guid) return;
    m_chatGuid = guid;
    emit chatGuidChanged();
    refresh();
}

void MessageListModel::onCoreMessagesChanged(const QString& chatGuid)
{
    // An empty guid means the core could not attribute the change to one chat,
    // so refresh regardless.
    if (chatGuid.isEmpty() || chatGuid == m_chatGuid) refresh();
}

QVector<MessageListModel::Row> MessageListModel::fetchRows() const
{
    QVector<Row> rows;
    if (m_chatGuid.isEmpty()) return rows;

    auto messages = core::list_messages(m_bridge->state(), Utf8(m_chatGuid), kMessageLimit);
    rows.reserve(static_cast<int>(messages.size()));

    for (const auto& m : messages) {
        Row r;
        r.guid = fromRust(m.guid);
        r.senderDisplayName = fromRust(m.sender_display_name);
        if (r.senderDisplayName.isEmpty()) r.senderDisplayName = fromRust(m.sender_address);
        r.text = fromRust(m.text);
        r.richText = toRichText(r.text);
        r.isFromMe = m.is_from_me;
        r.isUnsent = m.is_unsent;
        r.isEdited = m.date_edited > 0;
        r.date = m.date;

        // Fetched eagerly rather than lazily from the delegate: a bubble whose
        // attachments arrive after creation resizes under the user mid-scroll.
        // Only messages flagged as having any are queried.
        if (m.has_attachments) {
            auto atts = core::list_attachments(m_bridge->state(), Utf8(r.guid));
            for (const auto& a : atts) {
                QVariantMap map;
                map[QStringLiteral("filename")] = fromRust(a.filename);
                map[QStringLiteral("mimeType")] = fromRust(a.mime_type);
                map[QStringLiteral("localPath")] = fromRust(a.local_path);
                map[QStringLiteral("sizeLabel")] = sizeLabel(a.size_bytes);
                const QString mime = fromRust(a.mime_type);
                map[QStringLiteral("isImage")] = mime.startsWith(QLatin1String("image/"));
                r.attachments.append(map);
            }
        }
        rows.push_back(std::move(r));
    }

    annotate(rows);
    return rows;
}

void MessageListModel::annotate(QVector<Row>& rows)
{
    for (int i = 0; i < rows.size(); ++i) {
        Row& r = rows[i];
        if (i == 0) {
            r.isRunStart = true;
            r.showDaySeparator = true;
            continue;
        }
        const Row& prev = rows.at(i - 1);
        r.isRunStart = prev.isFromMe != r.isFromMe ||
                       prev.senderDisplayName != r.senderDisplayName;

        const QDate prevDay = QDateTime::fromSecsSinceEpoch(prev.date).date();
        const QDate thisDay = QDateTime::fromSecsSinceEpoch(r.date).date();
        r.showDaySeparator = prevDay != thisDay;
        if (r.showDaySeparator) r.isRunStart = true;
    }
}

void MessageListModel::refresh()
{
    QVector<Row> next = fetchRows();

    // The common case is one or more messages appended to an otherwise
    // unchanged list. Detect it by guid so the view keeps its scroll position
    // and only the new rows are built.
    const bool isAppend =
        next.size() > m_rows.size() && !m_rows.isEmpty() &&
        [&] {
            for (int i = 0; i < m_rows.size(); ++i) {
                if (m_rows.at(i).guid != next.at(i).guid) return false;
            }
            return true;
        }();

    if (isAppend) {
        const int first = static_cast<int>(m_rows.size());
        const int added = static_cast<int>(next.size()) - first;
        beginInsertRows({}, first, first + added - 1);
        m_rows = std::move(next);
        endInsertRows();
        emit countChanged();
        emit appended(first, added);
        return;
    }

    beginResetModel();
    m_rows = std::move(next);
    endResetModel();
    emit countChanged();
}

}  // namespace cav
