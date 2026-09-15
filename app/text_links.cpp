#include "text_links.h"

#include <QRegularExpression>

namespace cav {
namespace {

// Only http and https are matched. Everything else stays inert text, which
// covers javascript:, data:, file: and vbscript: without enumerating them.
const QRegularExpression& urlPattern()
{
    static const QRegularExpression pattern(
        QStringLiteral(R"((https?://[^\s<>"'`]+))"),
        QRegularExpression::CaseInsensitiveOption);
    return pattern;
}

// Trailing punctuation usually belongs to the sentence, not the URL.
// "see https://example.com/x." should not link a URL nobody published.
// Closing brackets are trimmed only when unbalanced, since real URLs contain
// matched pairs often enough to matter.
QString trimTrailing(QString url)
{
    while (!url.isEmpty()) {
        const QChar last = url.back();

        if (last == u')' || last == u']') {
            const QChar opener = last == u')' ? u'(' : u'[';
            if (url.count(opener) < url.count(last)) {
                url.chop(1);
                continue;
            }
            break;
        }

        if (QStringLiteral(".,;:!?\"'").contains(last)) {
            url.chop(1);
            continue;
        }
        break;
    }
    return url;
}

QString escape(QStringView text)
{
    QString out;
    out.reserve(text.size() + text.size() / 8);
    for (const QChar c : text) {
        switch (c.unicode()) {
        case u'&':  out += QLatin1String("&amp;");  break;
        case u'<':  out += QLatin1String("&lt;");   break;
        case u'>':  out += QLatin1String("&gt;");   break;
        case u'"':  out += QLatin1String("&quot;"); break;
        case u'\'': out += QLatin1String("&#39;");  break;
        case u'\n': out += QLatin1String("<br>");   break;
        default:    out += c;                       break;
        }
    }
    return out;
}

}  // namespace

QString toRichText(const QString& raw)
{
    QString out;
    out.reserve(raw.size() + raw.size() / 4);

    qsizetype cursor = 0;
    auto it = urlPattern().globalMatch(raw);

    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        const QString url = trimTrailing(m.captured(1));
        if (url.isEmpty()) continue;

        // Escape the text before the URL, then the URL itself for both the
        // attribute and the visible label. The match is taken against the raw
        // string so escaping never shifts the boundaries.
        out += escape(QStringView(raw).mid(cursor, m.capturedStart(1) - cursor));

        const QString safeUrl = escape(url);
        out += QStringLiteral("<a href=\"%1\">%1</a>").arg(safeUrl);

        cursor = m.capturedStart(1) + url.size();
    }

    out += escape(QStringView(raw).mid(cursor));
    return out;
}

}  // namespace cav
