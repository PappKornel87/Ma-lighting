-- TC_Gap_Analyzer_Analyze.lua
-- This file contains the logic for the "ANALYZE" mode of the TC_Gap_Analyzer plugin.

--[[
  Serializes a Lua table into a string that can be saved to a file and later executed
  to reconstruct the table. This is a simple implementation that handles nested tables,
  numbers, and strings.
]]
local function serialize(obj)
  if type(obj) == "table" then
    local s = "{ "
    for k, v in pairs(obj) do
      s = s .. "[" .. serialize(k) .. "] = " .. serialize(v) .. ","
    end
    return s .. "} "
  else
    return tostring(obj)
  end
end

-- Function to save the analysis data to a file
--[[
  Saves the provided Lua table to the plugin's data file. The data is serialized
  to a string and written in a format that can be loaded back into a Lua table.
]]
local function save_data(data)
  -- Construct the full path to the data file, using a relative path
  local file_path = "./TC_Gap_Analyzer_data.lua"

  -- Open the file in write mode
  local file, err = io.open(file_path, "w")
  if file then
    -- Write the serialized data and close the file
    file:write("return " .. serialize(data))
    file:close()
    gma.feedback("Analysis Complete. Data saved to TC_Gap_Analyzer_data.lua")
  else
    -- Handle file writing errors
    gma.feedback("Error: Could not save analysis data. Details: " .. tostring(err))
  end
end

-- Main function for the ANALYZE mode
--[[
  The main function for the "ANALYZE" mode. This function handles the entire
  analysis process, from getting user input to saving the final data.
]]
return function()
  -- Prompt the user to enter the sequence number they want to analyze
  local sequence_input = gma.show.getobj.textinput("Enter Sequence Number")
  if not sequence_input then
    gma.feedback("Operation cancelled")
    return
  end
  local sequence_number = tonumber(sequence_input)
  if not sequence_number then
    gma.feedback("Invalid sequence number")
    return
  end

  -- Get the sequence object handle
  local sequence_handle_str = "Sequence "..sequence_number
  local sequence = gma.show.getobj.handle(sequence_handle_str)
  if not sequence or sequence == 0 then
    gma.feedback("Error: Sequence " .. sequence_number .. " not found.")
    return
  end

  -- Create a table to store the handles of all cues in the sequence
  local cues = {}
  for i = 1, gma.show.getobj.amount(sequence) do
    local cue_handle = gma.show.getobj.child(sequence, i)
    if cue_handle then
      table.insert(cues, cue_handle)
    end
  end

  -- This table will store the calculated durations for each cue
  local cue_durations = {}
  -- Iterate through each cue to determine its duration to the next cue
  for i, current_cue in ipairs(cues) do
    local current_cue = cues[i]
    local next_cue = cues[i + 1]
    local current_cue_number = gma.show.getobj.number(current_cue)

    if next_cue then
      local trig_type = gma.show.getobj.property(next_cue, "trigType")
      local trig_time_str = gma.show.getobj.property(next_cue, "trigTime")

      -- Convert TrigTime to seconds
      local trig_time_seconds = 0
      if trig_time_str and trig_time_str ~= "00:00:00.00" then
          local h, m, s, f = trig_time_str:match("(%d+):(%d+):(%d+).(%d+)")
          trig_time_seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(f) / 100
      end

      local current_trig_time_str = gma.show.getobj.property(current_cue, "trigTime")
      local current_trig_time_seconds = 0
      if current_trig_time_str and current_trig_time_str ~= "00:00:00.00" then
          local h, m, s, f = current_trig_time_str:match("(%d+):(%d+):(%d+).(%d+)")
          current_trig_time_seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(f) / 100
      end

      -- Scenario A: The next cue is triggered by Timecode and has a valid time
      if trig_type == "Timecode" and trig_time_seconds > 0 then
        -- Calculate the duration between the current and next cue's timecode
        cue_durations[current_cue_number] = trig_time_seconds - current_trig_time_seconds
      else
        -- Scenario B: The next cue is not triggered by Timecode or the time is invalid
        -- Prompt the user to manually enter the duration
        local user_input = gma.show.getobj.textinput("Cue " .. current_cue_number .. " has no Timecode. Enter duration in seconds:")
        if user_input and tonumber(user_input) then
          cue_durations[current_cue_number] = tonumber(user_input)
        else
          gma.feedback("Invalid input or operation cancelled.")
          return
        end
      end
    else
      -- This is the last cue in the sequence, so its duration is 0
      cue_durations[current_cue_number] = 0
    end
  end

  -- Save the final analysis data to the file
  save_data(cue_durations)
end
