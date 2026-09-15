#pragma once

#include <QString>

namespace cav {

// Turns a raw message body into the minimal HTML the transcript renders.
//
// Message text arrives from whoever sent it, so nothing is trusted: every
// character is escaped first and the only markup that comes out is <a> for
// http/https URLs and <br> for newlines. There is no path by which text from a
// stranger becomes an element, an attribute, or a non-http scheme.
QString toRichText(const QString& raw);

}  // namespace cav
