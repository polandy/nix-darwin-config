#!/usr/bin/env bash

# This script uses the 'sketchybar-app-font' to provide icons.
# https://github.com/kvndrsslr/sketchybar-app-font

function get_app_icon {
  case "$1" in
    "Alacritty") echo ":alacritty:" ;;
    "Finder") echo ":finder:" ;;
    "Firefox") echo ":firefox:" ;;
    "Google Chrome") echo ":google_chrome:" ;;
    "Code") echo ":code:" ;;
    "Visual Studio Code") echo ":code:" ;;
    "Logseq") echo ":logseq:" ;;
    "Outlook"*) echo ":outlook:" ;;
    "Slack") echo ":slack:" ;;
    "WhatsApp") echo ":whatsapp:" ;;
    "IntelliJ IDEA") echo ":intellij_idea:" ;;
    "Raycast") echo ":raycast:" ;;
    "System Settings") echo ":gear:" ;;
    "Music") echo ":music:" ;;
    "Spotify") echo ":spotify:" ;;
    "Messages") echo ":messages:" ;;
    "Brave Browser") echo ":brave_browser:" ;;
    "KeePassXC") echo ":keepassxc:" ;;
    "Docker"*) echo ":docker:" ;;
    "UTM") echo ":utm:" ;;
    *) echo ":default:" ;;
  esac
}
