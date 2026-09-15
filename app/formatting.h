#pragma once

#include <QDateTime>
#include <QLocale>
#include <QString>

namespace cav {

// Chat timestamps are relative to now: time for today, weekday inside the last
// week, date beyond that. Anything longer is noise in a list that is mostly
// recent.
inline QString timeLabel(qint64 epochSeconds)
{
    if (epochSeconds <= 0) return {};
    const QDateTime dt = QDateTime::fromSecsSinceEpoch(epochSeconds);
    const QDateTime now = QDateTime::currentDateTime();
    const qint64 days = dt.date().daysTo(now.date());

    if (days == 0) return QLocale().toString(dt.time(), QLocale::ShortFormat);
    if (days == 1) return QStringLiteral("Yesterday");
    if (days < 7) return QLocale().toString(dt.date(), QStringLiteral("ddd"));
    if (dt.date().year() == now.date().year())
        return QLocale().toString(dt.date(), QStringLiteral("d MMM"));
    return QLocale().toString(dt.date(), QStringLiteral("d MMM yyyy"));
}

// Wall-clock time for the transcript's left column. Fixed 24-hour HH:mm so the
// column stays the same width on every row and the nicks stay aligned; a
// locale short format can swap to h:mm AM and ragged the whole column.
inline QString clockLabel(qint64 epochSeconds)
{
    if (epochSeconds <= 0) return {};
    return QDateTime::fromSecsSinceEpoch(epochSeconds).toString(QStringLiteral("HH:mm"));
}

// Full timestamp for a line's tooltip and for the day separator rows.
inline QString fullTimeLabel(qint64 epochSeconds)
{
    if (epochSeconds <= 0) return {};
    return QLocale().toString(QDateTime::fromSecsSinceEpoch(epochSeconds),
                              QLocale::ShortFormat);
}

inline QString sizeLabel(qint64 bytes)
{
    static const char* units[] = {"B", "KB", "MB", "GB"};
    double v = static_cast<double>(bytes);
    int u = 0;
    while (v >= 1024.0 && u < 3) {
        v /= 1024.0;
        ++u;
    }
    return u == 0 ? QStringLiteral("%1 B").arg(bytes)
                  : QStringLiteral("%1 %2").arg(v, 0, 'f', 1).arg(QLatin1String(units[u]));
}

}  // namespace cav
