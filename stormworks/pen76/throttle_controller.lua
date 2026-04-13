local gn, gb = input.getNumber, input.getBool
local sn, sb = output.setNumber, output.setBool

-- Tunables
local THR_UP_RATE        = 0.010
local THR_DOWN_RATE      = 0.020
local BRK_UP_RATE        = 0.030
local BRK_DOWN_RATE      = 0.020
local LOCAL_BRK_RATE     = 0.020
local REGEN_MAX_SHARE    = 0.70
local SPEED_REGEN_CUTOFF = 16.6667 -- 60 km/h in m/s
local GRACE_TICKS        = 12      -- 200 ms at 60 fps

-- State memory
local mainState = 3
local localState = 3

local lastWS = 0
local lastUD = 0

local tractionMem = 0.0
local mainBrakeMem = 0.0
local localBrakeMem = 0.0
local EB = false

-- Grace timers
local mainGraceTimer = 0
local localGraceTimer = 0

local function clamp(x, a, b)
    if x < a then return a
    elseif x > b then return b
    else return x end
end

local function mainStateToPivot(state)
    if state == 1 then
        return 0.25
    elseif state == 2 then
        return 0.125
    elseif state == 3 then
        return 0.0
    elseif state == 4 then
        return -0.125
    elseif state == 5 then
        return -0.1875
    elseif state == 6 then
        return -0.25
    end
    return 0.0
end

local function localStateToPivot(state)
    if state == 1 then
        return 0.25
    elseif state == 2 then
        return 0.125
    elseif state == 3 then
        return 0.0
    elseif state == 4 then
        return -0.125
    elseif state == 5 then
        return -0.25
    end
    return 0.0
end

function onTick()
    -- Inputs
    local revSel   = gn(1) or 0
    local ws       = gn(2) or 0
    local ud       = gn(3) or 0
    local speed    = gn(4) or 0
    local master   = gb(1)
    local resetEB  = gb(2)

    -- Reverser interpretation
    local dirSign = 0
    local revBool = false
    if revSel > 0.5 then
        dirSign = 1
        revBool = false
    elseif revSel < -0.5 then
        dirSign = -1
        revBool = true
    end

    local neutral = (dirSign == 0)

    -- Edge detect
    local pressedW    = (ws >  0.5 and lastWS <=  0.5)
    local pressedS    = (ws < -0.5 and lastWS >= -0.5)
    local pressedUp   = (ud >  0.5 and lastUD <=  0.5)
    local pressedDown = (ud < -0.5 and lastUD >= -0.5)

    -- Neutral lock: don't allow power-side states in neutral
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

    -- Grace-period spring return for momentary states only
    if math.abs(ws) <= 0.5 then
        if mainState == 1 or mainState == 4 then
            if mainGraceTimer > 0 then
                mainGraceTimer = mainGraceTimer - 1
            else
                if mainState == 1 then
                    mainState = 2
                elseif mainState == 4 then
                    mainState = 3
                end
            end
        else
            mainGraceTimer = 0
        end
    else
        if mainState ~= 1 and mainState ~= 4 then
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
    else
        if localState ~= 2 and localState ~= 4 then
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

    -- Main controller behaviour
    if not EB then
        -- During grace with input released, momentary states behave like their normal return states:
        -- 1 behaves like 2, 4 behaves like 3
        local mainEffState = mainState
        if math.abs(ws) <= 0.5 and mainGraceTimer > 0 then
            if mainState == 1 then
                mainEffState = 2
            elseif mainState == 4 then
                mainEffState = 3
            end
        end

        if mainEffState == 1 then
            -- Increase power
            tractionMem = clamp(tractionMem + THR_UP_RATE, 0, 1)
            mainBrakeMem = clamp(mainBrakeMem - BRK_DOWN_RATE, 0, 1)

        elseif mainEffState == 2 then
            -- Maintain power / Decrease brake force
            mainBrakeMem = clamp(mainBrakeMem - BRK_DOWN_RATE, 0, 1)

        elseif mainEffState == 3 then
            -- Maintain brake force / Decrease power
            tractionMem = clamp(tractionMem - THR_DOWN_RATE, 0, 1)

        elseif mainEffState == 4 then
            -- Increase brake force
            tractionMem = 0
            mainBrakeMem = clamp(mainBrakeMem + BRK_UP_RATE, 0, 1)

        elseif mainEffState == 5 then
            -- Full braking
            tractionMem = 0
            mainBrakeMem = 1
        end
    end

    -- Local brake behaviour
    -- During grace with input released, 2 and 4 behave like 3 (hold), not ramp states
    local localEffState = localState
    if math.abs(ud) <= 0.5 and localGraceTimer > 0 then
        if localState == 2 or localState == 4 then
            localEffState = 3
        end
    end

    if localEffState == 1 then
        -- Release brake
        localBrakeMem = 0

    elseif localEffState == 2 then
        -- Decrease brake force
        localBrakeMem = clamp(localBrakeMem - LOCAL_BRK_RATE, 0, 1)

    elseif localEffState == 3 then
        -- Maintain brake force
        -- hold

    elseif localEffState == 4 then
        -- Increase brake force
        localBrakeMem = clamp(localBrakeMem + LOCAL_BRK_RATE, 0, 1)

    elseif localEffState == 5 then
        -- Full braking
        localBrakeMem = 1
    end

    -- Traction interlock
    local tractionEnabled = master and (dirSign ~= 0) and (not EB)
    if not tractionEnabled then
        tractionMem = 0
    end

    -- Final brake demand
    local finalBrake = math.max(mainBrakeMem, localBrakeMem)

    -- Final outputs
    local throttleOut = 0
    local brakeOut = 0
    local regenOut = 0

    if EB then
        throttleOut = 0
        brakeOut = 1
        regenOut = 1
    else
        throttleOut = tractionMem

        if finalBrake > 0 then
            throttleOut = 0

            if localBrakeMem > 0 then
                -- Local brake applied: use original blended logic
                regenOut = math.min(finalBrake, REGEN_MAX_SHARE)
                brakeOut = math.max(0, finalBrake - REGEN_MAX_SHARE)
            else
                -- Main brake only: speed-based logic
                if speed > SPEED_REGEN_CUTOFF then
                    regenOut = finalBrake
                    brakeOut = 0
                else
                    regenOut = 0
                    brakeOut = finalBrake
                end
            end
        end
    end

    local coast = (throttleOut < 0.001 and finalBrake < 0.001)
    local mainPivot = mainStateToPivot(mainState)
    local localPivot = localStateToPivot(localState)

    -- Number outputs
    sn(1, clamp(throttleOut, 0, 1))
    sn(2, clamp(brakeOut, 0, 1))
    sn(3, clamp(regenOut, 0, 1))
    sn(4, dirSign)
    sn(5, mainPivot)
    sn(6, mainState)
    sn(7, localPivot)
    sn(8, localState)
    sn(9, tractionMem)
    sn(10, mainBrakeMem)
    sn(11, localBrakeMem)

    -- Bool outputs
    sb(1, EB)
    sb(2, tractionEnabled)
    sb(3, coast)
    sb(4, revBool)
    sb(5, neutral)

    lastWS = ws
    lastUD = ud
end
