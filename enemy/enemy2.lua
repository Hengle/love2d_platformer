local gc=love.graphics
local draw,line,color,text=gc.draw,gc.line,gc.setColor,gc.print
local rect,mask=gc.rectangle,gc.setScissor
local rand,int=math.random,math.floor
Enemy1={}

function Enemy1:new()
    local new={}
    setmetatable(new,Enemy1)
    self.__index=self
    new.scene=Scene
    new.hpmax=1200
    new.hp=1200
    new.defend=20
    new.x=0
    new.y=0            --坐标
    new.vx=0
    new.vy=0           --速度
    new.vMax=2         --最大速度
    new.isRight=true   --朝向
    new.jumpTimer=0
    new.jumping=false
    new.onGround=false
    new._hitbox={}
    new._attackbox={}
    new.hitbox={x=0,y=0,w=0,h=0}
    new.attackbox={x=0,y=0,w=0,h=0}
    new.injuryNum={}
    new.injuryTimer=0
    new.act=1          --动作
    new.actTimer=0     --动作计时器
    new.image=nil      --贴图
    new.quads=nil      --切片
    new.aniSpeed=3     --动画速度
    new.task=0         --攻击
    new.taskTimer=0    --攻击计时器
    new.danmaku={{},{},{},{}}--弹幕
    new.imgDanmaku=love.graphics.newImage("img/danmaku.png")
    -- new.imgLaser=love.graphics.newImage("img/laser.png")
    return new
end

function Enemy1:loadData(datafile)
    local data=require(datafile)
    self.image=love.graphics.newImage(data.image)
    self.quads=data.quads
    self._hitbox=data.hitbox
    self._attackbox=data.attackbox
end

function Scene:addEnemy1(obj)
    obj.scene=self
    table.insert(self.enemys,obj)
end

local function collideMap(self)
    if not self.scene then return end
    local map=self.scene.map
    local int=math.floor
    local tilesize=self.scene.map.tilesize
    local hitbox=self._hitbox[self.act]
    local xNew,yNew=self.x+self.vx,self.y+self.vy
    local x1,y1=xNew+hitbox.x,self.y+hitbox.y
    local x2,y2=x1+hitbox.w-.1,y1+hitbox.h-.1
    local collide=Map.notPassable
    if self.vx>0 then
        --右侧碰撞
        if collide(map,x2,y1) or collide(map,x2,y2) or collide(map,x2,y1+16) or collide(map,x2,y1+32) then
            xNew=int(x2/tilesize)*tilesize-hitbox.w-hitbox.x
            self.vx=0
        end
    elseif self.vx<0 then
        --左侧碰撞
        if collide(map,x1,y1) or collide(map,x1,y2) or collide(map,x1,y1+16) or collide(map,x2,y1+32)then
            xNew=int(x1/tilesize+1)*tilesize-hitbox.x
            self.vx=0
        end
    end
    x1,y1=xNew+hitbox.x,yNew+hitbox.y
    x2,y2=x1+hitbox.w-.1,y1+hitbox.h-.1
    self.onGround=false
    if self.vy>0 then
        --下侧碰撞
        if collide(map,x1,y2) or collide(map,x2,y2) or collide(map,x1+16,y2) then
            yNew=int(y2/tilesize)*tilesize-hitbox.h-hitbox.y
            self.onGround=true
            self.vy=0
        end
    elseif self.vy<0 then
        --上侧碰撞
        if collide(map,x1,y1) or collide(map,x2,y1) or collide(map,x1+16,y2) then
            yNew=int(y1/tilesize+1)*tilesize-hitbox.y
            self.vy=0
        end
    end
    self.x,self.y=xNew,yNew
    -- 储存当前的hitbox
    local hb,ab=self.hitbox,self.attackbox
    hb.w,hb.h,hb.y=hitbox.w,hitbox.h,yNew+hitbox.y
    if self.isRight then
        hb.x=xNew+hitbox.x
    else
        hb.x=xNew-hitbox.x-hitbox.w
    end
end

local function updateAct(self)
    self.act=math.floor(self.scene.frames/self.aniSpeed)%10+1
    self.vy=self.vy+0.3;
    if self.vx>0 then
        self.isRight=true
    elseif self.vx<0 then
        self.isRight=false
    end
end

-- 弹幕属性列表
-- 1 匀速直线运动 [x,y,vx,vy]
-- 2 带旋转的 [x,y,vx,vy,dir,t]
-- 3 普通激光 [x,y,angle,t,lenth]
-- 4 弹幕消失动画 [x,y,t]
local function updateTask(self)
    local frames=self.taskTimer
    local cos,sin,pi=math.cos,math.sin,math.pi
    local x,y=self.x,self.y
    local _2pi=pi*2-.0001
    if self.task==0 then
        if frames%10==0 and rand()<0.1 then
            self.task,self.taskTimer=rand(6),0
        end
    elseif self.task==1 then
        local danmaku=self.danmaku[1]
        local _=#danmaku
        if frames%10==0 then
            if frames%20==0 then
                for i=0,_2pi,pi/8 do
                    local vx,vy=cos(i)*2,sin(i)*2
                    _=_+1
                    danmaku[_]={x,y,vx,vy}
                end
            else
                for i=pi/16,_2pi,pi/8 do
                    local vx,vy=cos(i)*2,sin(i)*2
                    _=_+1
                    danmaku[_]={x,y,vx,vy}
                end
            end
        end
        if self.taskTimer>120 then
            self.task,self.taskTimer=0,0
        end
    end
    self.taskTimer=self.taskTimer+1
