-- TC_Gap_Analyzer_Playback.lua
-- This file contains the logic for the "PLAYBACK" and "STOP" modes of the TC_Gap_Analyzer plugin.

-- Global variables to manage the playback state
local cue_durations          -- Stores the loaded analysis data
local current_cue_start_time -- The time when the current cue started
local current_cue_duration   -- The pre-calculated duration of the current cue

-- Function to load the analysis data from the file
--[[
  Loads the analysis data from the data file. This function is called when the
  "PLAYBACK" mode is initiated. It returns the data as a Lua table or nil if
  the file cannot be loaded.
]]
local function load_data()
  local file_path = "./TC_Gap_Analyzer_data.lua"
  local f = loadfile(file_path)
  if f then
    return f()
  else
    gma.feedback("Error: Could not load data file. Please run ANALYZE mode first.")
    return nil
  end
end

-- The main loop function that runs at 10Hz
--[[
  The core countdown loop that runs in the background. This function is executed
  approximately 10 times per second. It monitors the selected executor for cue
  changes and updates the countdown timer accordingly.
]]
local function countdown_loop()
  -- Get the handle of the currently selected executor
  local selected_exec = gma.show.getobj.handle("selectedexec")
  if not selected_exec or selected_exec == 0 then
    -- If no executor is selected, do nothing and wait.
    gma.show.setvar("$TC_COUNTDOWN", "Select Exec")
    return
  end

  -- Get the handle of the currently active cue on the selected executor
  local current_cue_handle = gma.show.getobj.property(selected_exec, "currentcue")
  if not current_cue_handle or current_cue_handle == 0 then
    gma.show.setvar("$TC_COUNTDOWN", "No Active Cue")
    return
  end

  local current_cue_number = gma.show.getobj.number(current_cue_handle)

  -- This block detects a cue change by comparing the current cue number with the last known one.
  if current_cue_number ~= gma.show.getvar("TC_Analyzer_Last_Cue") then
    -- When a new cue is detected, update the last cue variable and reset the timer
    gma.show.setvar("TC_Analyzer_Last_Cue", current_cue_number)
    current_cue_duration = cue_durations[current_cue_number]
    current_cue_start_time = gma.show.gettime()
  end

  -- This block performs the countdown calculation and updates the user variable
  if current_cue_duration and current_cue_start_time then
    local elapsed_time = gma.show.gettime() - current_cue_start_time
    local remaining_time = current_cue_duration - elapsed_time

    if remaining_time < 0 then
      remaining_time = 0
    end

    local minutes = math.floor(remaining_time / 60)
    local seconds = math.floor(remaining_time % 60)
    local formatted_time = string.format("%02d:%02d", minutes, seconds)

    gma.show.setvar("$TC_COUNTDOWN", formatted_time)
  end
end

-- Function to start the playback loop
--[[
  Starts the playback mode. This function loads the analysis data, initializes
  the necessary variables, and creates the background timer for the countdown loop.
]]
local function start_playback()
  cue_durations = load_data()
  if not cue_durations then
    return
  end

  gma.show.setvar("TC_Analyzer_Last_Cue", -1) -- Initialize last cue variable

  if not gma.show.getvar("TC_Analyzer_Timer") then
    local timer_handle = gma.show.createtimer(countdown_loop, 0.1, -1)
    gma.show.setvar("TC_Analyzer_Timer", tostring(timer_handle))
    gma.feedback("Playback loop started")
  else
    gma.feedback("Playback loop is already running")
  end
end

--[[
  Stops the playback mode. This function destroys the background timer, cleans up
  the user variables, and provides feedback to the user.
]]
local function stop_playback()
  local timer_handle_str = gma.show.getvar("TC_Analyzer_Timer")
  if timer_handle_str and timer_handle_str ~= "" then
    local timer_handle = tonumber(timer_handle_str)
    gma.show.destroytimer(timer_handle)
    gma.show.setvar("TC_Analyzer_Timer", nil)
    gma.show.setvar("$TC_COUNTDOWN", "Stopped")
    gma.feedback("Playback loop stopped")
  else
    gma.feedback("Playback loop is not running")
  end
end

return {
  start = start_playback,
  stop = stop_playback
}
