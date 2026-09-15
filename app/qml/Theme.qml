pragma Singleton

import QtQuick

QtObject {
    // ── Brand colors ──────────────────────────────────────────────
    readonly property color black:      "#000000"
    readonly property color surface:    "#0A0A0A"
    readonly property color elevated:   "#141414"
    readonly property color border:     "#1F1F1F"
    readonly property color borderSoft: "#161616"
    readonly property color red:        "#FF0000"
    readonly property color redDark:    "#CC0000"
    // The ramp is set by contrast against bg1 (#0A0A0A), not by eye. white is
    // already #FFFFFF and cannot go further, so "the white text is hard to
    // read" is really the tiers below it: gray600 measured 4.61, a hair over
    // the 4.5 floor for body text, and gray400 was dim beside a terminal on the
    // same screen. Ratios now run 19.8 / 16.9 / 11.1 / 7.2, which keeps four
    // distinguishable tiers and puts the dimmest one well clear of the floor.
    readonly property color white:      "#FFFFFF"
    readonly property color gray200:    "#EDEDED"
    readonly property color gray400:    "#C2C2C2"
    readonly property color gray600:    "#9C9C9C"
    readonly property color success:    "#00CC66"
    readonly property color warning:    "#FFB800"
    readonly property color info:       "#3399FF"

    // Alpha-layered red for glows & tints
    readonly property color red02: Qt.rgba(1, 0, 0, 0.02)
    readonly property color red05: Qt.rgba(1, 0, 0, 0.05)
    readonly property color red10: Qt.rgba(1, 0, 0, 0.10)
    readonly property color red20: Qt.rgba(1, 0, 0, 0.20)

    // ── Foreground / background roles ────────────────────────────
    readonly property color fg1: white
    readonly property color fg2: gray200
    readonly property color fg3: gray400
    readonly property color fg4: gray600
    readonly property color bg0: black
    readonly property color bg1: surface
    readonly property color bg2: elevated
    readonly property color controlBorder: "#666666"
    readonly property color controlHover: "#383838"
    readonly property color selection: "#D23838"
    readonly property color focusRing: "#FF6666"
    readonly property color error: focusRing
    readonly property color disabled: gray600

    // ── Type ─────────────────────────────────────────────────────
    readonly property string fontHeading: "Chakra Petch"
    readonly property string fontBody:    "Outfit"
    readonly property string fontMono:    "Consolas"

    // ── Spacing scale (Tailwind 4, px) ──────────────────────────
    readonly property int sp1:  4
    readonly property int sp2:  8
    readonly property int sp3:  12
    readonly property int sp4:  16
    readonly property int sp5:  20
    readonly property int sp6:  24
    readonly property int sp8:  32
    readonly property int sp10: 40
    readonly property int sp12: 48
    readonly property int sp16: 64

    // ── Radii ────────────────────────────────────────────────────
    readonly property int radSm:   2
    readonly property int radFull: 9999

    // ── Letter-spacing (em-equivalent ratios; multiply by font px) ──
    readonly property real trackHeading: 0.025
    readonly property real trackWider:   0.05
    readonly property real trackEyebrow: 0.20
    readonly property real trackCaps:    0.30

    // ── Transcript (IRC layout) ──────────────────────────────────
    // Three columns: timestamp, nick, message. Wrapped lines hang under the
    // message column rather than returning to the left edge, which is what
    // makes a dense transcript scannable instead of a wall.
    readonly property int tsColumnWidth:   58
    readonly property int nickColumnWidth: 116
    readonly property int lineGapV:        3
    // Extra gap where the speaker changes, so runs read as blocks.
    readonly property int speakerGapV:     8

    // Nicks are distinguished by brightness, not hue: the design language is
    // monochromatic plus one red, and red is reserved for "me" so that own
    // messages are findable at a glance. Four tiers all clear 7:1 on bg0.
    readonly property var nickTiers: [white, gray200, gray400, gray600]

    // Deterministic so a given person keeps the same tier across sessions.
    function nickColor(name, isFromMe) {
        if (isFromMe)
            return red
        var h = 0
        for (var i = 0; i < name.length; ++i)
            h = (h * 31 + name.charCodeAt(i)) & 0xFFFF
        return nickTiers[h % nickTiers.length]
    }

    readonly property color rowHover:    "#0E0E0E"
    readonly property color linkColor:   "#FF6666"
    readonly property color systemColor: gray600

    // Primary button fill. A saturated red block under white label text sits
    // under the contrast floor, so the fill is a dark red solid and the red
    // itself carries on the border.
    readonly property color primaryBg: "#1C0A0A"

    // ── Transports ───────────────────────────────────────────────
    // Three of them, and they behave differently enough to be worth telling
    // apart at a glance: iMessage has the full feature set, RCS has most of it
    // (typing, receipts, decent media), SMS/MMS has almost none and will
    // mangle anything larger than a postcard.
    //
    // Red is deliberately not used here. It is the app's own accent and
    // already carries selection, unread and the mark; spending it on a
    // transport badge would make every row shout.
    function serviceColor(service) {
        if (service === "RCS") return info
        if (service === "SMS") return success
        return gray600          // iMessage, the default, stays quiet
    }

    function serviceLabel(service) {
        return service === "iMessage" ? "iMSG" : service
    }

    // ── Layout ───────────────────────────────────────────────────
    readonly property int sidebarWidth:   320
    readonly property int titleBarHeight: 36
    readonly property int chatRowHeight:  64
    readonly property int composerMinH:   44
}
