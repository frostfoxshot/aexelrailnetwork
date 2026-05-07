local gn, gb = input.getNumber, input.getBool
local sn, sb = output.setNumber, output.setBool

-- Tunables
local TICKS_PER_SEC = 60

-- 1% initial bite, short delay, then 3 sec to full
local INITIAL_STEP = 0.01
local RAMP_DELAY_TICKS = 12 -- 0.2 sec
local THR_UP_RATE = 1 / (3 * TICKS_PER_SEC)
local BRK_UP_RATE = 1 / (3 * TICKS_PER_SEC)

local THR_DOWN_RATE = 0.020
local BRK_DOWN_RATE = 0.020
local LOCAL_BRK_RATE = 1 / (3 * TICKS_PER_SEC)

-- Regen/friction blend speeds
local SPEED_REGEN_FADE_START = 8.3333 -- 30 km/h
local SPEED_FULL_FRICTION    = 4.4444 -- 16 km/h

local GRACE_TICKS = 12

-- State memory
local mainState = 3
local localState = 3

local lastWS = 0
local lastUD = 0

local tractionMem = 0.0
local mainBrakeMem = 0.0
local localBrakeMem = 0.0
local EB = false

local mainGraceTimer = 0
local localGraceTimer = 0

local throttleDelay = 0
local mainBrakeDelay = 0
local localBrakeDelay = 0

local function clamp(x, a, b)
    if x < a then return a
    elseif x > b then return b
    else return x end
end

local function mainStateToPivot(state)
    if state == 1 then return 0.25
    elseif state == 2 then return 0.125
    elseif state == 3 then return 0.0
    elseif state == 4 then return -0.125
    elseif state == 5 then return -0.1875
    elseif state == 6 then return -0.25
    end
    return 0.0
end

local function localStateToPivot(state)
    if state == 1 then return 0.25
    elseif state == 2 then return 0.125
    elseif state == 3 then return 0.0
    elseif state == 4 then return -0.125
    elseif state == 5 then return -0.25
    end
    return 0.0
end

local function delayedRampUp(value, rate, delayName)
    if value <= 0 then
        value = INITIAL_STEP
        if delayName == "throttle" then throttleDelay = RAMP_DELAY_TICKS end
        if delayName == "mainBrake" then mainBrakeDelay = RAMP_DELAY_TICKS end
        if delayName == "localBrake" then localBrakeDelay = RAMP_DELAY_TICKS end
        return value
    end

    if delayName == "throttle" and throttleDelay > 0 then
        throttleDelay = throttleDelay - 1
        return value
    elseif delayName == "mainBrake" and mainBrakeDelay > 0 then
        mainBrakeDelay = mainBrakeDelay - 1
        return value
    elseif delayName == "localBrake" and localBrakeDelay > 0 then
        localBrakeDelay = localBrakeDelay - 1
        return value
    end

    return clamp(value + rate, 0, 1)
end

