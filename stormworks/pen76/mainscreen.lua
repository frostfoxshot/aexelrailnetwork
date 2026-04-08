-- AEX EN76 Style Centre Screen v2.0 (3x2, ARN braking curve overlay)
--
-- INPUT MAP
-- Bool 1: Touch 1 pressed
-- Bool 2: Touch 2 pressed
-- Bool 3: ARN active
-- Bool 4: Overspeed warning
-- Bool 5: Brake intervention
-- Bool 6: Door interlock / doors closed
-- Bool 7: Master on
-- Bool 8: Reverse bool (false=fwd, true=rev)
--
-- Number 1: Screen width passthrough (optional)
-- Number 2: Screen height passthrough (optional)
-- Number 3: Touch 1 X
-- Number 4: Touch 1 Y
-- Number 5: Touch 2 X
-- Number 6: Touch 2 Y
-- Number 7: Current speed km/h
-- Number 8: Friction brake %
-- Number 9: Traction %
-- Number 10: Regen brake %
-- Number 11: Current limit km/h
-- Number 12: Target speed km/h
-- Number 13: Distance to target m
-- Number 14: Authority remaining m

local W,H=96,64
local p1,p2=false,false
local t1x,t1y,t2x,t2y=0,0,0,0
local p1p,p2p=false,false

local spd=0
local brk=0
local trac=0
local regen=0
local limit=160
local target=0
local distT=0
local authRem=0

local arn=false
local overspeed=false
local intervene=false
local doors=true
local master=false
local rev=false

local M_NIGHT=false
local M_MPH=false

local BTN={}

-- ARN braking curve tuning
local SERVICE_DECEL = 0.75 -- m/s^2
local WARN_MARGIN_M = 35   -- start showing more urgent warning when close
local CURVE_MAX_KMH = 160

local function clamp(x,a,b)
    if x<a then return a elseif x>b then return b else return x end
end

local function lerp(a,b,t)
    return a+(b-a)*t
end

local function C3(c)
    screen.setColor(c[1],c[2],c[3])
end

local function rect(x,y,w,h,f)
    if f then screen.drawRectF(x,y,w,h) else screen.drawRect(x,y,w,h) end
end

local function hit(x,y,w,h,px,py)
    return px>=x and px<=x+w and py>=y and py<=y+h
end

local function panel(x,y,w,h,FACE,EDGE)
    C3(FACE)
    rect(x,y,w,h,true)
    C3(EDGE)
    rect(x,y,w,h,false)
end

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
    if M_NIGHT then
        return BG_NGT,FG_NGT,DIM_N,FACE_N,EDGE_N,BLUE_N,GREEN_N,AMBER_N,RED_N,CYAN_N,PURPLE_N
    else
        return BG_DAY,FG_DAY,DIM_D,FACE_D,EDGE_D,BLUE_D,GREEN_D,AMBER_D,RED_D,CYAN_D,PURPLE_D
    end
end

local function drawArc(cx,cy,r,a1,a2,col,steps)
    C3(col)
    local px,py=nil,nil
    for i=0,steps do
        local t=i/steps
        local a=lerp(a1,a2,t)
        local x=cx+math.cos(a)*r
        local y=cy+math.sin(a)*r
        if px then screen.drawLine(px,py,x,y) end
        px,py=x,y
    end
end

local function drawRingSegment(cx,cy,r1,r2,a1,a2,col,steps)
    if a2 < a1 then
        local tmp=a1
        a1=a2
        a2=tmp
    end
    for rr=r1,r2 do
        drawArc(cx,cy,rr,a1,a2,col,steps)
    end
end

local function speedAngle(v,maxV)
    local n=clamp(v/maxV,0,1)
    return math.rad(140 + n*260)
end

local function drawMarker(cx,cy,r,a,col,len)
    C3(col)
    local x1=cx+math.cos(a)*(r-len)
    local y1=cy+math.sin(a)*(r-len)
    local x2=cx+math.cos(a)*r
    local y2=cy+math.sin(a)*r
    screen.drawLine(x1,y1,x2,y2)
end

