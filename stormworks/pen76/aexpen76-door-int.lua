-- PEN76 DOOR CONTROLLER v2.0
-- State machine with MU support, side-selective locking, and step/ramp control

-- ===== PERSISTENT STATE (retained between ticks) =====
if left_open == nil then left_open = false end
if right_open == nil then right_open = false end
if left_step_deployed == nil then left_step_deployed = false end
if right_step_deployed == nil then right_step_deployed = false end
if prev_step_button == nil then prev_step_button = false end

function onTick()
    -- ===== INPUT CHANNEL MAPPING (adjust if needed) =====
    -- Panel (cab) inputs
    local panel_open = input.getBool(1)       -- Open doors button
    local panel_close = input.getBool(2)      -- Close doors button
    local panel_step = input.getBool(3)       -- Deploy steps button
    local master_enable = input.getBool(4)    -- This cab is master
    
    -- Lock selector (0=left unlocked, 1=all locked, 2=right unlocked, 3=both)
    local lock_number = input.getNumber(1)    -- Number channel 1, value 0-3
    lock_number = math.floor(lock_number + 0.5)  -- round to nearest integer
    
    -- Front connector (unit facing same direction)
    local front_open_left = input.getBool(5)
    local front_open_right = input.getBool(6)
    local front_close = input.getBool(7)
    
    -- Rear connector (unit facing opposite direction)
    -- Because the rear unit is reversed, we swap its left/right commands
    local rear_raw_open_left = input.getBool(8)   -- from rear's "open left"
    local rear_raw_open_right = input.getBool(9)  -- from rear's "open right"
    local rear_close = input.getBool(10)
    
    -- Apply swap for rear connector
    local rear_open_left = rear_raw_open_right   -- rear's right becomes our left
    local rear_open_right = rear_raw_open_left   -- rear's left becomes our right
    
    -- ===== DECODE LOCK NUMBER =====
    local left_unlocked = false
    local right_unlocked = false
    if lock_number == 0 then      -- left only
        left_unlocked = true
        right_unlocked = false
    elseif lock_number == 1 then  -- both locked
        left_unlocked = false
        right_unlocked = false
    elseif lock_number == 2 then  -- right only
        left_unlocked = false
        right_unlocked = true
    elseif lock_number == 3 then  -- both unlocked
        left_unlocked = true
        right_unlocked = true
    else                          -- safety fallback: both locked
        left_unlocked = false
        right_unlocked = false
    end
    
    -- ===== DETERMINE ACTIVE COMMANDS =====
    -- Open/close from panel only if master enabled
    local cmd_open = false
    local cmd_close = false
    local cmd_step = false
    
    if master_enable then
        cmd_open = panel_open
        cmd_close = panel_close
        cmd_step = panel_step
    end
    
    -- MU commands always override (any unit in consist can control)
    cmd_open = cmd_open or front_open_left or front_open_right or rear_open_left or rear_open_right
    cmd_close = cmd_close or front_close or rear_close
    
    -- ===== DOOR STATE MACHINE =====
    -- Open command: open unlocked sides
    if cmd_open then
        if left_unlocked then
            left_open = true
        end
        if right_unlocked then
            right_open = true
        end
    end
    
    -- Close command: close all doors and retract steps
    if cmd_close then
        left_open = false
        right_open = false
        left_step_deployed = false
        right_step_deployed = false
    end
    
    -- Step command (rising edge detection)
    if cmd_step and not prev_step_button then
        -- Deploy step on any currently open side
        if left_open then
            left_step_deployed = true
        end
        if right_open then
            right_step_deployed = true
        end
        -- If no doors open, steps remain retracted
    end
    prev_step_button = cmd_step
    
    -- Safety: if a door closes while step is deployed, retract step automatically
    if not left_open then
        left_step_deployed = false
    end
    if not right_open then
        right_step_deployed = false
    end
    
    -- ===== OUTPUTS TO DOOR MECHANISMS =====
    -- Door motors (open = true)
    output.setBool(1, left_open)      -- left door motor
    output.setBool(2, right_open)     -- right door motor
    
    -- Lock actuators (true = locked, false = unlocked)
    -- Locks engage only when door is fully closed
    output.setBool(3, not left_unlocked and not left_open)   -- left lock
    output.setBool(4, not right_unlocked and not right_open) -- right lock
    
    -- Step/ramp deploy
    output.setBool(5, left_step_deployed)    -- left step
    output.setBool(6, right_step_deployed)   -- right step
    
    -- ===== OUTPUTS TO CONNECTORS (MU) =====
    -- To front connector (same orientation)
    output.setBool(7, left_open)        -- front open left
    output.setBool(8, right_open)       -- front open right
    output.setBool(9, cmd_close)        -- front close (pulsed)
    
    -- To rear connector (swap left/right because rear unit is reversed)
    output.setBool(10, right_open)      -- rear "open left" (our right)
    output.setBool(11, left_open)       -- rear "open right" (our left)
    output.setBool(12, cmd_close)       -- rear close (pulsed)
    
    -- Optional: send lock number to other units (if you want MU lock sync)
    -- output.setNumber(1, lock_number)
end
