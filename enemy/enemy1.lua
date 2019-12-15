Enemy1={}

function Enemy1:new()
    local new={}
    setmetatable(new,Enemy1)
    self.__index=self
    self.scene=Scene
    self.x=0
    self.y=0            --坐标
    self.vx=0
    self.vy=0           --速度
    self.vMax=2         --最大速度
    self.isRight=true   --朝向
    self.jumpTimer=0
    self.jumping=false
    self.onGround=false
    self._hitbox={}
    self._attackbox={}
    self.hitbox={x=0,y=0,w=0,h=0}
    self.attackbox={x=0,y=0,w=0,h=0}
    self.act=1          --动作
    self.actTimer=0     --动作计时器
    self.image=nil      --贴图
    self.quads=nil      --切片
    self.aniSpeed=3     --动画速度
    self.task=0         --攻击
    self.taskTimer=0    --攻击计时器
    self.danmaku={{},{},{},{}}--弹幕
    self.imgDanmaku=love.graphics.newImage("img/danmaku.png")
    self.imgLaser=love.graphics.newImage("img/laser.png")
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
    local rand,int,cos,sin,pi=math.random,math.floor,math.cos,math.sin,math.pi
    local x,y=self.x,self.y
    local _2pi=pi*2
    if self.task==0 then
        if frames%10==0 and rand()<0.1 then
            self.task,self.taskTimer=6,0
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
    elseif self.task==2 then --螺旋
        local danmaku=self.danmaku[1]
        local _=#danmaku
        if frames%4==0 then
            local m=int(frames/4)%8
            local d=pi/64
            for i=m*d,_2pi,d*8 do
                local vx,vy=cos(i)*2,sin(i)*2
                _=_+1
                danmaku[_]={x,y,vx,vy}
            end
        end
        if self.taskTimer>120 then
            self.task,self.taskTimer=0,0
        end
    elseif self.task==3 then --随机
        local danmaku=self.danmaku[1]
        local _=#danmaku
        if self.taskTimer<60 then
            local a,v,vx,vy
            for __=1,3 do
                a,v=rand()*2*pi,rand()+1
                vx,vy,_=cos(a)*2,sin(a)*2,_+1
                danmaku[_]={x,y,vx*v,vy*v}
            end
        end
        if self.taskTimer>90 then
            self.task,self.taskTimer=0,0
        end
    elseif self.task==4 then -- 旋转
        local danmaku=self.danmaku[2]
        local _=#danmaku
        if self.taskTimer%10==0 then
            for i=0,_2pi,pi/8 do
                local vx,vy
                vx,vy,_,i=cos(i)*2,sin(i)*2,_+1,i+pi/16
                danmaku[_]={x,y,vx,vy,true,0}
                vx,vy,_=cos(i)*2,sin(i)*2,_+1
                danmaku[_]={x,y,vx,vy,false,0}
            end
        end
        if self.taskTimer>90 then
            self.task,self.taskTimer=0,0
        end
    elseif self.task==5 then --激光
        local danmaku=self.danmaku[3]
        local _=#danmaku
        if frames%80==0 then
            for i=0,_2pi,pi/(frames/80+4) do
                _=_+1
                danmaku[_]={0,0,i,-20,0}
            end
        end
        if self.taskTimer>800 then
            self.task,self.taskTimer=0,0
        end
    elseif self.task==6 then --不等速 单向
        local danmaku=self.danmaku[1]
        local _=#danmaku
        if frames%4==0 then
            local j=frames/4
            if j<8 then
                for i=pi*j/64,_2pi,pi/8 do
                    local k=j*.1+1
                    local vx,vy=k*cos(i),k*sin(i)
                    _=_+1
                    danmaku[_]={x,y,vx,vy}
                end
            end
        end
        if self.taskTimer>60 then
            self.task,self.taskTimer=0,0
        end
    end
    self.taskTimer=self.taskTimer+1
end

