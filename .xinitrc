#!/bin/sh
# =============================================================================
#  .xinitrc — Arch Linux + Suckless setup
#  Created by install_suckless.sh
#
#  This file is created ONCE and never modified by install scripts.
#  Autostart programs are managed via hooks in ~/.config/xinitrc.d/
# =============================================================================

# ───────── 1) Session Setup ─────────

# Always start in $HOME
cd "$HOME"

# Start D-Bus session if not already running
# This ensures GUI apps can communicate (notifications, file dialogs, etc.)
if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
  exec dbus-run-session "$0" "$@"
fi

# Export X environment to systemd user services
# Allows user services (like dunst.service) to access DISPLAY and XAUTHORITY
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
fi

# Load X resources (fonts, colors, DPI settings)
[ -r "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Set keyboard layout (change 'se' to your layout: us, gb, de, etc.)
command -v setxkbmap >/dev/null 2>&1 && setxkbmap se

# Set root window background color (prevents ugly gray)
command -v xsetroot >/dev/null 2>&1 && xsetroot -solid "#111111"

# Optional: enable NumLock at startup
# command -v numlockx >/dev/null 2>&1 && numlockx on

# Optional: HiDPI scaling (uncomment and adjust for your display)
# command -v xrandr >/dev/null 2>&1 && xrandr --output eDP-1 --scale 0.75x0.75

# ───────── 2) GTK & Qt Theming ─────────

export XDG_CONFIG_HOME="$HOME/.config"
export GTK_THEME="Adwaita:dark"
export QT_STYLE_OVERRIDE="kvantum"
export QT_QPA_PLATFORMTHEME="qt5ct"
export XCURSOR_THEME="Adwaita"
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# ───────── 3) Autostart Programs (via hooks) ─────────

# Source all executable hooks from ~/.config/xinitrc.d/
# Other install scripts (lookandfeel, statusbar) create hooks here
# Hooks are executed in alphabetical order (10-*, 20-*, 30-*, etc.)
if [ -d "$HOME/.config/xinitrc.d" ]; then
  for hook in "$HOME/.config/xinitrc.d"/*.sh; do
    [ -x "$hook" ] && . "$hook"
  done
fi

# ───────── 3.1) Workstation display layout ─────────

#   - Bottom monitor = DP-5 (primary)
#   - Top monitor    = DP-6 (physically upside-down) → rotate 180° (inverted)
#   - If both present: DP-6 above DP-5
#   - If only one present: use that one as primary (rotate DP-6 if it's the only one)
#   - Be resilient at session start: wait for X/xrandr and for EDID to settle

if command -v xrandr >/dev/null 2>&1; then
  sleep 0.3
  BOTTOM="DP-5"
  TOP="DP-6"

  # Wait until the X server answers and xrandr can query it
  # (guards against races when the session starts very quickly)
  tries=0
  until xrandr --query >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -ge 20 ] && break # ~2 seconds total
    sleep 0.1
  done

  # Give the displays a brief moment to expose EDID/connect states
  sleep 0.5

  # Probe connection state with a few retries (helps slow handshakes/adapters)
  connected_bottom=0
  connected_top=0
  for _ in 1 2 3; do
    XR="$(
      xrandr --query 2>/dev/null
    )"
    echo "$XR" | grep -q "^$BOTTOM connected" && connected_bottom=1 || connected_bottom=0
    echo "$XR" | grep -q "^$TOP connected" && connected_top=1 || connected_top=0
    [ "$connected_bottom" -eq 1 ] || [ "$connected_top" -eq 1 ] || sleep 0.3
  done

  # Apply layout based on what is actually present
  if [ "$connected_bottom" -eq 1 ] && [ "$connected_top" -eq 1 ]; then
    # Both screens: bottom primary, top rotated 180° above bottom
    xrandr \
      --output "$BOTTOM" --auto --primary \
      --output "$TOP" --auto --rotate inverted --above "$BOTTOM"
  elif [ "$connected_bottom" -eq 1 ]; then
    # Only bottom screen connected
    xrandr \
      --output "$TOP" --off \
      --output "$BOTTOM" --auto --primary
  elif [ "$connected_top" -eq 1 ]; then
    # Only top screen connected (physically upside-down → rotate inverted)
    xrandr \
      --output "$BOTTOM" --off \
      --output "$TOP" --auto --primary --rotate inverted
  else
    # Neither DP-5 nor DP-6 reported as connected.
    # Fall back to xrandr's default auto-detection so you still get a picture
    # (e.g., if you temporarily use HDMI or a different port).
    xrandr --auto
  fi
fi

# ───────── 4) DWM Launch & Cleanup ─────────

# Ensure all background processes terminate when X session ends
trap 'kill -- -$$' EXIT

# DWM restart loop
# If DWM crashes or you reload config (Mod+Shift+Q), it restarts automatically
# Exit loop by logging out (Mod+Shift+E) or closing X server
while true; do
  /usr/local/bin/dwm 2>/tmp/dwm.log
done
