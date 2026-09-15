# Contributing to Cavitation

Cavitation is a C++/Qt6 rewrite of the OpenBubbles Windows client. The protocol core stays in Rust (`rust/` + `rustpush/`); the frontend is native C++ with a QML view layer.

## Toolchain

You need:

- [Git](https://git-scm.com/downloads)
- [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/) with the **Desktop development with C++** workload (includes MSVC, the Windows SDK, and the Windows 10/11 platform toolset)
- [CMake](https://cmake.org/download/) 3.24 or newer (3.24 is the minimum for the Corrosion integration used in `CMakeLists.txt`)
- [Qt 6.8](https://www.qt.io/download-qt-installer) for **msvc2022_64**, with the Qt Quick / QML modules. The presets expect it at `C:/Qt/6.8.3/msvc2022_64`; override `CMAKE_PREFIX_PATH` if yours lives elsewhere.
- [Rust](https://rustup.rs/) (stable, default MSVC toolchain on Windows)
- [Protocol Buffers compiler (`protoc`)](https://github.com/protocolbuffers/protobuf/releases) on `PATH`, needed by `prost-build` when the Rust core compiles. `winget install Google.Protobuf`.
- **Strawberry Perl** on `PATH`, needed by `openssl-sys` (the Rust core vendors OpenSSL and shells out to Perl's `Configure`). `winget install StrawberryPerl.StrawberryPerl`.

  Git Bash ships a Perl that looks like it will work and does not: it lacks `Locale::Maketext::Simple`, so OpenSSL's `Configure` dies partway through with a `@INC` error that reads like a broken checkout rather than a missing module. If a build fails inside `openssl-sys`, check which Perl is first on `PATH` before anything else.

Optional but recommended:

- [Ninja](https://ninja-build.org/): CMake picks it up automatically when present and builds faster than the default MSBuild generator
- [vcpkg](https://github.com/microsoft/vcpkg) if you prefer to manage third-party C++ dependencies outside of CMake `FetchContent`

## Submodules

After cloning, initialize the `rustpush` submodule (which itself has nested submodules):

```
git submodule update --init --recursive
```

If any of the nested submodules are declared with SSH URLs and you don't have SSH keys configured for GitHub, run once:

```
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_0=git@github.com: git submodule update --init --recursive
```

## Building

There is a `CMakePresets.json` at the repo root that points CMake at the rustup-managed toolchain directly (required because Corrosion's rustup proxy detection misbehaves in MSYS / Git Bash environments on Windows).

Visual Studio 2022 generator:

```
cmake --preset win-vs
cmake --build --preset win-vs-release
```

Ninja (run from a VS 2022 Developer Command Prompt so `cl.exe`, `link.exe`, and the Windows SDK are on `PATH`):

```
cmake --preset win-ninja
cmake --build --preset win-ninja
```

Cargo is invoked by Corrosion during the CMake build; you do not need to run `cargo build` yourself. To iterate on the Rust side in isolation:

```
cargo check --manifest-path rust/Cargo.toml
```

First build is slow. The Rust core vendors OpenSSL and pulls the full `rustpush` tree.

## Style

- **C++:** C++17. Default to standard library containers and algorithms. Prefer `std::unique_ptr` / `std::shared_ptr` over hand-rolled ownership, and Qt parent-child ownership for `QObject`s. C++ owns state and models; QML owns layout. Anything reaching the core goes through `CoreBridge`.
- **QML:** all colour, spacing, type and radius values come from `Theme.qml`. No literal hex, no magic pixel numbers in a view. New primitives are `Cav`-prefixed and live beside the others in `app/qml/`. Message bodies are remote input: render them through the escaped HTML from `text_links.cpp`, never by handing raw text to a rich-text renderer.
- **Rust:** idiomatic, `rustfmt` on save, `clippy::pedantic` as a warning guide (not a hard gate). FFI signatures live in `rust/src/ffi.rs` under the `cxx::bridge` module.
- **No AI trailers, artifacts, or attribution** in source, comments, commit messages, docs, or license files.

## Branches and commits

1. Create a topic branch: `git checkout -b <short-topic>`.
2. Keep commits focused. Commit messages describe the *why*.
3. Rust changes that touch the FFI boundary should come with a matching C++ caller update in the same commit so the tree always builds.

## Pull requests

Open PRs against the default branch. Include:

- What problem is being solved.
- Summary of the change.
- Manual test notes for the Windows build.

## Upstream

Cavitation is an independent fork. Do not send Cavitation changes upstream to OpenBubbles or BlueBubbles, and do not file Cavitation bugs on their issue trackers. They did not write this frontend and should not field questions about it.
