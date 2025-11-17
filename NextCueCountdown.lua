--[[
NextCueCountdown
A grandMA2 Lua plugin to display a countdown to the next cue based on cue timestamps.
]]
local NextCueCountdown = {}

local is_running = false
local main_loop_thread = nil

-- Placeholder for manual countdown
local manual_countdown_active = false
local manual_duration = 0
local manual_start_time = 0

-- Function to format the time into MM:SS.ms
local function format_time(seconds)
    if seconds < 0 then
        seconds = math.abs(seconds)
        local minutes = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        local ms = math.floor((seconds * 100) % 100)
        return string.format("-%02d:%02d.%02d", minutes, secs, ms)
    else
        local minutes = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        local ms = math.floor((seconds * 100) % 100)
        return string.format("%02d:%02d.%02d", minutes, secs, ms)
    end
end

-- The main loop of the plugin
local function main_loop()
    local last_cue_number = nil
    local cue_start_time = 0
    local total_duration = 0

    -- Helper to convert grandMA2 time string to seconds
    local function time_to_seconds(t_str)
        if t_str == nil or t_str == "" then return nil end
        local h, m, s = string.match(t_str, "(%d+):(%d+):(%d+%.?%d*)")
        if h then
            return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
        end
        return nil
    end

    while is_running do
        -- Handle manual countdown first
        if manual_countdown_active then
            local elapsed = gma.time() - manual_start_time
            if elapsed >= manual_duration then
                manual_countdown_active = false
                gma.show.setvar("$COUNTDOWN_TIMER", format_time(0))
            else
                local remaining = manual_duration - elapsed
                gma.show.setvar("$COUNTDOWN_TIMER", format_time(remaining))
            end
            gma.sleep(0.1)
            goto continue_loop
        end

        -- Automatic calculation logic
        local selected_exec_str = gma.gui.getvar("selectedexec") -- e.g., "1.201"
        if selected_exec_str == nil or selected_exec_str == "" then
            gma.show.setvar("$COUNTDOWN_TIMER", "---")
            last_cue_number = nil -- Reset cue tracking when no exec is selected
            gma.sleep(0.1)
            goto continue_loop
        end

        local path_str = "Page " .. string.gsub(selected_exec_str, "%.", " Exec ")
        local exec_handle = gma.show.getobj.handle(path_str)

        if exec_handle == 0 then
            gma.show.setvar("$COUNTDOWN_TIMER", "---")
            last_cue_number = nil
            gma.sleep(0.1)
            goto continue_loop
        end

        local current_cue_idx = gma.show.getobj.property(exec_handle, "CurrentCue")
        if current_cue_idx == nil or current_cue_idx == 0 then
            gma.show.setvar("$COUNTDOWN_TIMER", "---") -- No active cue
            last_cue_number = nil
            gma.sleep(0.1)
            goto continue_loop
        end

        -- Check if the cue has changed
        if current_cue_idx ~= last_cue_number then
            last_cue_number = current_cue_idx
            local cue_count = gma.show.getobj.property(exec_handle, "NoOfChildren")

            if current_cue_idx >= cue_count then -- It's the last cue
                total_duration = 0
            else
                local current_cue_handle = gma.show.getobj.child(exec_handle, current_cue_idx)
                local next_cue_handle = gma.show.getobj.child(exec_handle, current_cue_idx + 1)

                if current_cue_handle ~= 0 and next_cue_handle ~= 0 then
                    local current_cue_time_str = gma.show.getobj.property(current_cue_handle, "TrigTime")
                    local next_cue_time_str = gma.show.getobj.property(next_cue_handle, "TrigTime")

                    local current_cue_seconds = time_to_seconds(current_cue_time_str)
                    local next_cue_seconds = time_to_seconds(next_cue_time_str)

                    if current_cue_seconds and next_cue_seconds and next_cue_seconds > current_cue_seconds then
                        total_duration = next_cue_seconds - current_cue_seconds
                    else
                        total_duration = 0 -- No timestamp or invalid order, so no duration
                    end
                else
                    total_duration = 0
                end
            end
            cue_start_time = gma.time()
        end

        -- Calculate and display remaining time
        if total_duration <= 0 then
            gma.show.setvar("$COUNTDOWN_TIMER", format_time(0))
        else
            local elapsed_time = gma.time() - cue_start_time
            local remaining_time = total_duration - elapsed_time
            if remaining_time < 0 then remaining_time = 0 end
            gma.show.setvar("$COUNTDOWN_TIMER", format_time(remaining_time))
        end

        ::continue_loop::
        gma.sleep(0.1) -- Prevent freezing
    end
end

-- Public functions
function NextCueCountdown.start()
    if not is_running then
        is_running = true
        main_loop_thread = gma.coroutine.create(main_loop)
        gma.feedback("NextCueCountdown: Started")
    else
        gma.feedback("NextCueCountdown: Already running")
    end
end

function NextCueCountdown.stop()
    if is_running then
        is_running = false
        main_loop_thread = nil
        gma.feedback("NextCueCountdown: Stopped")
    else
        gma.feedback("NextCueCountdown: Not running")
    end
end

function NextCueCountdown.set(minutes, seconds)
    gma.feedback("NextCueCountdown: Manual override set to " .. minutes .. "m " .. seconds .. "s")
    manual_duration = (minutes * 60) + seconds
    manual_start_time = gma.time()
    manual_countdown_active = true
end

return NextCueCountdown
