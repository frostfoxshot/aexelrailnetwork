-- AEX EN76 Centre Speed Dial v4.4
-- 350 km/h dial / 220 mph dial
-- Major marks every 50
-- Bool Out 1 = Night mode
-- Bool Out 2 = MPH mode

local W,H=96,64

local p1,p2=false,false
local p1p,p2p=false,false
local t1x,t1y,t2x,t2y=0,0,0,0

local spd,brk,trac,regen=0,0,0,0
local vmax,target,distT,authRem=160,0,0,0

local arn,overspeed,intervene=false,false,false
local doors,master,rev=true,false,false

local M_NIGHT=false
local M_MPH=false
local tick=0
local tripKM=0
local BTN={}

local SERVICE_DECEL=0.75
local TICKS_PER_SECOND=60

local function clamp(x,a,b)
    if x<a then return a elseif x>b then return b else return x end
end

local function C(r,g,b) screen.setColor(r,g,b) end
local function C3(c) screen.setColor(c[1],c[2],c[3]) end
local function lerp(a,b,t) return a+(b-a)*t end
local function hit(x,y,w,h,px,py) return px>=x and px<=x+w and py>=y and py<=y+h end

local function fmt3(n)
    n=math.floor(math.max(n,0)+0.5)
    if n>999 then n=999 end
    return string.format("%03d",n)
end

local function pal()
    if M_NIGHT then
        return
        {2,5,9},{235,245,255},{70,95,125},{7,11,17},{25,38,55},
        {45,125,220},{65,210,110},{245,165,45},{255,55,55},
        {90,225,255},{170,110,255},{255,115,35}
    else
        return
        {14,28,50},{255,255,255},{120,145,180},{24,45,78},{65,105,160},
        {75,165,245},{90,245,145},{255,180,55},{255,65,65},
        {120,235,255},{205,140,255},{255,105,25}
    end
end

local function panel(x,y,w,h,face,edge)
    C3(face)
    screen.drawRectF(x,y,w,h)
    C3(edge)
    screen.drawRect(x,y,w,h)
end

local function drawArc(cx,cy,r,a1,a2,col,steps)
    C3(col)
    local px,py=nil,nil

    for i=0,steps do
        local t=i/steps
        local a=lerp(a1,a2,t)
        local x=cx+math.cos(a)*r
        local y=cy+math.sin(a)*r

        if px then
            screen.drawLine(px,py,x,y)
        end

        px,py=x,y
    end
end

local function drawRing(cx,cy,r1,r2,a1,a2,col,steps)
    if a2<a1 then
        local tmp=a1
        a1=a2
        a2=tmp
    end

    for r=r1,r2 do
        drawArc(cx,cy,r,a1,a2,col,steps)
    end
end

local function speedAngle(v,maxV)
    return math.rad(140 + clamp(v/maxV,0,1)*260)
end

local function drawMarker(cx,cy,r,a,col,len)
    C3(col)
    screen.drawLine(
        cx+math.cos(a)*(r-len),
        cy+math.sin(a)*(r-len),
        cx+math.cos(a)*r,
        cy+math.sin(a)*r
    )
end

local function brakingCurveInfo(curKmh,tgtKmh,distM)
    if tgtKmh<=0 or distM<=0 then
        return 0,false,false
    end

    local v=math.max(curKmh,0)/3.6
    local u=math.max(tgtKmh,0)/3.6
    local d=math.max(distM,0.1)

    local need=((v*v)-(u*u))/(2*SERVICE_DECEL)

    if need<0 then need=0 end

    local ratio=need/d

    return ratio,ratio>=0.75,ratio>=1.0
end

local function drawBar(x,y,w,h,val,col,edge)
    C(8,10,14)
    screen.drawRectF(x,y,w,h)

    C3(edge)
    screen.drawRect(x,y,w,h)

    local f=math.floor(clamp(val,0,100)/100*(w-2))

    if f>0 then
        C3(col)
        screen.drawRectF(x+1,y+1,f,h-2)
    end
end

