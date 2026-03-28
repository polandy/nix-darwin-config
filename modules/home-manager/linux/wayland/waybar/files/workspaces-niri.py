#!/usr/bin/env python3
"""Waybar custom/wsN module for Niri.

Run one instance per workspace: workspaces-niri.py --workspace N
Outputs JSON with CSS class so waybar can style the active workspace.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from icons import APP_ICONS, APP_DEFAULT, WORKSPACE_PLACEHOLDERS as PLACEHOLDER

DEFAULT_ICON = APP_DEFAULT

TRIGGER_EVENTS = {
    "WorkspacesChanged",
    "WorkspaceActivated",
    "WindowOpenedOrChanged",
    "WindowClosed",
    "WindowFocusChanged",
}


def niri_msg(*args) -> list | dict:
    result = subprocess.run(["niri", "msg", "--json"] + list(args), capture_output=True, text=True)
    return json.loads(result.stdout)


def app_icon(app_id: str) -> str:
    key = app_id.lower()
    for k, icon in APP_ICONS.items():
        if k in key:
            return icon
    return DEFAULT_ICON


def build_output(ws_idx: int) -> dict:
    workspaces = niri_msg("workspaces")
    windows = niri_msg("windows")

    focused_idx = None
    ws_id = None
    for ws in workspaces:
        if ws.get("is_focused"):
            focused_idx = ws.get("idx")
        if ws.get("idx") == ws_idx:
            ws_id = ws.get("id")

    icons: list[str] = []
    for win in windows:
        if win.get("workspace_id") == ws_id:
            icon = app_icon(win.get("app_id", ""))
            if icon not in icons:
                icons.append(icon)

    is_active = ws_idx == focused_idx
    is_empty = len(icons) == 0
    icon_part = PLACEHOLDER.get(ws_idx, str(ws_idx)) if is_empty else " ".join(icons)
    text = f"{ws_idx} {icon_part}"

    css_class = "active" if is_active else ("empty" if is_empty else "")
    return {"text": text, "class": css_class}


def emit(ws_idx: int) -> None:
    print(json.dumps(build_output(ws_idx)), flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace", type=int, required=True)
    args = parser.parse_args()
    ws = args.workspace

    emit(ws)

    proc = subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE,
        text=True,
    )

    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
            event_type = next(iter(event)) if isinstance(event, dict) else None
            if event_type in TRIGGER_EVENTS:
                emit(ws)
        except json.JSONDecodeError:
            continue


if __name__ == "__main__":
    main()
