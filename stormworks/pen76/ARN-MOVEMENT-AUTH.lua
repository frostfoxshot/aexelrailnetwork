-- AEX ARN Monitor v1.1
-- GPS zone / speed authority monitor
-- Fixes passed-zone brake intervention

local gn, gb = input.getNumber, input.getBool
local sn, sb = output.setNumber, output.setBool

-- SETTINGS
local DEFAULT_LIMIT = 400
local APPROACH_DIST = 1500
local OVERSPEED_MARGIN = 2
local INTERVENE_MARGIN = 8
local SERVICE_DECEL = 0.75

-- ZONES
local zones = {
    {
        x1 = -17010, y1 = -1803,
        x2 = -18647, y2 = -2370,
        limit = 160,
        tol = 700
    },
    {
        x1 = -12833, y1 = -2982,
        x2 = -13158, y2 = -2701,
        limit = 90,
        tol = 300
    }
}

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function zoneInfo(px, py, z, reverse)
    local dx = z.x2 - z.x1
    local dy = z.y2 - z.y1
    local L = math.sqrt(dx*dx + dy*dy)

    if L < 0.001 then
        return false, false, false, 999999, 0, 0, L
    end

    local ux = dx / L
    local uy = dy / L

    local vx = px - z.x1
    local vy = py - z.y1

    local along = vx * ux + vy * uy
    local perp = math.abs(vx * uy - vy * ux)

    local inside = perp <= z.tol and along >= 0 and along <= L

    local ahead = false
    local distToZone = 999999
    local distToEnd = 0
    local distToStart = 0

    if not reverse then
        -- Travelling from x1/y1 toward x2/y2
        if along < 0 then
            ahead = true
            distToZone = -along
        elseif inside then
            ahead = true
            distToZone = 0
        else
            ahead = false
        end

        distToEnd = math.max(L - along, 0)
        distToStart = math.max(along, 0)
    else
        -- Travelling from x2/y2 toward x1/y1
        if along > L then
            ahead = true
            distToZone = along - L
        elseif inside then
            ahead = true
            distToZone = 0
        else
            ahead = false
        end

        distToEnd = math.max(L - along, 0)
        distToStart = math.max(along, 0)
    end

    local nearTrack = perp <= z.tol
    return nearTrack, inside, ahead, distToZone, distToEnd, distToStart, L
end

local function brakingCurveNeedsIntervention(curKmh, tgtKmh, distM)
    if tgtKmh <= 0 or distM <= 0 then
        return false
    end

    local v = math.max(curKmh, 0) / 3.6
    local u = math.max(tgtKmh, 0) / 3.6

    local need = ((v*v) - (u*u)) / (2 * SERVICE_DECEL)
    if need < 0 then need = 0 end

    return need >= distM
end

function onTick()
    local gpsX = gn(1)
    local gpsY = gn(2)
    local spd  = gn(3)
    local brk  = gn(4)
    local trac = gn(5)
    local regen = gn(6)

    local master = gb(1)
    local doors  = gb(2)
    local rev    = gb(3)

    local currentLimit = DEFAULT_LIMIT
    local targetSpeed = 0
    local distToTarget = 0
    local authRemaining = 0

    local arnActive = master
    local overspeed = false
    local intervene = false

    local bestZone = nil
    local bestInside = false
    local bestDist = 999999
    local bestDistToEnd = 0
    local bestDistToStart = 0

    for i = 1, #zones do
        local z = zones[i]
        local nearTrack, inside, ahead, distToZone, distToEnd, distToStart, L =
            zoneInfo(gpsX, gpsY, z, rev)

        if nearTrack and ahead then
            if inside then
                bestZone = z
                bestInside = true
                bestDist = 0
                bestDistToEnd = distToEnd
                bestDistToStart = distToStart
                break
            elseif distToZone < bestDist then
                bestZone = z
                bestInside = false
                bestDist = distToZone
                bestDistToEnd = distToEnd
                bestDistToStart = distToStart
            end
        end
    end

    if bestZone then
        if bestInside then
            currentLimit = bestZone.limit
            targetSpeed = 0
            distToTarget = 0

            if rev then
                authRemaining = bestDistToStart
            else
                authRemaining = bestDistToEnd
            end

        elseif bestDist <= APPROACH_DIST then
            currentLimit = DEFAULT_LIMIT
            targetSpeed = bestZone.limit
            distToTarget = bestDist
            authRemaining = bestDist
        end
    end

    if arnActive then
        overspeed = spd > currentLimit + OVERSPEED_MARGIN

        if spd > currentLimit + INTERVENE_MARGIN then
            intervene = true
        end

        if targetSpeed > 0 and brakingCurveNeedsIntervention(spd, targetSpeed, distToTarget) then
            intervene = true
        end
    end

    -- NUM OUTPUTS
    sn(1, spd)
    sn(2, brk)
    sn(3, trac)
    sn(4, regen)
    sn(5, currentLimit)
    sn(6, targetSpeed)
    sn(7, distToTarget)
    sn(8, authRemaining)

    -- BOOL OUTPUTS
    sb(1, arnActive)
    sb(2, overspeed)
    sb(3, intervene)
    sb(4, doors)
    sb(5, master)
    sb(6, rev)
end
