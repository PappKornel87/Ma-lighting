-- TC_Gap_Analyzer.lua
-- A grandMA2 Lua Plugin for Timecode Gap Analysis and Countdown

-- Main function to be called when the plugin is executed
return function()
  -- Define the options for the main menu popup
  local menu_options = {
    "ANALYZE",
    "PLAYBACK",
    "STOP"
  }

  -- Show the popup menu and get the user's choice
  gma.feedback("TC_Gap_Analyzer: Choose a mode")
  local choice = gma.show.getobj.popupmodal("TC Gap Analyzer", "Select a mode:", menu_options)

  -- Process the user's choice
  if choice == 1 then
    -- ANALYZE mode
    gma.feedback("ANALYZE mode selected")
    local analyze_sequence = require("TC_Gap_Analyzer_Analyze")
    analyze_sequence()
  elseif choice == 2 then
    -- PLAYBACK mode
    gma.feedback("PLAYBACK mode selected")
    local playback = require("TC_Gap_Analyzer_Playback")
    playback.start()
  elseif choice == 3 then
    -- STOP mode
    gma.feedback("STOP mode selected")
    local playback = require("TC_Gap_Analyzer_Playback")
    playback.stop()
  else
    -- User cancelled the popup
    gma.feedback("TC_Gap_Analyzer: Operation cancelled")
  end
end
