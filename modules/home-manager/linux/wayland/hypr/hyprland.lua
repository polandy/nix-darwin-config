-- Hyprland configuration
-- See https://wiki.hypr.land/Configuring/Start/
-- API stubs: /usr/share/hypr/stubs/hl.meta.lua

-- Monitor config — kanshi handles multi-monitor profiles
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.25,
})

-- Variables
local mod         = "SUPER"
local terminal    = "alacritty"
local fileManager = "thunar"

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/waybar/launch-hyprland.sh")
    hl.exec_cmd("env QT_QPA_PLATFORM=xcb nextcloud")
    hl.exec_cmd("copyq")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("kanshi")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprswitch init --show-title")
    hl.exec_cmd("dunst")
end)

-- Random wallpaper on start and on every reload
local function randomWallpaper()
    hl.exec_cmd([[awww img "$(find ~/Nextcloud/wallpapers/ -iname "*.jpg" -o -iname "*.png" | shuf -n1)"]])
end
hl.on("hyprland.start", randomWallpaper)
hl.on("config.reloaded", randomWallpaper)

hl.config({
    input = {
        kb_layout          = "us",
        kb_options         = "compose:ralt,caps:escape",
        numlock_by_default = true,
        follow_mouse       = 0,

        touchpad = {
            natural_scroll = false,
        },

        sensitivity = 0,
    },

    general = {
        gaps_in     = 3,
        gaps_out    = 5,
        border_size = 2,

        -- Catppuccin Macchiato — blue → mauve, matches waybar/dunst
        col = {
            active_border   = { colors = { "rgba(8aadf4ee)", "rgba(c6a0f6ee)" }, angle = 45 },
            inactive_border = "rgba(494d64aa)",
        },

        layout = "dwindle",

        -- Drag window borders/gaps with the mouse to resize
        resize_on_border        = true,
        extend_border_grab_area = 10,

        allow_tearing = false,
    },

    decoration = {
        rounding = 10,

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(181926ee)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
    },

    xwayland = {
        force_zero_scaling = true, -- prevents blur on XWayland apps with fractional scaling
    },
})

