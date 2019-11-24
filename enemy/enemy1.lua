Enemy1={}
local insert=table.insert

function Enemy1:new()
    local new={}
    setmetatable(new,Player)
    self.__index=self
    self.scene=Scene
    self.x=0
    self.y=0            --坐标
    self.vx=0
    self.vy=0           --速度
    self.vMax=2         --最大速度
    self.isRight=true
    self.jumpTimer=0
    self.jumping=false
    self.onGround=false
    self.hitbox={}
    self.attackbox={}
    self.act=1
    self.actTimer=0
    self.image=nil      --贴图
    self.quads=nil      --切片
    self.aniMove=true   --行走动画
    self.aniStand=false --踏步动画
    self.aniSpeed=10    --动画速度
    return new
end

function Enemy1:loadData(datafile)
    local data=require(datafile)
    self.image=love.graphics.newImage(data.image)
    self.quads=data.quads
    self.hitbox=data.hitbox
    self.attackbox=data.attackbox
end

function Scene:addEnemy1(obj)
    obj.scene=self
    insert(self.Enemy1s,obj)
end

local function getRect(hitbox,x,y)
    local x1,y1=x+hitbox.x,y+hitbox.y
    return x1,y1,x1+hitbox.w-0.1,y1+hitbox.h-0.1
end

local function collideMap(self)
    if not self.scene then return end
    local map=self.scene.map
    local int=math.floor
    local tilesize=self.scene.map.tilesize
    local hitbox=self.hitbox[self.act]
    local xNew,yNew=self.x+self.vx,self.y+self.vy
    local x1,y1,x2,y2=getRect(hitbox,xNew,self.y)
    if self.vx>0 then
        --右侧碰撞
        if map:notPassable(x2,y1) or map:notPassable(x2,y2) or map:notPassable(x2,y1+16) then
            xNew=int(x2/tilesize)*tilesize-hitbox.w-hitbox.x
            self.vx=0
        end
    elseif self.vx<0 then
        --左侧碰撞
        if map:notPassable(x1,y1) or map:notPassable(x1,y2) or map:notPassable(x1,y1+16) then
            xNew=int(x1/tilesize+1)*tilesize-hitbox.x
            self.vx=0
        end
    end
    x1,y1,x2,y2=getRect(hitbox,xNew,yNew)
    self.onGround=false
    if self.vy>0 then
        --下侧碰撞
        if map:notPassable(x1,y2) or map:notPassable(x2,y2) then
            yNew=int(y2/tilesize)*tilesize-hitbox.h-hitbox.y
            self.onGround=true
            self.vy=0
        end
    elseif self.vy<0 then
        --上侧碰撞
        if map:notPassable(x1,y1) or map:notPassable(x2,y1) then
            yNew=int(y1/tilesize+1)*tilesize-hitbox.y
            self.vy=0
        end
    end
    self.x,self.y=xNew,yNew
end

local function processDir(self)
    if self.vx>0 then
        self.isRight=true
    elseif self.vx<0 then
        self.isRight=false
    end
end

function Enemy1:update()
    collideMap(self)
    processDir(self)
end

function Enemy1:draw()
    local camera=self.scene.camera
    local scale=camera.z
    local x,y=camera:Transform(self.x,self.y)
    love.graphics.setColor(1,1,1,1)
    if self.isRight then
        love.graphics.draw(self.image,self.quads[self.act],x,y,0,scale,scale,64,64)
    else
        love.graphics.draw(self.image,self.quads[self.act],x,y,0,-scale,scale,64,64)
    end
end