end

local function updateDanmaku(self)
    local camera=self.scene.camera
    local x1,y1=camera:InvTransform(0,0)
    local x2,y2=camera:InvTransform(1280,720)
    local cos,sin=math.cos,math.sin
    local map,collide=map,Map.notPassable
    local px,py=player.x,player.y
    local danmaku,new,_
    local fade,__={},1 --用于弹幕消失动画
    ---------------------------------------------------------------------------
    -- 弹幕种类1
    danmaku,new,_=self.danmaku[1],{},1
    for i=1,#danmaku do
        local d=danmaku[i]
        d[1],d[2]=d[1]+d[3],d[2]+d[4]
        if (d[1]-px)*(d[1]-px)+(d[2]-py)*(d[2]-py)<4 then --玩家受伤
            player:injure(int(50+50*rand()))
        end
        if d[1]>x1 and d[1]<x2 and d[2]>y1 and d[2]<y2 then
            if not collide(map,d[1],d[2]) then
                new[_],_=d,_+1
            else
                fade[__],__={d[1],d[2],0},__+1
            end
        end
    end
    self.danmaku[1]=new
    ---------------------------------------------------------------------------
    -- 弹幕消失
    danmaku=self.danmaku[4]
    for i=1,#danmaku do
        local d=danmaku[i]
        if d[3]<20 then
            fade[__],__=d,__+1
        end
        d[3]=d[3]+1
    end
    self.danmaku[4]=fade
end

local function updateInjure(self)
    local injury=self.injuryNum
    local new,_={},1
    for i=1,#injury do
        local t=injury[i]
        if t[4]<60 then
            new[_],_=t,_+1
        end
        t[2],t[4]=t[2]-1,t[4]+1
    end
    self.injuryNum=new
    if self.injuryTimer>0 then
        self.injuryTimer=self.injuryTimer-1
    end
end

function Enemy1:update()
    updateAct(self)
    collideMap(self)
    updateTask(self)
    updateDanmaku(self)
    updateInjure(self)
end

function Enemy1:injure(n)
    if self.injuryTimer==0 then
        local t=self.injuryNum
        t[#t+1]={self.x,self.y,n,0}
        self.injuryTimer=10
        self.hp=self.hp-n
        if self.hp<0 then
            self.hp=0
        end
    end
end

local function drawHitbox(self)
    local camera=self.scene.camera
    local hitbox=self.hitbox
    x,y=camera:Transform(hitbox.x,hitbox.y)
    color(1,1,1,1)
    love.graphics.rectangle("line",x,y,camera.z*hitbox.w,camera.z*hitbox.h)
end

function Enemy1:draw()
    local camera=self.scene.camera
    local z=camera.z
    local x,y=camera:Transform(self.x,self.y)
    color(1,1,1,1)
    -- if self.isRight then
    --     draw(self.image,self.quads[self.act],x,y,0,z,z,24,40)
    -- else
    --     draw(self.image,self.quads[self.act],x,y,0,-z,z,24,40)
    -- end
    drawHitbox(self)
end

local function hsv(h,s,v)
    local i=int(h*6)
    local f=h*6-i;
    local p=v*(1-s)
    local q=v*(1-f*s)
    local t=v*(1-(1-f)*s)
    if i==0     then color(v,t,p)
    elseif i==1 then color(q,v,p)
    elseif i==2 then color(p,v,t)
    elseif i==3 then color(p,q,v)
    elseif i==4 then color(t,p,v)
    elseif i==5 then color(v,p,q)
    end
end

function Enemy1:drawStatus()
    local w,h=480,48
    local x,y=1280-20-w,20
    hsv(.72,.9+.1*math.sin(self.scene.frames*.1),1)
    mask(x,y,w*self.hp/self.hpmax,h)
    rect("fill",x,y,w,h,12,12)
    hsv(.72,.7+.1*math.sin(self.scene.frames*.1),1)
    mask(x,y,w*self.hp/self.hpmax,8)
    rect("fill",x,y,w,h,12,12)
    mask()
    color(1,1,1)
    gc.setLineWidth(3)
    rect("line",x,y,w,h,12,12)
    gc.setLineWidth(1)
end

function Enemy1:drawDanmaku()
    local imgDanmaku=self.imgDanmaku
    local camera=self.scene.camera
    local z=camera.z
    local danmaku=self.danmaku[1]
    color(1,1,1,1)
    for i=1,#danmaku do
        local d=danmaku[i]
        local x,y=camera:Transform(d[1],d[2])
        draw(imgDanmaku,x,y,0,z*.25,z*.25,16,16)
    end
    text(string.format("num: %d, laser:%d",#self.danmaku[1]+#self.danmaku[2],#self.danmaku[3]),0,160)
    text(string.format("task: %d, timer: %d",self.task,self.taskTimer),0,180)
end

function Enemy1:drawInjury()
    local injury=self.injuryNum
    local camera=self.scene.camera
    for i=1,#injury do
        local d=injury[i]
        local x,y=camera:Transform(d[1],d[2])
        if d[4]<40 then
            text(d[3],x,y,0,2,2,10,10)
        else
            local z=.066*(70-d[4])
            text(d[3],x,y,0,z,z,10,10)
        end
    end
end