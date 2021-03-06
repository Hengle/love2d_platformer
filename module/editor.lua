Editor={}

function Editor:new(Scene)
    local new={}
    setmetatable(new,Editor)
    self.__index=self
    self.scene=Scene
    self.box={i=0,j=0,x=0,y=0,w=0,id=1}
    return new
end

function Editor:update()
    local b=self.box
    if love.mouse.isDown(1) then
        self.scene.map.data[b.i][b.j]=b.id
    elseif love.mouse.isDown(2) then
        self.scene.map.data[b.i][b.j]=0
    end
end

function Editor:draw()
    local int=math.floor
    local x,y=love.mouse.getPosition()
    local ts=self.scene.map.tilesize
    local mapx,mapy=love.graphics.inverseTransformPoint(x,y)
    local b=self.box
    b.i,b.j=int(mapy/ts),int(mapx/ts)
    b.x,b.y=b.j*ts,b.i*ts
    b.w=ts
    if b.id>0 then
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.scene.map.image,self.scene.map.quads[b.id],b.x,b.y)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",b.x,b.y,b.w,b.w)
    love.graphics.print(string.format("Editor: (%d,%d)=>%d",b.i,b.j,b.id),0,80)
end
