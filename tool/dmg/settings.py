# dmgbuild settings for the Whowolf disk image.
#
# dmgbuild writes the Finder layout (.DS_Store) itself instead of remote
# controlling Finder, so the image looks the same when a CI runner builds it.
# Called from tool/package_dmg.sh with
#   -D app=<Whowolf.app> -D background=<background.tiff> -D icon=<AppIcon.icns>
# The icon positions match the plaques drawn in background.svg.
import os.path

application = defines["app"]  # noqa: F821 (injected by dmgbuild)
appname = os.path.basename(application)

format = "UDZO"
filesystem = "HFS+"
compression_level = 9

files = [application]
symlinks = {"Applications": "/Applications"}
hide_extension = [appname]

icon = defines["icon"]  # noqa: F821
background = defines["background"]  # noqa: F821

# The background is 660 x 420 points; Finder counts its 28 pt title bar in.
window_rect = ((200, 140), (660, 448))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 0

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = "bottom"
text_size = 13
icon_size = 112

icon_locations = {
    appname: (170, 215),
    "Applications": (490, 215),
}
