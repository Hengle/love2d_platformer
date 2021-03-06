Scene={}

function Scene:new()
    local new={};
    setmetatable(new,Scene)
    self.__index=self
    self.width,self.height=love.graphics.getPixelDimensions()
    self.map=Map
    self.camera=Camera:new()
    self.weather=Weather and Weather:new()
    self.frames=0
    self.players={}
    self.enemys={}
    self.objects={}
    return new
end

local function updateCamera(self)
    camera=self.camera
    camera.x=player.x
    camera.y=player.y
    if camera.x*camera.z<640 then
        camera.x=640/camera.z
    end
    if (self.map.pixelWidth-player.x)*camera.z<640 then
        camera.x=self.map.pixelWidth-640/camera.z
    end
    if camera.y*camera.z<360 then
        camera.y=360/camera.z
    end
    if (self.map.pixelHeight-player.y)*camera.z<360 then
        camera.y=self.map.pixelHeight-360/camera.z
    end
    local c=self.camera
    love.graphics.scale(c.z)
    love.graphics.translate(self.width*.5/c.z-c.x,self.height*.5/c.z-c.y)
end

function Scene:update()
    updateCamera(self)
    player:update()
    if self.weather then
        self.weather:update()
    end
    text:update()
	editor:update()
	for i=1,#self.enemys do
        self.enemys[i]:update()
    end
    self.frames=self.frames+1
end

function Scene:draw()
    local c=self.camera
    love.graphics.scale(c.z)
    love.graphics.translate(self.width*.5/c.z-c.x,self.height*.5/c.z-c.y)
    self.map:draw()
    for i=1,#self.enemys do
        self.enemys[i]:draw()
    end
    player:draw()
    for i=1,#self.enemys do
        self.enemys[i]:drawDanmaku()
        self.enemys[i]:drawInjury()
    end
    player:drawInjury()
	text:draw()
	editor:draw()
	control:draw()
    if self.weather then
        self.weather:draw()
    end
    love.graphics.origin()
    player:drawStatus()
    self.enemys[1]:drawStatus()
end
