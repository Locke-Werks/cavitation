#pragma once

// The one place the generated cxx bridge header and its namespace are named.
// The Rust crate still ships as whatbubbles_core from the ImGui era; when it is
// renamed, this file is the only C++ that has to follow.
#include "whatbubbles_cxx/ffi.h"

#include <QByteArray>
#include <QString>

namespace core = whatbubbles;

namespace cav {

inline QString fromRust(const rust::String& s)
{
    return QString::fromUtf8(s.data(), static_cast<qsizetype>(s.size()));
}

// rust::Str borrows, so the QByteArray backing it has to outlive the call.
// Every call site keeps one of these on the stack for the duration.
class Utf8 {
public:
    explicit Utf8(const QString& s) : m_bytes(s.toUtf8()) {}

    operator rust::Str() const  // NOLINT(google-explicit-constructor)
    {
        return rust::Str(m_bytes.constData(), static_cast<std::size_t>(m_bytes.size()));
    }

private:
    QByteArray m_bytes;
};

}  // namespace cav