local function drawNeedle(cx,cy,r,a,needleCol)
    local tipX=cx+math.cos(a)*(r-6)
    local tipY=cy+math.sin(a)*(r-6)

    local sideA=a+math.pi/2
    local w=3

    local leftX=cx+math.cos(sideA)*w
    local leftY=cy+math.sin(sideA)*w
    local rightX=cx-math.cos(sideA)*w
    local rightY=cy-math.sin(sideA)*w

    C(0,0,0)
    screen.drawTriangleF(tipX+1,tipY+1,leftX+1,leftY+1,rightX+1,rightY+1)

    C3(needleCol)
    screen.drawTriangleF(tipX,tipY,leftX,leftY,rightX,rightY)

    C(0,0,0)
    screen.drawCircleF(cx,cy,4)

    C3(needleCol)
    screen.drawCircle(cx,cy,3)

    C(235,245,255)
    screen.drawCircleF(cx,cy,1)
end

local function drawDial(cx,cy,r,FG,DIM,BLUE,GREEN,AMBER,RED,CYAN,PURPLE,NEEDLE)
    local maxV=M_MPH and 220 or 350
    local s=M_MPH and spd*0.621371 or spd
    local lim=M_MPH and vmax*0.621371 or vmax
    local tgt=M_MPH and target*0.621371 or target

    C(3,6,12)
    screen.drawCircleF(cx,cy,r+3)

    C(11,17,27)
    screen.drawCircleF(cx,cy,r+1)

    C(5,8,14)
    screen.drawCircleF(cx,cy,r-4)

    local startA=math.rad(140)
    local endA=math.rad(400)
    local limA=speedAngle(lim,maxV)

    drawRing(cx,cy,r-1,r+1,startA,endA,DIM,56)
    drawRing(cx,cy,r-1,r+1,startA,limA,BLUE,46)

    if lim<maxV then
        drawRing(cx,cy,r-1,r+1,limA,endA,RED,30)
    end

    if arn and tgt>0 and distT>0 then
        local ratio,onCurve,urgent=brakingCurveInfo(spd,target,distT)
        local col=urgent and RED or (onCurve and AMBER or PURPLE)

        drawRing(
            cx,cy,
            r-7,r-5,
            speedAngle(tgt,maxV),
            speedAngle(s,maxV),
            col,
            24
        )
    end

    if trac>0.1 then
        drawRing(
            cx,cy,
            r-12,r-10,
            math.rad(270),
            math.rad(270+clamp(trac/100,0,1)*70),
            GREEN,
            14
        )
    end

    local brakeTotal=clamp((brk+regen)/100,0,1)

    if brakeTotal>0.01 then
        drawRing(
            cx,cy,
            r-12,r-10,
            math.rad(270-brakeTotal*70),
            math.rad(270),
            AMBER,
            14
        )
    end

    -- Minor marks every 10
    for k=0,maxV,10 do
        local a=speedAngle(k,maxV)

        C3(DIM)

        screen.drawLine(
            cx+math.cos(a)*(r-2),
            cy+math.sin(a)*(r-2),
            cx+math.cos(a)*(r-5),
            cy+math.sin(a)*(r-5)
        )
    end

    -- Major marks every 50
    for k=0,maxV,50 do
        local a=speedAngle(k,maxV)

        C(230,240,255)

        screen.drawLine(
            cx+math.cos(a)*(r-2),
            cy+math.sin(a)*(r-2),
            cx+math.cos(a)*(r-10),
            cy+math.sin(a)*(r-10)
        )
    end

    drawMarker(cx,cy,r+2,speedAngle(lim,maxV),CYAN,10)

    if tgt>0 then
        drawMarker(cx,cy,r+2,speedAngle(tgt,maxV),AMBER,8)
    end

    drawNeedle(cx,cy,r,speedAngle(s,maxV),NEEDLE)
end

local function statusText()
    local ratio,onCurve,urgent=brakingCurveInfo(spd,target,distT)

    if intervene then return "INTERVENTION","red" end
    if overspeed then return "OVERSPEED","red" end
    if arn and target>0 and urgent then return "CURVE","red" end
    if arn and target>0 and onCurve then return "APPROACH","amber" end
    if not master then return "MASTER OFF","amber" end
    if not doors then return "DOORS","amber" end
    if trac>0.1 then return "POWER","green" end
    if brk+regen>0.1 then return "BRAKING","amber" end
    if arn then return "READY","green" end

    return "LOCAL","dim"
end

function onTick()
    tick=tick+1

    p1=input.getBool(1) or false
    p2=input.getBool(2) or false

    arn=input.getBool(3) or false
    overspeed=input.getBool(4) or false
    intervene=input.getBool(5) or false
    doors=input.getBool(6) or false
    master=input.getBool(7) or false
    rev=input.getBool(8) or false

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

    vmax=input.getNumber(11) or 160
    target=input.getNumber(12) or 0
    distT=input.getNumber(13) or 0
    authRem=input.getNumber(14) or 0

    if master and spd>0.05 then
        tripKM=tripKM+(spd/3600)/60
    end

    output.setBool(1,M_NIGHT)
    output.setBool(2,M_MPH)