local function brakingCurveInfo(curKmh,tgtKmh,distM)
    if distM <= 0 or tgtKmh <= 0 and curKmh <= 0 then
        return 0, false, false
    end

    local v = math.max(curKmh,0) / 3.6
    local u = math.max(tgtKmh,0) / 3.6
    local d = math.max(distM,0.1)

    local need = ((v*v) - (u*u)) / (2 * SERVICE_DECEL)
    if need < 0 then need = 0 end

    local ratio = need / d
    local onCurve = ratio >= 0.75
    local urgent = ratio >= 1.0 or distM <= WARN_MARGIN_M

    return ratio, onCurve, urgent
end

local function drawDial(cx,cy,r,spdV,maxV,limitV,targetV,tracPct,brkPct,regenPct,distM,FG,DIM,BLUE,GREEN,AMBER,RED,CYAN,PURPLE)
    screen.setColor(8,10,14)
    screen.drawCircleF(cx,cy,r+2)
    screen.setColor(18,24,34)
    screen.drawCircleF(cx,cy,r)

    local safeTo=clamp(limitV/maxV,0,1)
    local safeA=math.rad(140)
    local warnA=math.rad(140 + safeTo*260)

    -- outer line speed ring
    drawRingSegment(cx,cy,r-2,r,safeA,warnA,BLUE,48)
    if limitV < maxV then
        drawRingSegment(cx,cy,r-2,r,warnA,math.rad(400),RED,28)
    end

    -- ARN braking curve overlay
    if targetV > 0 and distM > 0 then
        local curveRatio, onCurve, urgent = brakingCurveInfo(spdV,targetV,distM)
        local curveCol = urgent and RED or (onCurve and AMBER or PURPLE)
        local curA = speedAngle(spdV,maxV)
        local tgtA = speedAngle(targetV,maxV)
        drawRingSegment(cx,cy,r-6,r-4,tgtA,curA,curveCol,24)
    end

    -- ticks
    for k=0,maxV,10 do
        local a=speedAngle(k,maxV)
        local major=(k%20==0)
        local r1=major and (r-2) or (r-1)
        local r2=major and (r-9) or (r-6)
        C3(DIM)
        screen.drawLine(cx+math.cos(a)*r1, cy+math.sin(a)*r1, cx+math.cos(a)*r2, cy+math.sin(a)*r2)
    end

    -- traction/brake inner arcs
    local tracN=clamp(tracPct/100,0,1)
    local brkN=clamp((brkPct+regenPct)/100,0,1)

    if tracN>0 then
        drawRingSegment(cx,cy,r-13,r-10,math.rad(270),math.rad(270 + tracN*90),GREEN,20)
    end
    if brkN>0 then
        drawRingSegment(cx,cy,r-13,r-10,math.rad(270 - brkN*90),math.rad(270),AMBER,20)
    end

    -- markers
    drawMarker(cx,cy,r+1,speedAngle(limitV,maxV),CYAN,11)
    if targetV>0 then
        drawMarker(cx,cy,r+1,speedAngle(targetV,maxV),AMBER,8)
    end

    -- needle
    local a=speedAngle(spdV,maxV)
    C3(FG)
    screen.drawLine(cx,cy,cx+math.cos(a)*(r-15),cy+math.sin(a)*(r-15))
    screen.drawLine(cx+1,cy,cx+math.cos(a)*(r-15)+1,cy+math.sin(a)*(r-15))
    screen.drawCircleF(cx,cy,2)

    -- centre readout
    C3(FG)
    screen.drawTextBox(cx-r*0.62, cy-13, r*1.24, 12, string.format("%3.0f", spdV), 0, 0)
    C3(DIM)
    screen.drawTextBox(cx-r*0.62, cy+1, r*1.24, 8, M_MPH and "mph" or "km/h", 0, 0)

    C3(CYAN)
    screen.drawTextBox(cx-r*0.62, cy+11, r*1.24, 8, string.format("LIM %3.0f", limitV), 0, 0)
    if targetV>0 then
        C3(AMBER)
        screen.drawTextBox(cx-r*0.62, cy+19, r*1.24, 8, string.format("TGT %3.0f", targetV), 0, 0)
    end
