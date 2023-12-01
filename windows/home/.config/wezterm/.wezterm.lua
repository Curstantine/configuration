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
config.font_size = 13

local theme_colors = {
      mantle = "#181825",
      base = '#2c2e34',
      surface_0 = '#313244',
      overlay_1 = '#7f849c',
      text = "#cdd6f4",
  }

config.hide_tab_bar_if_only_one_tab = true

config.window_frame = {
      font = wezterm.font { family = 'Inter', weight = 'Bold' },
      font_size = 10.0,
      active_titlebar_bg = 'black',
      inactive_titlebar_bg = '#2b2b2b',
}

config.colors = {
      background = 'black',
      tab_bar = {
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
                  bg_color = theme_colors.base,
                  fg_color = theme_colors.text,
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


--- Start Exec Specific Settings ---
wezterm.on('update-status', function(window, pane)
      local overrides = window:get_config_overrides() or {}

      if string.find(pane:get_title(), 'hx.*') then
            overrides.window_padding = {
                  left = 0,
                  right = 0,
                  top = 0,
                  bottom = 0,
            }
      else
            overrides.window_padding = {
                  left = '1cell',
                  right = '1cell',
                  top = '0.5cell',
                  bottom = '0.5cell',
            }
      end
      
      window:set_config_overrides(overrides)
end)
--- END Exec Specific Settings ---


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
