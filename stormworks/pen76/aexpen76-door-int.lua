-- PEN76 DOOR CONTROLLER v5.2 (STEP STATE FIX)

-- ===== PERSISTENT STATE =====

if left_open_pulse == nil then left_open_pulse = 0 end
if right_open_pulse == nil then right_open_pulse = 0 end
if left_close_pulse == nil then left_close_pulse = 0 end
if right_close_pulse == nil then right_close_pulse = 0 end

-- Edge detection
if last_panel_open == nil then last_panel_open = false end
if last_panel_close == nil then last_panel_close = false end


function onTick()

    -- ===== INPUTS =====
    local panel_open = input.getBool(1)
    local panel_close = input.getBool(2)
    local step_enabled = input.getBool(3)   -- ✔ STATE INPUT (FIXED)
    local master = input.getBool(4)
    local lock_number = math.floor(input.getNumber(1) + 0.5)

    local left_door_open = input.getBool(5)
    local right_door_open = input.getBool(6)

    -- ===== LOCK STATE =====
    local left_unlocked = (lock_number == 0 or lock_number == 3)
    local right_unlocked = (lock_number == 2 or lock_number == 3)

    output.setBool(1, master and not left_unlocked)
    output.setBool(2, master and not right_unlocked)

    -- ===== EDGE COMMANDS =====
    local cmd_open = panel_open and not last_panel_open and master
    local cmd_close = panel_close and not last_panel_close and master

    local open_left_cmd = cmd_open and left_unlocked
    local open_right_cmd = cmd_open and right_unlocked

    -- ===== PULSES =====
    if left_open_pulse > 0 then left_open_pulse = left_open_pulse - 1 end
    if right_open_pulse > 0 then right_open_pulse = right_open_pulse - 1 end
    if left_close_pulse > 0 then left_close_pulse = left_close_pulse - 1 end
    if right_close_pulse > 0 then right_close_pulse = right_close_pulse - 1 end

    if open_left_cmd and left_open_pulse == 0 then left_open_pulse = 1 end
    if open_right_cmd and right_open_pulse == 0 then right_open_pulse = 1 end

    if cmd_close then
        if left_close_pulse == 0 then left_close_pulse = 1 end
        if right_close_pulse == 0 then right_close_pulse = 1 end
    end

    output.setBool(3, left_open_pulse > 0)
    output.setBool(4, right_open_pulse > 0)
    output.setBool(5, left_close_pulse > 0)
    output.setBool(6, right_close_pulse > 0)

    -- =====================================================
    -- STEP SYSTEM (STATE-BASED, NO TOGGLES)
    -- =====================================================

    local step_left =
        step_enabled
        and master
        and left_unlocked
        and left_door_open

    local step_right =
        step_enabled
        and master
        and right_unlocked
        and right_door_open

    output.setBool(7, step_left)
    output.setBool(8, step_right)

    -- ===== UPDATE =====
    last_panel_open = panel_open
    last_panel_close = panel_close
end


function onDraw()
end
