import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Starwatch clicks: a little firefly burst wherever you click.
//   left   fireflies scatter out of a soft ring
//   right  lavender sparkles (✦) twinkle outwards
//   middle glacier-blue ripple
// clickwatch.py reports button presses; the overlay window only exists while
// a burst is playing and is click-through, and nothing plays over fullscreen
// windows (games, video). Toggle: `omarchy-shell -q clicks toggle`.
Item {
  id: root

  readonly property color firefly: "#e3dc5c"
  readonly property color fireflyCore: "#fffbd0"
  readonly property color nebula: "#9d8fe6"
  readonly property color glacier: "#57add0"

  property bool enabled: true
  property int maxBursts: 12
  readonly property string helper: String(Qt.resolvedUrl("clickwatch.py")).replace(/^file:\/\//, "")

  ListModel { id: bursts }
  property int nextId: 0

  function spawn(button, gx, gy) {
    if (!enabled || bursts.count >= maxBursts) return
    bursts.append({ bid: nextId++, button: button, gx: gx, gy: gy, born: Date.now() })
  }

  function finish(bid) {
    for (var i = 0; i < bursts.count; i++) {
      if (bursts.get(i).bid === bid) { bursts.remove(i); return }
    }
  }

  Process {
    id: watcher
    running: root.enabled
    command: ["setpriv", "--pdeathsig", "TERM", "/usr/bin/python3", root.helper]
    // Exit code 3 = python-evdev missing; retrying would not help.
    onExited: function(code) { if (root.enabled && code !== 3) restartTimer.restart() }
    stdout: SplitParser {
      onRead: function(line) {
        var p = String(line).trim().split(" ")
        if (p.length === 3) root.spawn(p[0], Number(p[1]), Number(p[2]))
      }
    }
  }

  // A crashed or unplugged watcher comes back on its own.
  Timer {
    id: restartTimer
    interval: 3000
    onTriggered: if (root.enabled && !watcher.running) watcher.running = true
  }

  IpcHandler {
    target: "clicks"
    function toggle(): void { root.enabled = !root.enabled }
    function setEnabled(on: bool): void { root.enabled = on }
    function test(): void {
      var s = Quickshell.screens[0]
      root.spawn("L", s.x + s.width / 2, s.y + s.height / 2)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property bool covered: !!(hyprMonitor && hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen)

      function mine(gx, gy) {
        return gx >= modelData.x && gx < modelData.x + modelData.width
          && gy >= modelData.y && gy < modelData.y + modelData.height
      }

      screen: modelData
      visible: bursts.count > 0
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "starwatch-clicks"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      mask: Region {}

      Repeater {
        model: bursts

        delegate: Loader {
          id: slot
          required property int bid
          required property string button
          required property real gx
          required property real gy

          active: panel.mine(gx, gy) && !panel.covered
          x: gx - panel.modelData.x
          y: gy - panel.modelData.y
          onActiveChanged: if (!active) root.finish(bid)
          Component.onCompleted: if (!active) Qt.callLater(root.finish, bid)

          sourceComponent: slot.button === "R" ? sparkleBurst : (slot.button === "M" ? rippleBurst : fireflyBurst)

          Component {
            id: fireflyBurst
            Burst {
              ringColor: root.firefly
              onDone: root.finish(slot.bid)
              Repeater {
                model: 7
                Firefly {
                  required property int index
                  angle: (index / 7) * Math.PI * 2 + Math.random() * 0.7
                  distance: 22 + Math.random() * 26
                  lift: 10 + Math.random() * 14
                  size: 5 + Math.random() * 3.5
                  duration: 650 + Math.random() * 350
                  color: root.firefly
                  core: root.fireflyCore
                }
              }
            }
          }

          Component {
            id: sparkleBurst
            Burst {
              ringColor: root.nebula
              onDone: root.finish(slot.bid)
              Repeater {
                model: 5
                Sparkle {
                  required property int index
                  angle: (index / 5) * Math.PI * 2 - Math.PI / 2 + Math.random() * 0.5
                  distance: 18 + Math.random() * 18
                  size: 11 + Math.random() * 7
                  duration: 700 + Math.random() * 300
                  color: index % 2 ? root.nebula : root.fireflyCore
                }
              }
            }
          }

          Component {
            id: rippleBurst
            Burst {
              ringColor: root.glacier
              rings: 3
              onDone: root.finish(slot.bid)
            }
          }
        }
      }
    }
  }

  // --- building blocks -----------------------------------------------------

  component Burst: Item {
    id: burst
    property color ringColor: "white"
    property int rings: 1
    signal done()
    default property alias content: holder.data

    Repeater {
      model: burst.rings
      Rectangle {
        required property int index
        property real r: 0
        x: -r; y: -r
        width: r * 2; height: r * 2
        radius: r
        color: "transparent"
        border.width: 1.6
        border.color: burst.ringColor
        opacity: 0
        SequentialAnimation on r {
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: 3; to: 26 + index * 6; duration: 520; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on opacity {
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: 0.85; to: 0; duration: 520; easing.type: Easing.InQuad }
        }
      }
    }

    Item { id: holder }

    Timer { interval: 1100; running: true; onTriggered: burst.done() }
  }

  component Firefly: Item {
    id: fly
    property real angle: 0
    property real distance: 30
    property real lift: 12
    property real size: 5
    property int duration: 800
    property color color: "yellow"
    property color core: "white"
    property real p: 0

    x: Math.cos(angle) * distance * p
    y: Math.sin(angle) * distance * p - lift * p * p
    opacity: p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75

    Rectangle {
      width: fly.size * 3.2; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: fly.color
      opacity: 0.3
    }
    Rectangle {
      width: fly.size * 1.8; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: fly.color
      opacity: 0.65
    }
    Rectangle {
      width: fly.size * 0.8; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: fly.core
    }

    NumberAnimation on p { from: 0; to: 1; duration: fly.duration; easing.type: Easing.OutQuad }
  }

  component Sparkle: Text {
    id: spark
    property real angle: 0
    property real distance: 24
    property real size: 12
    property int duration: 800
    property real p: 0

    text: "✦"
    font.pixelSize: size
    x: Math.cos(angle) * distance * p - width / 2
    y: Math.sin(angle) * distance * p - height / 2
    rotation: p * 90
    scale: p < 0.3 ? 0.4 + p * 2 : 1 - (p - 0.3) * 0.8
    opacity: 1 - p * p

    NumberAnimation on p { from: 0; to: 1; duration: spark.duration; easing.type: Easing.OutCubic }
  }
}
