#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVariantList>
#include <QVector>

namespace cav {

class CoreBridge;

// The message scrollback for one chat, oldest first.
//
// Unlike the chat list this does not reset on every change. A reset while the
// user is scrolled up reading history throws them back to the bottom, and an
// arriving message is by far the most common change, so the usual case is
// detected and appended instead.
class MessageListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString chatGuid READ chatGuid WRITE setChatGuid NOTIFY chatGuidChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        GuidRole = Qt::UserRole + 1,
        SenderDisplayNameRole,
        TextRole,
        // Escaped, with http/https URLs linkified. See text_links.h.
        RichTextRole,
        IsFromMeRole,
        ClockLabelRole,
        FullTimeLabelRole,
        IsUnsentRole,
        IsEditedRole,
        AttachmentsRole,
        // True when this message starts a run from a new sender, which is
        // where the name label and the extra gap go.
        IsRunStartRole,
        // True when a day boundary falls before this message.
        ShowDaySeparatorRole,
        DayLabelRole,
    };

    explicit MessageListModel(CoreBridge* bridge, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString chatGuid() const { return m_chatGuid; }
    void setChatGuid(const QString& guid);

    Q_INVOKABLE void refresh();

signals:
    void chatGuidChanged();
    void countChanged();
    // Emitted only when rows were appended to the end, so the view can decide
    // whether to follow the tail instead of being yanked to it.
    void appended(int firstRow, int count);

private:
    struct Row {
        QString guid;
        QString senderDisplayName;
        QString text;
        QString richText;
        bool isFromMe = false;
        bool isUnsent = false;
        bool isEdited = false;
        qint64 date = 0;
        QVariantList attachments;
        bool isRunStart = true;
        bool showDaySeparator = false;
    };

    QVector<Row> fetchRows() const;
    // Fills isRunStart / showDaySeparator, which depend on the previous row.
    static void annotate(QVector<Row>& rows);

    void onCoreMessagesChanged(const QString& chatGuid);

    CoreBridge* m_bridge = nullptr;
    QVector<Row> m_rows;
    QString m_chatGuid;
};

}  // namespace cav