end

local function drawBar(x,y,w,h,val,col,EDGE)
    screen.setColor(12,16,22)
    screen.drawRectF(x,y,w,h)
    C3(EDGE)
    screen.drawRect(x,y,w,h)
    local fill=math.floor(clamp(val,0,100)/100*(w-2))
    if fill>0 then
        C3(col)
        screen.drawRectF(x+1,y+1,fill,h-2)
    end
end

local function drawInfoPanel(x,y,w,h,FG,DIM,FACE,EDGE,GREEN,AMBER,RED,CYAN,PURPLE)
    panel(x,y,w,h,FACE,EDGE)

    local yy=y+3
    local row=7

    C3(FG)   screen.drawText(x+3,yy,"SYSTEM"); yy=yy+row
    C3(DIM)  screen.drawText(x+3,yy,arn and "ARN ACTIVE" or "ARN OFF"); yy=yy+row

    C3(FG)   screen.drawText(x+3,yy,"AUTH"); yy=yy+row
    C3(CYAN) screen.drawText(x+3,yy,string.format("%4.0fm", authRem)); yy=yy+row

    C3(FG)   screen.drawText(x+3,yy,"TARGET"); yy=yy+row
    C3(AMBER) screen.drawText(x+3,yy,string.format("%3.0f", target)); yy=yy+row

    C3(FG)   screen.drawText(x+3,yy,"DIST"); yy=yy+row
    C3(CYAN) screen.drawText(x+3,yy,string.format("%4.0fm", distT)); yy=yy+row

    C3(FG)   screen.drawText(x+3,yy,"DIR"); yy=yy+row
    C3(DIM)  screen.drawText(x+3,yy,rev and "REV" or "FWD"); yy=yy+row

    C3(FG)   screen.drawText(x+3,yy,"READY"); yy=yy+row
    if master and doors and not intervene then C3(GREEN) else C3(RED) end
    local txt = master and (doors and "YES" or "DOOR") or "OFF"
    screen.drawText(x+3,yy,txt)

    local bx=x+2
    local bw=w-4
    local by=y+h-20

    C3(DIM) screen.drawText(bx,by-7,"TRAC")
    drawBar(bx,by,bw,5,trac,GREEN,EDGE)

    C3(DIM) screen.drawText(bx,by+7,"BRK")
    drawBar(bx,by+14,bw,5,brk+regen,AMBER,EDGE)
end

local function drawBottomStrip(x,y,w,h,FG,DIM,GREEN,AMBER,RED,PURPLE,FACE,EDGE)
    panel(x,y,w,h,FACE,EDGE)

    local msg="COAST"
    local col=DIM

    local curveRatio,onCurve,urgent = brakingCurveInfo(spd,target,distT)

    if intervene then
        msg="BRAKE INTERVENTION"
        col=RED
    elseif overspeed then
        msg="OVERSPEED"
        col=RED
    elseif arn and target > 0 and urgent then
        msg="BRAKE CURVE"
        col=RED
    elseif arn and target > 0 and onCurve then
        msg="APPROACH TARGET"
        col=AMBER
    elseif not master then
        msg="MASTER OFF"
        col=AMBER
    elseif not doors then
        msg="DOOR INTERLOCK"
        col=AMBER
    elseif trac > 0.1 then
        msg="POWER"
        col=GREEN
    elseif (brk+regen) > 0.1 then
        msg="BRAKING"
        col=AMBER
    elseif arn then
        msg="READY"
        col=GREEN
    end

    C3(col)
    screen.drawTextBox(x+2,y+1,w-4,h-2,msg,0,0)
end

local function drawTinyBtn(x,y,w,h,label,active,FACE,EDGE,FG,GREEN)
    panel(x,y,w,h,FACE,EDGE)
    if active then
        C3(GREEN)
        rect(x+1,y+1,w-2,h-2,true)
        screen.setColor(5,8,12)
    else
        C3(FG)
    end
    screen.drawTextBox(x,y+1,w,h-2,label,0,0)
end

