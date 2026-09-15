<div align="center">

<img src="assets/cavitation.ico" width="96" alt="Cavitation">

# Cavitation

**An iMessage client for Windows that reads like a terminal, not a phone.**

[![license](https://img.shields.io/badge/license-Apache--2.0-FF0000?style=flat-square)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Windows%2011-FF0000?style=flat-square)](#requirements)
[![built with](https://img.shields.io/badge/Qt6%20%2B%20Rust-FF0000?style=flat-square)](#stack)

</div>

---

Cavitation is a native desktop client for the OpenBubbles ecosystem. The
protocol work is inherited from [OpenBubbles](https://github.com/OpenBubbles/openbubbles-app);
the entire front end is new.

Conversations render as an IRC-style transcript: a timestamp column, a nick
column, and message text that wraps with a hanging indent. Text is selectable,
links are clickable, and images render inline.

## Status

Early. Apple ID sign-in, IDS registration, message send and receive, local
attachments and the transcript all work. Starting a new conversation does not:
resolving an address to an IDS handle is still parked in the protocol core, so
conversations have to begin elsewhere for now.

Windows is the only target.

## Requirements

- Windows 11
- An Apple ID
- A relay pairing code from the OpenBubbles setup flow on a paired Mac

Cavitation is a client. It does not replace the OpenBubbles service, the relay,
or any backend, and it cannot reach iMessage without them.

## Stack

| Layer | What |
| --- | --- |
| Front end | C++17, Qt 6.8 Quick/QML |
| Protocol core | Rust, via the `rustpush` crate |
| Bridge | [`cxx`](https://cxx.rs), surfaced in `rust/src/ffi.rs` |
| Build | CMake with [Corrosion](https://github.com/corrosion-rs/corrosion) |

## Layout

```
cavitation/
├── app/            C++/Qt front end
│   ├── qml/        QML views and the Specter Point theme
│   └── resources/  qrc, version resource, bundled fonts
├── rust/           cxx bridge, storage, session, keystore
├── rustpush/       protocol core (submodule)
└── assets/         icon
```

## Building

Needs Visual Studio 2022, Qt 6.8 (msvc2022_64), a Rust stable toolchain, and
two things the Rust core's build scripts shell out to:

- **Perl** with the full core module set, for vendored OpenSSL.
  `winget install StrawberryPerl.StrawberryPerl`. Git Bash's perl is missing
  `Locale::Maketext::Simple` and fails partway through OpenSSL's `Configure`.
- **protoc**, for `prost-build`. `winget install Google.Protobuf`.

Then:

```
git submodule update --init --recursive
cmake --preset win-vs
cmake --build --preset win-vs-release
```

The presets put both tools on `PATH` for the build. See `CONTRIBUTING.md` for
the longer version.

## Acknowledgments

Cavitation exists because other people did the hard part first, and did it in
the open. The front end here is new. Everything underneath it, which is to say
everything that actually makes iMessage work, was built by others over six
years and 6,500 commits.

**[BlueBubbles](https://github.com/BlueBubblesApp/bluebubbles-app)** is where
this lineage starts. Thanks to Zach Shames, who founded it and wrote more of it
than anyone, and to Tanay Neotia, Joel Jothiprakasam, Brandon, Elliot Nash,
Josh Levin, Sean Regan, Adison Trueblood, Terry Brett, Christopher Lang, Jake
Block, Matthew Stadter, Travis Gibson, Anthony Michelizzi, Cameron Aaron,
Keegan Lillo, Keyvan Fatehi and everyone else who contributed. They built a
genuinely good iMessage client and then gave it away.

**[OpenBubbles](https://github.com/OpenBubbles/openbubbles-app)** and
**[rustpush](https://github.com/OpenBubbles/rustpush)** are Tae Hagen's work.
Reimplementing Apple's IDS registration, APNs transport, identity handling and
now FaceTime, from the outside, without documentation, is the reason a client
like this can talk to iMessage without a Mac in the loop at all. That reverse
engineering is the single most valuable thing in this repository and none of it
is mine.

If you want the mature, cross-platform, actively maintained client, use theirs.
Cavitation is a Windows-only offshoot with opinions about layout. Please
support the projects above rather than this one.

Both upstreams are Apache 2.0 and the same licence applies here. See
[`NOTICE`](./NOTICE) for the formal attribution.

Not endorsed by, affiliated with, or sponsored by either project, or by Apple.

## License

Apache License, Version 2.0. See [`LICENSE`](./LICENSE) and [`NOTICE`](./NOTICE).
