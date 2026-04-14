stations = {
    [0]  = "OUT OF SERVICE",
    [1]  = "BVG STATION",
    [2]  = "CAMODO ISLAND",
    [3]  = "CLARKE AIRFIELD",
    [4]  = "DAYLIGHT OIL REFINERY",
    [5]  = "FJ WARNER DEPOT",
    [6]  = "KALOPSIDIOTIS",
    [7]  = "MAGNUS SHIP BREAKING",
    [8]  = "MALLAMAR FACILITY",
    [9]  = "NORTH HARBOR",
    [10] = "O'NEIL CENTRAL",
    [11] = "PACKARD STATION",
    [12] = "TERMINAL ENDO",
    [13] = "TERMINAL SPYCAKES",
    [14] = "TERMINAL TRINITE",
    [15] = "URAN WIND FACILITY",
    [16] = "XFURY STATION",
    [17] = "TEST TRAIN"
}

-- =========================
-- Custom font setup
-- =========================
s=string
M=math
si=M.sin
co=M.cos
at=M.atan
ab=M.abs
pi=M.pi
pi2=pi*2
pih=pi/2
S=screen
dTF=S.drawTriangleF
tU=table.unpack

function dRC(a,b,c,d,e,f,g,h)
    dTF(a,b,c,d,e,f)
    dTF(e,f,g,h,c,d)
end

chr = {
    A={{0,0,2,1,2,0,"",1,3},{9,-1,-8,0,8,1,"",5,0}},
    B={{0,4,0,-2,2,0,-4,0},{0,0,2,2,2,3,0,-9}},
    C={{4,-2,-2,0,2,2},{0,0,2,5,2,0}},
    D={{0,3,2,0,-2,-3,0},{0,0,2,5,2,0,-9}},
    E={{4,-4,0,4,"",0,3},{0,0,9,0,"",4,0}},
    F={{4,-4,0,"",0,3},{0,0,9,"",4,0}},
    G={{5,-3,-2,0,2,3,0,-2},{0,0,2,5,2,0,-4,0}},
    H={{0,0,"",0,5,"",5,0},{0,9,"",4,0,"",0,9}},
    I={{0,0},{0,9}},
    J={{2,0,-2,0},{0,9,0,-2}},
    K={{0,0,"",5,-4,4,0},{0,9,"",0,4,4,1}},
    L={{0,0,4},{0,9,0}},
    M={{0,0,1,2,2,1,0},{9,-9,0,5,-5,0,9}},
    N={{0,0,1,2,1,0},{9,-9,0,9,0,-9}},
    O={{0,5,0,-5,0},{0,0,9,0,-9}},
    P={{0,0,4,0,-3},{9,-9,0,4,0}},
    Q={{3,-3,0,4,0,1},{9,0,-9,0,8,1}},
    R={{0,0,4,0,-3,3,0},{9,-9,0,4,0,4,1}},
    S={{4,0,-4,0,4,0,-4,0},{2,-2,0,4,0,5,0,-2}},
    T={{0,5,"",2,0},{0,0,"",0,9}},
    U={{0,0,4,0},{0,9,0,-9}},
    V={{0,0,2,2,0},{0,6,3,-3,-6}},
    W={{0,0,1,2,2,1,0},{0,5,3,-4,4,-3,-5}},
    X={{0,0,4,0,"",0,0,4,0},{0,2,5,2,"",9,-2,-5,-2}},
    Y={{0,0,2.5,"",5,0,-5},{0,3,3,"",0,3,6}},
    Z={{0,5,0,-5,0,6},{0,0,2,5,2,0}},
    [1]={{0,2,0},{2,-2,9}},
    [2]={{0,0,4,0,-4,5},{2,-2,0,2,7,0}},
    [3]={{0,0,4,0,-1,1,0,-4,0},{2,-2,0,3,1,1,4,0,-2}},
    [4]={{2,-2,5,"",3,0},{0,5,0,"",3,6}},
    [5]={{4,-3,-1,4,0,-4,0},{0,0,4,0,5,0,-2}},
    [6]={{0,4,0,-4,0,2},{5,0,4,0,-5,-4}},
    [7]={{0,4,-3},{0,0,9}},
    [8]={{0,0,3,0,-4,0,4,0},{4,-4,0,4,0,5,0,-5}},
    [9]={{4,-4,0,4,0,-3},{4,0,-4,0,4,5}},
    [0]={{3,-3,0,4,0},{0,0,9,0,-8}},
    ["!"]={{0,0,"",0,0},{0,6,"",8,1}},
    ["?"]={{0,0,3,0,-2,0,"",1,0},{2,-2,0,2,3,1,"",8,1}},
    ["+"]={{0,3.5,"",1.5,0},{4,0,"",2,4}},
    ["-"]={{0,3.5},{4,0}},
    [":"]={{0,0,"",0,0},{2,1,"",5,1}},
    ["_"]={{0,4},{9,0}},
    ["."]={{0,0},{8.5,1}},
    [","]={{0,1},{10,-2}},
    ["'"]={{0,0},{0,2}}
}