local function updateDanmaku(self)
    local camera=self.scene.camera
    local x1,y1=camera:InvTransform(0,0)
    local x2,y2=camera:InvTransform(1280,720)
    local cos,sin,rand,int=math.cos,math.sin,math.random,math.floor
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
    -- 弹幕种类2
    danmaku,new,_=self.danmaku[2],{},1
    for i=1,#danmaku do
        local d=danmaku[i]
        local k=d[6]*0.02
        d[1],d[2]=d[1]+d[3],d[2]+d[4]
        if d[5] then
            d[1],d[2]=d[1]+k*d[4],d[2]-k*d[3] --顺时针[y,-x]
        else
            d[1],d[2]=d[1]-k*d[4],d[2]+k*d[3] --逆时针[-y,x]
        end
        d[6]=d[6]+1
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
    self.danmaku[2]=new
    ---------------------------------------------------------------------------
    -- 弹幕种类3
    danmaku,new,_=self.danmaku[3],{},1
    for i=1,#danmaku do
        local d=danmaku[i]
        local vx,vy=cos(d[3]),sin(d[3])
        local x,y=self.x+20*vx,self.y+20*vy
        local x3,y3=x,y
        d[1],d[2],d[5]=x,y,0
        while not collide(map,x,y) and x>x1 and x<x2 and y>y1 and y<y2 do
            x,y,d[5]=x+vx,y+vy,d[5]+1
        end
        -- 玩家受伤
        local z3,z4,pz=vx*x3+vy*y3,vx*x+vy*y,vx*px+vy*py
        local z=vy*px-vx*py+vx*y3-vy*x3 -- 点到直线距离公式
        if d[4]>=0 and z*z/(vx*vx+vy*vy)<4 and (z3>pz and pz>z4 or z3<pz and pz<z4) then
            player:injure(int(50+50*rand()))
        end
        if d[4]<40 then
            new[_],_=d,_+1
        end
        d[3],d[4]=d[3]+.005,d[4]+1
    end
    self.danmaku[3]=new
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

function Enemy1:update()
    updateAct(self)
    collideMap(self)
    updateTask(self)
    updateDanmaku(self)
end

local function drawHitbox(self)
    local camera=self.scene.camera
    local hitbox=self.hitbox
    local x1,y1=self.x+hitbox.x,self.y+hitbox.y
    x,y=camera:Transform(x1,y1)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",x,y,camera.z*hitbox.w,camera.z*hitbox.h)
end

function Enemy1:draw()
    local camera=self.scene.camera
    local z=camera.z
    local x,y=camera:Transform(self.x,self.y)
    love.graphics.setColor(1,1,1,1)
    if self.isRight then
        love.graphics.draw(self.image,self.quads[self.act],x,y,0,z,z,24,40)
    else
        love.graphics.draw(self.image,self.quads[self.act],x,y,0,-z,z,24,40)
    end
    drawHitbox(self)
end

function Enemy1:drawDanmaku()
    local draw,line,color=love.graphics.draw,love.graphics.line,love.graphics.setColor
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
    danmaku=self.danmaku[2]
    for i=1,#danmaku do
        local d=danmaku[i]
        local x,y=camera:Transform(d[1],d[2])
        draw(imgDanmaku,x,y,0,z*.25,z*.25,16,16)
    end
    danmaku=self.danmaku[3]
    for i=1,#danmaku do
        local cos,sin=math.cos,math.sin
        local d=danmaku[i]
        local x,y=camera:Transform(d[1],d[2])
        if d[4]>0 then -- 动画效果：0--放大--10--恒定--30--缩小--40消失
            if d[4]<10 then
                draw(self.imgLaser,x,y,d[3],z*d[5],z*.05*d[4],0,4)
            elseif d[4]<30 then
                draw(self.imgLaser,x,y,d[3],z*d[5],z*.5,0,4)
            else
                draw(self.imgLaser,x,y,d[3],z*d[5],z*.05*(40-d[4]),0,4)
            end
        else
            local l=40*(d[4]+20)
            if l>z*d[5] then l=z*d[5] end
            line(x,y,x+l*cos(d[3]),y+l*sin(d[3]))
        end
    end
    danmaku=self.danmaku[4]
    for i=1,#danmaku do
        local d=danmaku[i]
        local x,y=camera:Transform(d[1],d[2])
        local s=z*.0125*(d[3]+20)
        color(1,1,1,(20-d[3])*.05)
        draw(imgDanmaku,x,y,0,s,s,16,16)
    end
    color(1,1,1,1)
    love.graphics.print(string.format("num: %d, laser:%d",#self.danmaku[1]+#self.danmaku[2],#self.danmaku[3]),0,120)
    love.graphics.print(string.format("task: %d, timer: %d",self.task,self.taskTimer),0,140)
end