end

function onDraw()
    local BG,FG,DIM,FACE,EDGE,BLUE,GREEN,AMBER,RED,CYAN,PURPLE,NEEDLE=pal()

    local sW,sH=screen.getWidth(),screen.getHeight()
    if sW>0 and sH>0 then
        W,H=sW,sH
    end

    C3(BG)
    screen.drawRectF(0,0,W,H)

    local flash=(math.floor(tick/12)%2)==0

    -- Header
    panel(0,0,W,8,FACE,EDGE)

    C3(DIM)
    screen.drawText(2,1,"EN76")

    C3(arn and GREEN or AMBER)
    screen.drawTextBox(0,1,W-2,6,arn and "ARN" or "LOCAL",1,0)

    -- Left speed/trip
    local lx=2
    local ly=13

    local shownSpd=M_MPH and spd*0.621371 or spd
    local shownTrip=M_MPH and tripKM*0.621371 or tripKM
    local unitSpd=M_MPH and "mph" or "kmh"
    local unitTrip=M_MPH and "Mi" or "km"

    C3(FG)
    screen.drawTextBox(lx,ly,28,10,fmt3(shownSpd),0,0)

    C3(CYAN)
    screen.drawTextBox(lx,ly+10,28,6,unitSpd,0,0)

    C3(EDGE)
    screen.drawLine(lx,ly+20,lx+28,ly+20)

    C3(FG)
    screen.drawTextBox(lx,ly+25,30,8,string.format("%03.0f%s",shownTrip,unitTrip),0,0)

    -- Centre dial
    local bottomH=16
    local dialR=math.floor(math.min(W-52,H-bottomH-8)*0.50)

    if dialR<16 then
        dialR=16
    end

    local cx=50
    local cy=34

    drawDial(cx,cy,dialR,FG,DIM,BLUE,GREEN,AMBER,RED,CYAN,PURPLE,NEEDLE)

    -- Right AUTH/DIST
    local sx=W-22
    local sy=13

    panel(sx,sy,20,28,FACE,EDGE)

    C3(DIM)
    screen.drawTextBox(sx,sy+2,20,5,"AUTH",0,0)

    C3(CYAN)
    screen.drawTextBox(sx,sy+8,20,7,string.format("%04.0f",authRem),0,0)

    C3(EDGE)
    screen.drawLine(sx+2,sy+16,sx+18,sy+16)

    C3(DIM)
    screen.drawTextBox(sx,sy+18,20,5,"DIST",0,0)

    C3(target>0 and AMBER or DIM)
    screen.drawTextBox(sx,sy+24,20,7,string.format("%04.0f",distT),0,0)

    -- Status strip
    local msg,kind=statusText()
    local col=DIM

    if kind=="red" then col=RED
    elseif kind=="amber" then col=AMBER
    elseif kind=="green" then col=GREEN end

    if kind=="red" and flash then
        C3(RED)
        screen.drawRectF(0,H-16,W,8)
        C(0,0,0)
    else
        panel(0,H-16,W,8,FACE,EDGE)
        C3(col)
    end

    screen.drawTextBox(1,H-15,W-2,6,msg,0,0)

    -- Bottom traction/brake bars
    C3(DIM)
    screen.drawText(2,H-7,"T")
    drawBar(9,H-7,22,5,trac,GREEN,EDGE)

    C3(DIM)
    screen.drawText(34,H-7,"B")
    drawBar(41,H-7,22,5,brk+regen,AMBER,EDGE)

    -- Buttons: N = night, M = mph
    local by=H-8

    BTN={
        {x=W-27,y=by+1,w=12,h=6,kind=1},
        {x=W-14,y=by+1,w=12,h=6,kind=2}
    }

    for i=1,#BTN do
        local b=BTN[i]
        local active=(b.kind==1 and M_NIGHT) or (b.kind==2 and M_MPH)

        panel(b.x,b.y,b.w,b.h,FACE,EDGE)

        C3(active and GREEN or FG)

        screen.drawTextBox(
            b.x,
            b.y+1,
            b.w,
            b.h-1,
            b.kind==1 and "N" or "M",
            0,
            0
        )
    end

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
