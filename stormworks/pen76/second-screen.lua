-- EN76 secondary panel - 64x64
-- full regenerated version
--
-- NUMBER INPUTS
-- 1 = Reverser (-1..1)
-- 2 = Destination Index (0..17)
-- 3 = Combined Controller Notch (1..6)
--     1=increase power
--     2=maintain power / decrease brake
--     3=hold brake / decrease power
--     4=increase brake
--     5=full braking
--     6=emergency
-- 4 = Local Brake Notch (1..5)
-- 5 = Headlight Mode (0..4)
--     0=off 1=tail 2=day 3=night 4=high
-- 6 = Regen Brake (0..1)
-- 7 = Friction Brake (0..1)
--
-- BOOL INPUTS
-- 1 = Emergency Brake Active
-- 2 = Passenger Lights
-- 3 = Front Coupled
-- 4 = Rear Coupled
-- 5 = Night Mode

local gn, gb = input.getNumber, input.getBool

local rev, dest, ctrlNotch, lbrake, lights = 0, 0, 3, 1, 0
local regen, fric = 0, 0
local eb, pax, cplF, cplR, nightMode = false, false, false, false, false

local function clamp(x,a,b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function C3(c)
    screen.setColor(c[1], c[2], c[3])
end

local function rect(x,y,w,h) screen.drawRect(x,y,w,h) end
local function rectF(x,y,w,h) screen.drawRectF(x,y,w,h) end
local function line(x1,y1,x2,y2) screen.drawLine(x1,y1,x2,y2) end
local function txt(x,y,t) screen.drawText(x,y,t) end

-- matched to your main screen palette
local BG_DAY   ={18,36,64}
local BG_NGT   ={6,12,22}
local FG_DAY   ={255,255,255}
local FG_NGT   ={230,240,255}
local DIM_D    ={170,190,220}
local DIM_N    ={120,150,190}
local FACE_D   ={28,50,85}
local FACE_N   ={10,14,20}
local EDGE_D   ={90,130,180}
local EDGE_N   ={28,38,54}
local BLUE_D   ={120,200,255}
local BLUE_N   ={75,135,220}
local GREEN_D  ={120,255,160}
local GREEN_N  ={70,180,95}
local AMBER_D  ={255,200,90}
local AMBER_N  ={220,155,60}
local RED_D    ={255,80,80}
local RED_N    ={220,70,70}
local CYAN_D   ={150,240,255}
local CYAN_N   ={85,180,220}
local PURPLE_D ={210,150,255}
local PURPLE_N ={140,110,200}

local function pal()
    if nightMode then
        return BG_NGT,FG_NGT,DIM_N,FACE_N,EDGE_N,BLUE_N,GREEN_N,AMBER_N,RED_N,CYAN_N,PURPLE_N
    else
        return BG_DAY,FG_DAY,DIM_D,FACE_D,EDGE_D,BLUE_D,GREEN_D,AMBER_D,RED_D,CYAN_D,PURPLE_D
    end
end

function onTick()
    rev       = gn(1)
    dest      = gn(2)
    ctrlNotch = clamp(math.floor(gn(3) + 0.5), 1, 6)
    lbrake    = clamp(math.floor(gn(4) + 0.5), 1, 5)
    lights    = clamp(math.floor(gn(5) + 0.5), 0, 4)
    regen     = clamp(gn(6), 0, 1)
    fric      = clamp(gn(7), 0, 1)

    eb        = gb(1)
    pax       = gb(2)
    cplF      = gb(3)
    cplR      = gb(4)
    nightMode = gb(5)
end

local function drawSoft(x,y,filled,FG,DIM)
    C3(FG)
    rect(x,y,5,5)
    if filled then
        C3(DIM)
        rectF(x+1,y+1,3,3)
    end
end

local function drawModeRow(x,y,active,FG,BLUE)
    for i=0,4 do
        local bx = x + i*6
        C3(FG)
        rect(bx,y,5,5)
        if i == active then
            C3(BLUE)
            rectF(bx+1,y+1,3,3)
        end
    end
end

local function drawTriBox(x,y,active,FG,RED)
    C3(FG)
    rect(x,y,7,5)
    if active then
        C3(RED)
        screen.drawTriangle(x+3,y+1,x+1,y+4,x+5,y+4)
        rectF(x+2,y+2,3,2)
    else
        C3(FG)
        screen.drawTriangle(x+3,y+1,x+1,y+4,x+5,y+4)
    end
end

local function drawCtrlBar(x,y,h,notch,FG,FACE,EDGE,BLUE,AMBER,RED)
    C3(FG)
    rect(x,y,5,h)
    C3(FACE)
    rectF(x+1,y+1,3,h-1)

    C3(EDGE)
    local mid = y + math.floor(h/2)
    line(x+6,y+2,x+8,y+2)
    line(x+6,y+5,x+8,y+5)
    line(x+6,mid,x+8,mid)
    line(x+6,y+h-6,x+8,y+h-6)
    line(x+6,y+h-3,x+8,y+h-3)

    C3(FG)
    line(x+1,mid,x+3,mid)

    if notch == 1 then
        C3(BLUE)
        rectF(x+1, y+2, 3, math.max(1, mid-y-1))
    elseif notch == 2 then
        C3(BLUE)
        rectF(x+1, y+5, 3, math.max(1, mid-y-4))
    elseif notch == 3 then
        C3(FG)
        rectF(x+1, mid, 3, 1)
    elseif notch == 4 then
        C3(AMBER)
        rectF(x+1, mid, 3, math.max(1, y+h-mid-4))
    elseif notch == 5 then
        C3(AMBER)
        rectF(x+1, mid, 3, math.max(1, y+h-mid-1))
    elseif notch == 6 then
        C3(RED)
        rectF(x+1, y+1, 3, h-1)
    end
end

local function drawLocalBrakeBar(x,y,h,val,maxv,FG,FACE,EDGE,AMBER)
    C3(FG)
    rect(x,y,5,h)
    C3(FACE)
    rectF(x+1,y+1,3,h-1)

    C3(EDGE)
    line(x+6,y+2,x+8,y+2)
    line(x+6,y+5,x+8,y+5)
    line(x+6,y+8,x+8,y+8)
    line(x+6,y+11,x+8,y+11)
    line(x+6,y+14,x+8,y+14)

    local frac = clamp(val/maxv,0,1)
    local fh = math.max(1, math.floor((h-2)*frac + 0.5))
    C3(AMBER)
    rectF(x+1, y+h-fh, 3, fh)
end

local function drawAnalogBar(x,y,h,val,FG,FACE,EDGE,col)
    C3(FG)
    rect(x,y,5,h)
    C3(FACE)
    rectF(x+1,y+1,3,h-1)

    C3(EDGE)
    line(x+6,y+2,x+8,y+2)
    line(x+6,y+5,x+8,y+5)
    line(x+6,y+8,x+8,y+8)
    line(x+6,y+11,x+8,y+11)
    line(x+6,y+14,x+8,y+14)

    local fh = math.max(1, math.floor((h-2)*clamp(val,0,1) + 0.5))
    C3(col)
    rectF(x+1, y+h-fh, 3, fh)
end

local function drawCapsule(x,y,w,h,FG)
    local r = math.floor(h/2)
    C3(FG)
    line(x+r,y,x+w-r,y)
    line(x+r,y+h,x+w-r,y+h)
    line(x,y+r,x,y+h-r)
    line(x+w,y+r,x+w,y+h-r)
    screen.drawCircle(x+r,y+r,r)
    screen.drawCircle(x+w-r,y+r,r)
end

local function drawCar(x,y,leftOn,midOn,rightOn,fault,FG,BLUE,RED)
    local w,h = 14,6
    drawCapsule(x,y,w,h,FG)
    C3(FG)
    line(x+4,y+1,x+4,y+5)
    line(x+9,y+1,x+9,y+5)

    C3(leftOn and BLUE or RED)
    screen.drawCircleF(x+2,y+3,1)

    C3(midOn and BLUE or RED)
    screen.drawCircleF(x+7,y+3,1)

    C3(rightOn and BLUE or RED)
    screen.drawCircleF(x+12,y+3,1)

    if fault then
        C3(RED)
        screen.drawCircleF(x+3,y+2,1)
    end
end

local function drawNeutral(x,y,active,FG,BLUE)
    C3(FG)
    rect(x,y,5,5)
    C3(active and BLUE or FG)
    line(x+1,y+2,x+3,y+2)
end

local function drawUp(x,y,active,FG,BLUE)
    C3(FG)
    rect(x,y,5,5)
    C3(active and BLUE or FG)
    line(x+2,y+1,x+2,y+3)
    line(x+2,y+1,x+1,y+2)
    line(x+2,y+1,x+3,y+2)
end

local function drawDown(x,y,active,FG,BLUE)
    C3(FG)
    rect(x,y,5,5)
    C3(active and BLUE or FG)
    line(x+2,y+1,x+2,y+3)
    line(x+2,y+3,x+1,y+2)
    line(x+2,y+3,x+3,y+2)
end

local function destShort(i)
    local d = {
        "OOS","BVG","CAM","CLK","DOR","FJW","KAL","MSB","MAL",
        "NHB","ONC","PAC","END","SPY","TRI","UWF","XFY","TST"
    }
    i = clamp(math.floor(i+0.5),0,17)
    return d[i+1] or "UNK"
end

function onDraw()
    local BG,FG,DIM,FACE,EDGE,BLUE,GREEN,AMBER,RED,CYAN,PURPLE = pal()

    C3(BG)
    screen.drawClear()

    C3(EDGE)
    rect(1,1,61,61)

    -- top softkeys
    for i=0,7 do
        drawSoft(3 + i*7, 3, false, FG, DIM)
    end

    -- second row
    drawModeRow(10, 11, lights, FG, BLUE)
    drawTriBox(42, 11, eb, FG, RED)

    -- four central bars
    drawCtrlBar(8, 20, 16, ctrlNotch, FG, FACE, EDGE, BLUE, AMBER, RED)
    drawLocalBrakeBar(17,20,16, lbrake, 5, FG, FACE, EDGE, AMBER)
    drawAnalogBar(26,20,16, regen, FG, FACE, EDGE, GREEN)
    drawAnalogBar(35,20,16, fric,  FG, FACE, EDGE, RED)

    -- right stack
    drawNeutral(51,20, lights > 0, FG, BLUE)
    drawUp(51,27, rev > 0.1, FG, BLUE)
    drawDown(51,34, rev < -0.1, FG, BLUE)

    C3(FG)
    rect(51,41,5,9)
    if pax then
        C3(AMBER)
        rectF(52,42,3,2)
    end
    if eb then
        C3(RED)
        rectF(52,46,3,2)
    end

    -- consist row
    drawCar(5, 40, cplF, true, true, false, FG, BLUE, RED)
    drawCar(21,40, true, pax, true, false, FG, BLUE, RED)
    drawCar(37,40, true, true, cplR, eb, FG, BLUE, RED)

    -- lower furniture blocks
    C3(DIM)
    rectF(4, 49, 10, 6)

    C3(RED)
    rectF(15,50,2,4)

    C3(FACE)
    rectF(18,49,10,6)

    C3(AMBER)
    rectF(29,49,8,6)

    C3(CYAN)
    rectF(38,49,8,6)

    C3(PURPLE)
    rectF(47,49,11,7)

    -- bottom softkeys
    for i=0,6 do
        drawSoft(3 + i*8, 57, i == 6, FG, DIM)
    end

    -- destination code
    C3(FG)
    txt(43, 57, destShort(dest))
end
