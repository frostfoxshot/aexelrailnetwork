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

chr={
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

chrd={}
chrd[s.byte(" ")]={w=5}
W=0.5 -- font weight

for i,tbl in pairs(chr) do
    local tx=tbl[1]
    local ty=tbl[2]
    local asc=s.byte(i)
    chrd[asc]={}
    chrd[asc].t={}
    local mx=0
    local x,y=0,0
    local skip=false
    for z=1,#tx do
        if tx[z]=="" then
            skip=true
            x,y=0,0
            chrd[asc].t[z]=false
        else
            x,y=x+tx[z],y+ty[z]
            local a1=(z==1 or skip) and at(ty[z+1],tx[z+1]) or at(ty[z],tx[z])
            local a2=(z==#tx or tx[z+1]=="") and a1 or at(ty[z+1],tx[z+1])
            local a0=(a1+a2)/2
            local d=a0-a1
            d=d<0 and d or pi2-d
            local w=W/M.max(si(d),co(d))
            local j,k,l,m = x+w*co(a0-pih),y+w*si(a0-pih),x+w*co(a0+pih),y+w*si(a0+pih)
            if ab(j)<W/2 then j,l=-W,-W end
            if ab(k)<W/2 then k,m=-W,-W end
            if ab(k-9)<W/4 then k,m=9+W,9+W end
            chrd[asc].t[z]={j,k,l,m}
            mx=M.max(mx,j,l)
            skip=false
        end
    end
    chrd[asc].w=mx
end

function TXT(txt,xx,yy,ww,hh)
    txt=s.upper(txt)
    local lw,tw,ss,th=0,0,0,9
    for pass=1,2 do
        if pass>1 then
            tw=lw-2+W
            ss=M.min(hh/th, ww/tw)
        end
        lw=0
        for i=1,#txt do
            local c=chrd[s.byte(s.sub(txt,i,i))] or chrd[s.byte(" ")]
            local w,t=c.w,c.t
            if pass>1 and t~=nil then
                for a,b in pairs(t) do
                    if a>1 and t[a-1] and t[a] then
                        local x=xx+ss*(lw+W)
                        local y=yy+(hh-ss*th)/2
                        local j,k,l,m=tU(t[a-1])
                        local n,o,p,q=tU(t[a])
                        dRC(x+ss*j,y+ss*k,x+ss*l,y+ss*m,x+ss*n,y+ss*o,x+ss*p,y+ss*q)
                    end
                end
            end
            lw=lw+w+2
        end
    end
end

function pad5(n)
    n = M.max(0, M.floor(n or 0))
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

runningNumber = 0
destIndex = 0
useOrange = true
displayOn = true

function onTick()
    runningNumber = M.floor(input.getNumber(1) or 0)
    destIndex = M.floor(input.getNumber(2) or 0)
    useOrange = input.getBool(1)
    displayOn = input.getBool(2)
end

function onDraw()
    local w = S.getWidth()
    local h = S.getHeight()

    S.setColor(0,0,0)
    S.drawClear()

    if not displayOn then
        return
    end

    if useOrange then
        S.setColor(255,110,0)
    else
        S.setColor(255,255,255)
    end

    local runText = pad5(runningNumber)
    local destText = stations[destIndex] or "OUT OF SERVICE"

    -- running number top-left
    S.drawText(1,1,runText)

    -- destination sign area
    TXT(destText, 1, 8, w-2, h-9)
end
