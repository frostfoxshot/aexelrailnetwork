local gn, gb = input.getNumber, input.getBool
local sn, sb = output.setNumber, output.setBool

-- Tunables
local TICKS_PER_SEC = 60
local MAX_SPEED_MS = 160 / 3.6        -- 160 km/h hard limit (44.44 m/s)

-- Performance Windows (Enforced by Autotuner during active driving)
local TARGET_ACCEL_MIN = 0.8
local TARGET_ACCEL_MAX = 1.2
local TARGET_DECEL_MIN = 0.8
local TARGET_DECEL_MAX = 1.0

-- State Memory
local lastSpeed = 0.0
local tuneThrottle = 0.0
local tuneBrake = 0.0

-- Coasting Speed-Set Memory
local wasCoasting = false
local coastTargetSpeed = 0.0

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function onTick()
    -- Inputs mapping (Strictly 5 channels)
    local handlePower  = gn(1) or 0 -- Power handle input (0 to 1)
    local handleFric   = gn(2) or 0 -- Friction brake handle input (0 to 1)
    local handleRegen  = gn(3) or 0 -- Regen brake handle input (0 to 1)
    local speed        = gn(4) or 0 -- Velocity speed in m/s
    local tiltDeg      = gn(5) or 0 -- Tilt input in degrees

    -- Real-time physical acceleration tracking (m/s^2)
    local currentAccel = (speed - lastSpeed) * TICKS_PER_SEC
    local absSpeed = math.abs(speed)
    
    -- Direction vector based on velocity movement
    local dirSign = 1
    if speed < -0.05 then dirSign = -1 end

    local finalBrakeDemand = math.max(handleFric, handleRegen)
    local rawThrottleDemand = handlePower

    ------------------------------------------------------------------------
    -- DYNAMIC INCLINE VECTORING
    ------------------------------------------------------------------------
    -- Gravity vector computation: Positive tilt = nose up (climbing)
    local radTilt = math.rad(tiltDeg)
    local gravityForceFactor = math.sin(radTilt)

    -- Scale target acceleration windows based on slope angles
    local liveMaxAccel = clamp(TARGET_ACCEL_MAX - (gravityForceFactor * 1.5), TARGET_ACCEL_MIN, 1.5)
    local liveMaxDecel = clamp(TARGET_DECEL_MAX + (gravityForceFactor * 1.2), TARGET_DECEL_MIN, 1.4)

    local currentPerformance = math.abs(currentAccel)
    local tuneRate = 0.008 -- Sensitivity adjustment multiplier

    local throttleOut = 0.0
    local brakeFricOut = 0.0
    local brakeRegenOut = 0.0

    -- Check if operator is completely off the handles
    local coast = rawThrottleDemand < 0.01 and finalBrakeDemand < 0.01

    if coast then
        -- Initialize the Coasting Speed-Set target the frame handles are released
        if not wasCoasting then
            coastTargetSpeed = absSpeed
            wasCoasting = true
        end

        -- DYNAMIC MOMENTUM SIMULATION FOR HILLS
        -- We shift the target speed directly by the gravity slope.
        -- Uphill (gravity > 0): The target speed sags down, forcing the train to slow down.
        -- Downhill (gravity < 0): The target speed shifts up, allowing the speed to raise.
        local liveCoastTarget = coastTargetSpeed - (gravityForceFactor * 4.0)

        -- Gentle maintenance loop to overcome basic flat-ground rolling drag
        local speedError = liveCoastTarget - absSpeed
        
        -- Very low gain loop so the engine smoothly and loosely holds speed
        tuneThrottle = clamp(tuneThrottle + (speedError * 0.004), 0.0, 0.35)
        
        throttleOut = tuneThrottle
        brakeFricOut = 0.0  -- No physical mechanical drag brakes applied while coasting
        brakeRegenOut = 0.0
        tuneBrake = 0.0
    else
        -- Break out of speed-set memory if driver uses power or brakes
        wasCoasting = false
        
        if rawThrottleDemand > 0 then
            -- Active Power Autotune Loop
            local targetAccel = rawThrottleDemand * liveMaxAccel
            local error = targetAccel - currentPerformance
            tuneThrottle = clamp(tuneThrottle + (error * tuneRate), 0.0, 1.0)
            tuneBrake = 0.0
    
            throttleOut = tuneThrottle
        elseif finalBrakeDemand > 0 then
            -- Active Service Brake Autotune Loop
            local targetDecel = finalBrakeDemand * liveMaxDecel
            local error = targetDecel - currentPerformance
            tuneBrake = clamp(tuneBrake + (error * tuneRate), 0.0, 1.0)
            tuneThrottle = 0.0
    
            -- Map physical handle splits directly to actuator lines
            brakeFricOut = handleFric * tuneBrake
            brakeRegenOut = handleRegen * tuneBrake
        end
    end

    -- Hard overspeed structural safety clamp
    if absSpeed >= MAX_SPEED_MS then
        throttleOut = 0.0
    end

    -- Actuator Outputs
    sn(1, clamp(throttleOut, 0, 1))
    sn(2, clamp(brakeFricOut, 0, 1))
    sn(3, clamp(brakeRegenOut, 0, 1))

    -- Simple indicator line to map back to dashboard setups
    sb(1, coast)

    lastSpeed = speed
end
