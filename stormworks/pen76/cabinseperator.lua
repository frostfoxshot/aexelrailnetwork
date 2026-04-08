

i24flip={x=9,y=8,w=14,h=22,a=false,p=false}

function onTick()
isP1 = input.getBool(1)
isP2 = input.getBool(2)

in1X = input.getNumber(3)
in1Y = input.getNumber(4)
in2X = input.getNumber(5)
in2Y = input.getNumber(6)

if isP1 and isInRectO(i24flip,in1X,in1Y) or isP2 and isInRectO(i24flip,in2X,in2Y) then
if not i24flip.p then
i24flip.a=not i24flip.a
i24flip.p=true
end
else
i24flip.p=false
end
output.setBool(1,i24flip.a)

i25Indc=input.getBool(4)

i26Indc=input.getBool(5)

i28Indc=input.getBool(3)
end

function onDraw()

setC(96,96,96)
screen.drawRectF(0,0,32,32)
setC(96,96,96)
screen.drawRectF(1,1,30,30)

if i24flip.a then
setC(96,96,96)
screen.drawRectF(9,8,14,22)
setC(0,0,0)
screen.drawRectF(12.5,15,7,6)
setC(71,0,0)
screen.drawRectF(10,10,12,6)
else
setC(96,96,96)
screen.drawRectF(9,8,14,22)
setC(0,0,0)
screen.drawRectF(12.5,17,7,6)
setC(71,0,0)
screen.drawRectF(10,23,12,6)
end

cx=4
cy=28
ri=3
ro=4
setC(19,19,19)
screen.drawCircleF(cx,cy,ro)
if i25Indc then
setC(30,96,0)
else
setC(16,16,16)
end
screen.drawCircleF(cx,cy,ri)

cx=28
cy=28
ri=3
ro=4
setC(19,19,19)
screen.drawCircleF(cx,cy,ro)
if i26Indc then
setC(30,96,0)
else
setC(16,16,16)
end
screen.drawCircleF(cx,cy,ri)

cx=16
cy=4
ri=3
ro=4
setC(19,19,19)
screen.drawCircleF(cx,cy,ro)
if i28Indc then
setC(30,96,0)
else
setC(16,16,16)
end
screen.drawCircleF(cx,cy,ri)
end

function setC(r,g,b,a)
if a==nil then a=255 end
screen.setColor(r,g,b,a)
end

function isInRectO(o,px,py)
return px>=o.x and px<=o.x+o.w and py>=o.y and py<=o.y+o.h
end

