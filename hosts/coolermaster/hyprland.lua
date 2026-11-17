-- coolermaster-specific Hyprland config, deployed as ~/.config/hypr/host.lua and loaded at the
-- end of the shared hyprland.lua.

-- NVIDIA (x1 has Intel graphics; these would break its VA-API video decoding)
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