function onTick()
    local revSel  = gn(1) or 0
    local ws      = gn(2) or 0
    local ud      = gn(3) or 0
    local speed   = gn(4) or 0
    local master  = gb(1)
    local resetEB = gb(2)

    local dirSign = 0
    local revBool = false

    if revSel > 0.5 then
        dirSign = 1
        revBool = false
    elseif revSel < -0.5 then
        dirSign = -1
        revBool = true
    end

    local neutral = dirSign == 0

    local pressedW    = ws > 0.5 and lastWS <= 0.5
    local pressedS    = ws < -0.5 and lastWS >= -0.5
    local pressedUp   = ud > 0.5 and lastUD <= 0.5
    local pressedDown = ud < -0.5 and lastUD >= -0.5

    if neutral and (mainState == 1 or mainState == 2) then
        mainState = 3
        mainGraceTimer = 0
    end

    -- Main controller notch stepping
    if pressedW then
        if mainState == 6 then
            mainState = 5
        elseif mainState == 5 then
            mainState = 4
            mainGraceTimer = GRACE_TICKS
        elseif mainState == 4 then
            mainState = 3
            mainGraceTimer = 0
        elseif mainState == 3 then
            mainState = 2
        elseif mainState == 2 and not neutral then
            mainState = 1
            mainGraceTimer = GRACE_TICKS
        end
    elseif pressedS then
        if mainState == 1 then
            mainState = 2
            mainGraceTimer = 0
        elseif mainState == 2 then
            mainState = 3
        elseif mainState == 3 then
            mainState = 4
            mainGraceTimer = GRACE_TICKS
        elseif mainState == 4 then
            mainState = 5
            mainGraceTimer = 0
        elseif mainState == 5 then
            mainState = 6
            mainGraceTimer = 0
        end
    end

    -- Local brake notch stepping
    if pressedUp then
        if localState == 5 then
            localState = 4
            localGraceTimer = GRACE_TICKS
        elseif localState == 4 then
            localState = 3
            localGraceTimer = 0
        elseif localState == 3 then
            localState = 2
            localGraceTimer = GRACE_TICKS
        elseif localState == 2 then
            localState = 1
            localGraceTimer = 0
        end
    elseif pressedDown then
        if localState == 1 then
            localState = 2
            localGraceTimer = GRACE_TICKS
        elseif localState == 2 then
            localState = 3
            localGraceTimer = 0
        elseif localState == 3 then
            localState = 4
            localGraceTimer = GRACE_TICKS
        elseif localState == 4 then
            localState = 5
            localGraceTimer = 0
        end
    end

    -- Spring return
    if math.abs(ws) <= 0.5 then
        if mainState == 1 or mainState == 4 then
            if mainGraceTimer > 0 then
                mainGraceTimer = mainGraceTimer - 1
            else
                if mainState == 1 then mainState = 2 end
                if mainState == 4 then mainState = 3 end
            end
        else
            mainGraceTimer = 0
        end
    end

    if math.abs(ud) <= 0.5 then
        if localState == 2 or localState == 4 then
            if localGraceTimer > 0 then
                localGraceTimer = localGraceTimer - 1
            else
                localState = 3
            end
        else
            localGraceTimer = 0
        end
    end

    mainState = clamp(mainState, 1, 6)
    localState = clamp(localState, 1, 5)

    -- EB latch/reset
    if mainState == 6 then
        EB = true
    end

    if resetEB then
        EB = false
    end

    if not EB then
        local mainEffState = mainState

        if math.abs(ws) <= 0.5 and mainGraceTimer > 0 then
            if mainState == 1 then
                mainEffState = 2
            elseif mainState == 4 then
                mainEffState = 3
            end
        end

        if mainEffState == 1 then
            mainBrakeMem = clamp(mainBrakeMem - BRK_DOWN_RATE, 0, 1)
            tractionMem = delayedRampUp(tractionMem, THR_UP_RATE, "throttle")

        elseif mainEffState == 2 then
            mainBrakeMem = clamp(mainBrakeMem - BRK_DOWN_RATE, 0, 1)

        elseif mainEffState == 3 then
            tractionMem = clamp(tractionMem - THR_DOWN_RATE, 0, 1)
            if tractionMem <= 0 then throttleDelay = 0 end

        elseif mainEffState == 4 then
            tractionMem = 0
            throttleDelay = 0
            mainBrakeMem = delayedRampUp(mainBrakeMem, BRK_UP_RATE, "mainBrake")

        elseif mainEffState == 5 then
            tractionMem = 0
            throttleDelay = 0
            mainBrakeMem = 1
            mainBrakeDelay = 0
        end
    end

    -- Local brake
    local localEffState = localState

    if math.abs(ud) <= 0.5 and localGraceTimer > 0 then
        if localState == 2 or localState == 4 then
            localEffState = 3
        end
    end

    if localEffState == 1 then
        localBrakeMem = 0
        localBrakeDelay = 0

    elseif localEffState == 2 then
        localBrakeMem = clamp(localBrakeMem - LOCAL_BRK_RATE, 0, 1)
        if localBrakeMem <= 0 then localBrakeDelay = 0 end

    elseif localEffState == 3 then
        -- hold

    elseif localEffState == 4 then
        localBrakeMem = delayedRampUp(localBrakeMem, LOCAL_BRK_RATE, "localBrake")

    elseif localEffState == 5 then
        localBrakeMem = 1
        localBrakeDelay = 0
    end

    -- Traction interlock
    local tractionEnabled = master and dirSign ~= 0 and not EB

    if not tractionEnabled then
        tractionMem = 0
        throttleDelay = 0
    end

    local finalBrake = math.max(mainBrakeMem, localBrakeMem)

    local throttleOut = 0
    local brakeOut = 0
    local regenOut = 0

    if EB then
        throttleOut = 0
        brakeOut = 1
        regenOut = 0
    else
        throttleOut = tractionMem

        if finalBrake > 0 then
            throttleOut = 0

            if speed >= SPEED_REGEN_FADE_START then
                regenOut = finalBrake
                brakeOut = 0

            elseif speed <= SPEED_FULL_FRICTION then
                regenOut = 0
                brakeOut = finalBrake

            else
                local blend = (speed - SPEED_FULL_FRICTION) /
                              (SPEED_REGEN_FADE_START - SPEED_FULL_FRICTION)

                regenOut = finalBrake * blend
                brakeOut = finalBrake * (1 - blend)
            end
        end
    end

    local coast = throttleOut < 0.001 and finalBrake < 0.001

    sn(1, clamp(throttleOut, 0, 1))
    sn(2, clamp(brakeOut, 0, 1))
    sn(3, clamp(regenOut, 0, 1))
    sn(4, dirSign)
    sn(5, mainStateToPivot(mainState))
    sn(6, mainState)
    sn(7, localStateToPivot(localState))
    sn(8, localState)
    sn(9, tractionMem)
    sn(10, mainBrakeMem)
    sn(11, localBrakeMem)

    sb(1, EB)
    sb(2, tractionEnabled)
    sb(3, coast)
    sb(4, revBool)
    sb(5, neutral)

    lastWS = ws
    lastUD = ud
end