-- Snappy: ~100ms, no overshoot, workspaces switch instantly
hl.curve("snap", { type = "bezier", points = { { 0.2, 1 }, { 0.3, 1 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 1, bezier = "snap", style = "popin 95%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 1, bezier = "snap" })
hl.animation({ leaf = "border",     enabled = true, speed = 1, bezier = "snap" })
hl.animation({ leaf = "workspaces", enabled = false })

-- Window rules
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "float-misc",
    match = { class = "^(pavucontrol|blueman-manager|galculator|copyq|steam)$" },
    float = true,
})

hl.window_rule({
    name  = "tile-steam",
    match = { class = "^(steam)$", title = "^(Steam)$" },
    tile  = true,
})

hl.window_rule({
    name  = "ws-thunderbird",
    match = { class = "^(thunderbird)$" },
    workspace = "2",
})

hl.window_rule({
    name  = "ws-firefox",
    match = { class = "^(firefox)$" },
    workspace = "4",
})

hl.window_rule({
    name  = "ws-idea",
    match = { class = "^(jetbrains-idea)$" },
    workspace = "6",
})

-- ─── Keybindings ──────────────────────────────────────────────────────────────

local function bind(mods, key, action, opts)
    local keys = mods == "" and key or (mods .. " + " .. key)
    hl.bind(keys, action, opts)
end

local exec = hl.dsp.exec_cmd

-- Core
bind(mod,              "Return", exec(terminal))
bind(mod,              "D",      exec("rofi -show run"))
bind(mod .. " + CTRL", "D",      exec("rofi -show combi"))
bind(mod,              "Tab",    exec("rofi -show window"))
-- hyprswitch 5 installs its own submap (via hyprctl eval) for repeated Tab presses.
-- Its Alt release bind never fires: Hyprland only matches release binds in the submap the key was
-- pressed in, and Alt goes down in the default submap. So close (and switch) from here; no-op if closed.
bind("ALT",            "Tab",    exec("hyprswitch gui --mod-key ALT --key TAB --close mod-key-release && hyprswitch dispatch"))
bind("ALT",            "Alt_L",  exec("hyprswitch close"), { release = true, transparent = true })
bind(mod,              "E",      exec(fileManager))
bind(mod .. " + SHIFT", "Q",     hl.dsp.window.close())
bind(mod .. " + SHIFT", "space", hl.dsp.window.float({ action = "toggle" }))
bind(mod,              "P",      hl.dsp.window.pin())
bind(mod,              "F",      hl.dsp.window.fullscreen())
bind(mod,              "B",      hl.dsp.layout("preselect r"))
bind(mod,              "V",      hl.dsp.layout("preselect d"))
bind(mod,              "O",      hl.dsp.layout("togglesplit"))
bind(mod .. " + SHIFT", "C",     exec("hyprctl reload"))
bind(mod .. " + SHIFT", "W",     exec("pkill waybar && ~/.config/waybar/launch-hyprland.sh"))
bind(mod,              "Escape", exec("hyprlock-safe"))

-- Focus / move windows — arrow keys + HJKL
local directions = {
    { key = "left",  vim = "H", dir = "left" },
    { key = "right", vim = "L", dir = "right" },
    { key = "up",    vim = "K", dir = "up" },
    { key = "down",  vim = "J", dir = "down" },
}
for _, d in ipairs(directions) do
    bind(mod,               d.key, hl.dsp.focus({ direction = d.dir }))
    bind(mod,               d.vim, hl.dsp.focus({ direction = d.dir }))
    bind(mod .. " + SHIFT", d.key, hl.dsp.window.move({ direction = d.dir }))
    bind(mod .. " + SHIFT", d.vim, hl.dsp.window.move({ direction = d.dir }))
end

-- Workspaces — numbered (0 → 10)
for i = 1, 10 do
    local key = tostring(i % 10)
    bind(mod,               key, hl.dsp.focus({ workspace = tostring(i) }))
    bind(mod .. " + SHIFT", key, hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end

-- Workspaces — navigation
bind(mod,               "Prior",     hl.dsp.focus({ workspace = "e-1" }))
bind(mod,               "Next",      hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + CTRL",  "H",         hl.dsp.focus({ workspace = "e-1" }))
bind(mod .. " + CTRL",  "L",         hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + SHIFT", "Prior",     hl.dsp.window.move({ workspace = "e-1", follow = true }))
bind(mod .. " + SHIFT", "Next",      hl.dsp.window.move({ workspace = "e+1", follow = true }))
bind(mod .. " + SHIFT", "BackSpace", hl.dsp.focus({ workspace = "previous" }))
bind(mod .. " + SHIFT", "B",         hl.dsp.window.move({ workspace = "previous", follow = true }))
bind(mod,               "N",         hl.dsp.focus({ workspace = "empty" }))

-- Special workspace (scratchpad)
bind(mod,               "S", hl.dsp.workspace.toggle_special("default"))
bind(mod .. " + SHIFT", "S", hl.dsp.window.move({ workspace = "special:default", follow = true }))

-- Mouse workspace scroll
bind(mod, "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mod, "mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
bind(mod, "mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mod, "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume
bind("",  "XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
bind("",  "XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
bind("",  "XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
bind(mod, "XF86AudioMute",        exec("pavucontrol"))

-- Media
bind("", "XF86AudioPlay",  exec("playerctl play-pause"))
bind("", "XF86AudioPause", exec("playerctl play-pause"))
bind("", "XF86AudioNext",  exec("playerctl next"))
bind("", "XF86AudioPrev",  exec("playerctl previous"))

-- Brightness
bind("", "XF86MonBrightnessUp",   exec("brightnessctl set +5%"))
bind("", "XF86MonBrightnessDown", exec("brightnessctl set 5%-"))

-- Display / monitor management
bind("",  "XF86Display", exec("nwg-displays"))
bind(mod, "M",           exec("kanshictl reload"))

-- Clamshell mode: kanshi owns the outputs (it re-enables anything disabled behind its back), so
-- the lid switches kanshi profiles. "clamshell" only matches with one external monitor connected,
-- "clamshell-dual" with two; reloading lets kanshi pick the first matching profile again.
local clamshell = "kanshictl switch clamshell || kanshictl switch clamshell-dual"
bind("", "switch:on:Lid Switch",  exec(clamshell),           { locked = true })
bind("", "switch:off:Lid Switch", exec("kanshictl reload"), { locked = true })

-- Switch binds only fire on change, so apply a lid closed at login too (once kanshi is up)
hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 1 && grep -q closed /proc/acpi/button/lid/LID/state && { " .. clamshell .. "; }")
end)

-- screenshot
bind("", "Print", exec([[grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png]]))

-- ─── Submaps ──────────────────────────────────────────────────────────────────

-- Run a dispatcher, then leave the submap
local function andReset(action)
    return function()
        hl.dispatch(action)
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

-- kblayout — keyboard layout switching
local function setLayout(layout, options)
    return function()
        hl.config({ input = { kb_layout = layout, kb_options = options } })
        hl.dispatch(hl.dsp.submap("reset"))
    end
end

bind(mod, "Insert", hl.dsp.submap("kblayout"))
hl.define_submap("kblayout", function()
    bind("", "U",      setLayout("us", "compose:ralt,caps:escape"))
    bind("", "C",      setLayout("ch", "caps:escape"))
    bind("", "Escape", hl.dsp.submap("reset"))
end)

-- resize
bind(mod, "R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local steps = {
        { key = "right", vim = "L", x =  10, y =   0 },
        { key = "left",  vim = "H", x = -10, y =   0 },
        { key = "up",    vim = "K", x =   0, y = -10 },
        { key = "down",  vim = "J", x =   0, y =  10 },
    }
    for _, s in ipairs(steps) do
        local action = hl.dsp.window.resize({ x = s.x, y = s.y, relative = true })
        bind("", s.key, action, { repeating = true })
        bind("", s.vim, action, { repeating = true })
    end
    bind("", "Escape", hl.dsp.submap("reset"))
end)

-- system — power/session management
bind(mod, "Pause", hl.dsp.submap("system"))
hl.define_submap("system", function()
    bind("",      "L",      andReset(exec("hyprlock-safe")))
    bind("",      "E",      hl.dsp.exit())
    bind("",      "S",      andReset(exec("systemctl suspend")))
    bind("",      "H",      andReset(exec("systemctl hibernate")))
    bind("",      "R",      andReset(exec("systemctl reboot")))
    bind("SHIFT", "S",      andReset(exec("systemctl poweroff -i")))
    bind("",      "Escape", hl.dsp.submap("reset"))
end)

-- thinkpad — ThinkPad-specific
bind(mod, "T", hl.dsp.submap("thinkpad"))
hl.define_submap("thinkpad", function()
    bind("", "Escape", hl.dsp.submap("reset"))
end)
