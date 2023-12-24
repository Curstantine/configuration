local wezterm = require 'wezterm'

local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

--- START General Settings ---
config.default_prog = { 'nu.exe' }
--- END General Settings ---

--- START Theme Settings ---
config.color_scheme = 'Sonokai (Gogh)'
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 11

local theme_colors = {
      mantle = "#181825",
      base = '#2c2e34',
      surface_0 = '#313244',
      overlay_1 = '#7f849c',
      text = "#cdd6f4",
  }

config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.window_frame = {
      font = wezterm.font { family = 'Inter', weight = 'Bold' },
      font_size = 10.0,
      active_titlebar_bg = 'black',
      inactive_titlebar_bg = 'black',
}

config.colors = {
      background = 'black',
      tab_bar = {
            background = 'black',
            inactive_tab_edge = 'none',
            inactive_tab = {
                  bg_color = 'none',
                  fg_color = theme_colors.overlay_1,
              },
            inactive_tab_hover = {
                  bg_color = theme_colors.mantle,
                  fg_color = theme_colors.overlay_1,
              },
            active_tab = {
                  bg_color = 'none',
                  fg_color = theme_colors.text,
                  underline = 'Single',
              },
            new_tab = {
                  bg_color = 'none',
                  fg_color = theme_colors.overlay_1,
              },
            new_tab_hover = {
                  bg_color = 'none',
                  fg_color = theme_colors.text,
              }
        },
  }


--- END Theme Settings ---


--- START Key Bindings ---
local keys = {}

table.insert(keys, {
      key = 'F1',
      mods = 'CTRL',
      action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  })

config.keys = keys
--- END Key Bindings ---

return config