function onTick()
    p1=input.getBool(1) or false
    p2=input.getBool(2) or false

    W=input.getNumber(1) or W
    H=input.getNumber(2) or H
    t1x=input.getNumber(3) or 0
    t1y=input.getNumber(4) or 0
    t2x=input.getNumber(5) or 0
    t2y=input.getNumber(6) or 0

    spd=input.getNumber(7) or 0
    brk=input.getNumber(8) or 0
    trac=input.getNumber(9) or 0
    regen=input.getNumber(10) or 0
    limit=input.getNumber(11) or 160
    target=input.getNumber(12) or 0
    distT=input.getNumber(13) or 0
    authRem=input.getNumber(14) or 0

    arn=input.getBool(3) or false
    overspeed=input.getBool(4) or false
    intervene=input.getBool(5) or false
    doors=input.getBool(6) or false
    master=input.getBool(7) or false
    rev=input.getBool(8) or false
end

function onDraw()
    local BG,FG,DIM,FACE,EDGE,BLUE,GREEN,AMBER,RED,CYAN,PURPLE=pal()

    local sW,sH=screen.getWidth(),screen.getHeight()
    if sW>0 and sH>0 then
        W,H=sW,sH
    end

    C3(BG)
    screen.drawRectF(0,0,W,H)

    local headerH=8
    local bottomH=8
    local btnH=8
    local bodyY=headerH+1
    local bodyH=H-headerH-bottomH-btnH-3
    if bodyH < 20 then bodyH=20 end

    panel(0,0,W,headerH,FACE,EDGE)
    C3(DIM)
    screen.drawText(2,1,"PEN76")
    C3(FG)
    screen.drawTextBox(0,1,W-2,6,arn and "CENTRE DMI" or "LOCAL MODE",1,0)

    -- 3x2 layout
    local leftW=math.floor(W*0.62)
    local rightW=W-leftW-1

    local dialCx=math.floor(leftW/2)
    local dialCy=bodyY + math.floor(bodyH*0.54)
    local dialR=math.floor(math.min(leftW,bodyH)*0.48)

    local maxV = M_MPH and 100 or CURVE_MAX_KMH
    local shownSpd = M_MPH and (spd*0.621371) or spd
    local shownLimit = M_MPH and (limit*0.621371) or limit
    local shownTarget = M_MPH and (target*0.621371) or target

    drawDial(
        dialCx,dialCy,dialR,
        shownSpd,maxV,shownLimit,shownTarget,
        trac,brk,regen,distT,
        FG,DIM,BLUE,GREEN,AMBER,RED,CYAN,PURPLE
    )

    drawInfoPanel(leftW+1,bodyY,rightW,bodyH,FG,DIM,FACE,EDGE,GREEN,AMBER,RED,CYAN,PURPLE)
    drawBottomStrip(0,H-bottomH-btnH,W,bottomH,FG,DIM,GREEN,AMBER,RED,PURPLE,FACE,EDGE)

    -- only 2 buttons
    local by=H-btnH
    local bw=math.floor((W-6)/2)
    BTN={
        {x=2,y=by+1,w=bw,h=btnH-2,kind=1},
        {x=4+bw,y=by+1,w=bw,h=btnH-2,kind=2},
    }

    drawTinyBtn(BTN[1].x,BTN[1].y,BTN[1].w,BTN[1].h,"NGT",M_NIGHT,FACE,EDGE,FG,GREEN)
    drawTinyBtn(BTN[2].x,BTN[2].y,BTN[2].w,BTN[2].h,"MPH",M_MPH,FACE,EDGE,FG,GREEN)

    local function press(px,py,was,is)
        if is and not was then
            for i=1,#BTN do
                local b=BTN[i]
                if hit(b.x,b.y,b.w,b.h,px,py) then
                    if b.kind==1 then
                        M_NIGHT=not M_NIGHT
                    elseif b.kind==2 then
                        M_MPH=not M_MPH
                    end
                end
            end
        end
    end

    press(t1x,t1y,p1p,p1)
    press(t2x,t2y,p2p,p2)
    p1p,p2p=p1,p2
end
