import QtQuick

QtObject {
    readonly property color backdrop: "#cc0b0e14"
    readonly property color cardBg: "#332a2e3a"
    readonly property color cardBorder: "#40ffffff"
    readonly property color selectedBorder: "#7aa2f7"
    readonly property color textColor: "#ffffff"
    readonly property color emptyTextColor: "#80ffffff"
    readonly property real cornerRadius: 10
    readonly property real cardHeight: 180
    readonly property real cardSpacing: 20

    // Carousel layout: fixed step distances between slots on each axis, and
    // per-step falloff for opacity/scale as items recede from the centered
    // (selected) slot.
    readonly property real carouselStepX: cardHeight * 2.6 + cardSpacing
    readonly property real carouselStepY: cardHeight + 70
    readonly property real carouselFadeStep: 0.35
    readonly property real carouselMaxFade: 0.85
    readonly property real carouselScaleStep: 0.08
    readonly property real carouselMaxScaleReduction: 0.3
    readonly property int carouselDuration: 220

    // A two-finger swipe must cross this many pixels (or angleDelta units)
    // before the selection steps once.
    readonly property int swipeThreshold: 120
}
