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

    local finalBrakeDemand = math.max(handleFric, handleRegen)
    local rawThrottleDemand = handlePower

    ------------------------------------------------------------------------
    -- DYNAMIC INCLINE VECTORING & TURN FILTERING
    ------------------------------------------------------------------------
    local radTilt = math.rad(tiltDeg)
    local gravityForceFactor = math.sin(radTilt)

    -- Centripetal Noise Filter: If the train is changing speed smoothly but tilt spikes,
    -- damp the gravity factor so turns don't fool the incline scaling.
    if math.abs(currentAccel) < 0.2 and math.abs(gravityForceFactor) > 0.1 then
        gravityForceFactor = gravityForceFactor * 0.3
    end

    -- Scale target acceleration windows based on slope angles
    local liveMaxAccel = clamp(TARGET_ACCEL_MAX - (gravityForceFactor * 1.5), TARGET_ACCEL_MIN, 1.5)
    local liveMaxDecel = clamp(TARGET_DECEL_MAX + (gravityForceFactor * 1.2), TARGET_DECEL_MIN, 1.4)

    local tuneRate = 0.012 -- Slightly increased for faster response in turns

    local throttleOut = 0.0
    local brakeFricOut = 0.0
    local brakeRegenOut = 0.0

    -- Check if operator is completely off the handles
    local coast = rawThrottleDemand < 0.01 and finalBrakeDemand < 0.01

    if coast then
        if not wasCoasting then
            coastTargetSpeed = absSpeed
            wasCoasting = true
        end

        -- Dynamic coast targets for hills
        local liveCoastTarget = coastTargetSpeed - (gravityForceFactor * 4.0)
        local speedError = liveCoastTarget - absSpeed
        
        -- Speed-holding logic
        if speedError > 0 then
            -- Train is below target speed: Apply gentle throttle to maintain
            tuneThrottle = clamp(tuneThrottle + (speedError * 0.005), 0.0, 0.40)
            throttleOut = tuneThrottle
        else
            -- Train is over target speed (rolling downhill): Let gravity roll it out
            tuneThrottle = clamp(tuneThrottle - 0.01, 0.0, 0.40)
            throttleOut = tuneThrottle
        end
        
        brakeFricOut = 0.0
        brakeRegenOut = 0.0
        tuneBrake = 0.0
    else
        wasCoasting = false
        
        if rawThrottleDemand > 0 then
            -- Active Power Autotune Loop (FIXED: Uses raw currentAccel)
            local targetAccel = rawThrottleDemand * liveMaxAccel
            local error = targetAccel - currentAccel
            
            tuneThrottle = clamp(tuneThrottle + (error * tuneRate), 0.0, 1.0)
            tuneBrake = 0.0
    
            throttleOut = tuneThrottle
        elseif finalBrakeDemand > 0 then
            -- Active Service Brake Autotune Loop (FIXED: Converts deceleration to positive value)
            local targetDecel = finalBrakeDemand * liveMaxDecel
            local measuredDecel = -currentAccel
            local error = targetDecel - measuredDecel
            
            tuneBrake = clamp(tuneBrake + (error * tuneRate), 0.0, 1.0)
            tuneThrottle = 0.0
    
            brakeFricOut = handleFric * tuneBrake
            brakeRegenOut = handleRegen * tuneBrake
        end
    end

    -- Hard overspeed safety clamp
    if absSpeed >= MAX_SPEED_MS then
        throttleOut = 0.0
    end

    -- Actuator Outputs
    sn(1, clamp(throttleOut, 0, 1))
    sn(2, clamp(brakeFricOut, 0, 1))
    sn(3, clamp(brakeRegenOut, 0, 1))

    sb(1, coast)

    lastSpeed = speed
end