chrd = {}
chrd[s.byte(" ")] = {w = 5}
W = 0.65

for i, tbl in pairs(chr) do
    local tx = tbl[1]
    local ty = tbl[2]
    local asc = s.byte(i)
    chrd[asc] = {}
    chrd[asc].t = {}
    local mx = 0
    local x, y = 0, 0
    local skip = false
    for z = 1, #tx do
        if tx[z] == "" then
            skip = true
            x, y = 0, 0
            chrd[asc].t[z] = false
        else
            x, y = x + tx[z], y + ty[z]
            local a1 = (z == 1 or skip) and at(ty[z+1], tx[z+1]) or at(ty[z], tx[z])
            local a2 = (z == #tx or tx[z+1] == "") and a1 or at(ty[z+1], tx[z+1])
            local a0 = (a1 + a2) / 2
            local d = a0 - a1
            d = d < 0 and d or pi2 - d
            local w = W / M.max(si(d), co(d))
            local j,k,l,m = x + w*co(a0-pih), y + w*si(a0-pih), x + w*co(a0+pih), y + w*si(a0+pih)
            if ab(j) < W/2 then j,l = -W,-W end
            if ab(k) < W/2 then k,m = -W,-W end
            if ab(k-9) < W/4 then k,m = 9+W,9+W end
            chrd[asc].t[z] = {j,k,l,m}
            mx = M.max(mx, j, l)
            skip = false
        end
    end
    chrd[asc].w = mx
end

function TXT(txt, xx, yy, ww, hh)
    txt = s.upper(txt)
    local lw, tw, ss, th = 0, 0, 0, 9
    for pass = 1, 2 do
        if pass > 1 then
            tw = lw - 2 + W
            ss = M.min(hh / th, ww / tw)
        end
        lw = 0
        for i = 1, #txt do
            local c = chrd[s.byte(s.sub(txt, i, i))] or chrd[s.byte(" ")]
            local w, t = c.w, c.t
            if pass > 1 and t ~= nil then
                for a, b in pairs(t) do
                    if a > 1 and t[a-1] and t[a] then
                        local x = xx + ss * (lw + W)
                        local y = yy + (hh - ss * th) / 2
                        local j,k,l,m = tU(t[a-1])
                        local n,o,p,q = tU(t[a])
                        dRC(x+ss*j, y+ss*k, x+ss*l, y+ss*m, x+ss*n, y+ss*o, x+ss*p, y+ss*q)
                    end
                end
            end
            lw = lw + w + 2
        end
    end
end

-- =========================
-- State
-- =========================
runningNumber = 0
speedMS = 0
mapX = 0
mapY = 0
destIndex = 0
headingTurns = 0
displayOn = true

pageTimer = 0
testPage = 1

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function pad5(n)
    n = math.max(0, math.floor(n or 0))
    if n < 10 then
        return "0000" .. n
    elseif n < 100 then
        return "000" .. n
    elseif n < 1000 then
        return "00" .. n
    elseif n < 10000 then
        return "0" .. n
    end
    return tostring(n)
end

function kmh(ms)
    return math.floor((ms or 0) * 3.6 + 0.5)
end

function textWidth(str)
    return string.len(str or "") * 4
end

function drawPill(x, y, w, h, br, bg, bb, tr, tg, tb, text)
    local r = math.floor(h / 2)

    screen.setColor(br, bg, bb)
    if w > h then
        screen.drawRectF(x + r, y, w - h, h)
    end
    screen.drawCircleF(x + r, y + r, r)
    screen.drawCircleF(x + w - r, y + r, r)

    screen.setColor(tr, tg, tb)
    local tw = textWidth(text)
    local tx = x + math.floor((w - tw) / 2)
    local ty = y + math.floor((h - 5) / 2)
    screen.drawText(tx, ty, text)
end

function drawTrainArrow(cx, cy, size, turns)
    -- Stormworks compass-style turns: 0..1
    -- 0 = up, 0.25 = right, 0.5 = down, 0.75 = left
    local a = turns * pi2 - pih

    local tipX = cx + co(a) * size
    local tipY = cy + si(a) * size

    local leftA = a + 2.45
    local rightA = a - 2.45
    local back = size * 0.9

    local leftX = cx + co(leftA) * back
    local leftY = cy + si(leftA) * back
    local rightX = cx + co(rightA) * back
    local rightY = cy + si(rightA) * back

    screen.drawTriangleF(tipX, tipY, leftX, leftY, rightX, rightY)
end

function onTick()
    runningNumber = math.floor(input.getNumber(1) or 0)
    speedMS       = input.getNumber(2) or 0
    mapX          = input.getNumber(3) or 0
    mapY          = input.getNumber(4) or 0
    destIndex     = math.floor(input.getNumber(5) or 0)
    headingTurns  = input.getNumber(6) or 0

    displayOn     = input.getBool(1)

    if stations[destIndex] == nil then
        destIndex = 0
    end

    pageTimer = pageTimer + 1
    if pageTimer >= 120 then
        pageTimer = 0
        testPage = testPage + 1
        if testPage > 3 then
            testPage = 1
        end
    end
end

function onDraw()
    local w = screen.getWidth()
    local h = screen.getHeight()

    screen.setColor(0, 0, 0)
    screen.drawClear()

    if not displayOn then
        return
    end

    -- TEST TRAIN warning pages
    if destIndex == 17 then
        local msg = "DO NOT BOARD"
        if testPage == 2 then
            msg = "THIS IS A TEST TRAIN"
        elseif testPage == 3 then
            msg = "LEAVE IMMEDIATELY"
        end

        screen.setColor(140, 0, 0)
        screen.drawClear()

        screen.setColor(255, 255, 255)
        screen.drawRect(1, 1, w - 3, h - 3)

        TXT(msg, 4, 4, w - 8, h - 8)
        return
    end

    local topBarH = 16
    local bottomBarH = 14
    local mapTop = topBarH
    local mapHeight = h - topBarH - bottomBarH

    -- map
    screen.setMapColorOcean(20, 30, 50, 255)
    screen.setMapColorShallows(30, 45, 70, 255)
    screen.setMapColorLand(45, 45, 45, 255)
    screen.setMapColorGrass(50, 60, 45, 255)
    screen.setMapColorSand(70, 65, 45, 255)
    screen.setMapColorSnow(220, 220, 220, 255)
    screen.setMapColorRock(80, 80, 80, 255)
    screen.setMapColorGravel(65, 65, 65, 255)
    screen.drawMap(mapX, mapY, 3)

    -- overlay bands
    screen.setColor(10, 10, 10, 220)
    screen.drawRectF(0, 0, w, topBarH)
    screen.drawRectF(0, h - bottomBarH, w, bottomBarH)

    screen.setColor(60, 60, 60)
    screen.drawLine(0, topBarH, w - 1, topBarH)
    screen.drawLine(0, h - bottomBarH - 1, w - 1, h - bottomBarH - 1)

    -- center train arrow
    local cx = math.floor(w / 2)
    local cy = math.floor(mapTop + mapHeight / 2)
    screen.setColor(255, 255, 255)
    drawTrainArrow(cx, cy, 5, headingTurns)

    -- top pills
    local runText = pad5(runningNumber)
    local speedText = tostring(kmh(speedMS)) .. " KM/H"

    local runW = math.max(36, textWidth(runText) + 10)
    local speedW = math.max(42, textWidth(speedText) + 10)

    local pillY = 2
    local pillH = 11

    drawPill(2, pillY, runW, pillH, 35, 35, 35, 255, 255, 255, runText)
    drawPill(w - speedW - 2, pillY, speedW, pillH, 35, 35, 35, 255, 255, 255, speedText)

    -- bottom destination/status
    screen.setColor(255, 255, 255)
    screen.drawTextBox(2, h - bottomBarH + 1, w - 4, bottomBarH - 2, stations[destIndex], 0, 0)
end
