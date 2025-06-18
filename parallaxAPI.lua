---@class parallaxBackground
---@field parent ModelPart
---@field texture Texture
---@field offset number
---@field uvScale number
---@field scale number

---@class parallaxAPI
---@field backgrounds table<string,parallaxBackground>

local parallax = {
	backgrounds = {},
	models = {},
	backgroundParent = models:getChildren()[1]:newPart("parallaxBackgrounds","CAMERA"),
	modelParent = models:getChildren()[1]:newPart("parallaxModels","CAMERA")
}

parallax.backgroundParent:setPivot(0,17.05,0)
parallax.modelParent:setPivot(0,17.05,0)

local rotation = vectors.vec2(-15,30)
local lastMousePos = client.getMousePos()
local mousePressed = false
local lastWindowSize = client.getWindowSize()


local backgroundFunctions = {
	setTexture = function(self,texture)
		
	end
}

---@param ID string
---@param texture Texture
---@param offset number
---@param uvScale number
---@param scale number
function parallax.addBackground(ID,texture,offset,rotation,uvScale,scale)
	if parallax.backgrounds[ID] then error('background named "' .. ID .. '" already exists') end
	local root = parallax.backgroundParent:newPart(ID)
	local parent = root:newPart("parent")
	parent:setPos(0,0,offset)

	local textureDem = texture:getDimensions()
	local sprite = parent:newSprite(ID)
	sprite:setTexture(texture,textureDem.x * scale,textureDem.y * scale)
		:setPos(textureDem.x/2 * scale, textureDem.y/2 * scale,0)

	local uvPos = (1/uvScale) * scale
	for index,vertex in pairs(sprite:getVertices()) do
		local xMod = math.floor((index)/2) % 2
		local yMod = math.floor((index+1)/2) % 2
		vertex:setUV(uvPos * xMod, uvPos * yMod)
	end
		
	
	parallax.backgrounds[ID] = {
		root = root,
		texture = texture,
		offset = offset,
		rotation = rotation,
		uvScale = uvScale,
		scale = scale,
	}
end

function parallax.addModel(ID,model,rotation,displacement,offset)
	if parallax.models[ID] then error('model named "' .. ID .. '" already exists') end
	local parent =  parallax.modelParent:newPart(ID)
	parent:addChild(model:copy())
	parent:getChildren()[1]:setScale(1/math.worldScale)


	parallax.models[ID] = {
		model = model,
		parent = parent,
		roll = parent:getChildren()[1],
		offset = offset,
		rotation = rotation,
		displacement = displacement
	}

end

local lastScreen
local wardrobeScreen = "org.figuramc.figura.gui.screens.WardrobeScreen"
local avatarScreen = "org.figuramc.figura.gui.screens.AvatarScreen"
local permissionsScreen = "org.figuramc.figura.gui.screens.PermissionsScreen"

if host:isHost() then
	function events.world_render()
		local screen = host:getScreen()
		if (screen == wardrobeScreen) and (lastScreen ~= wardrobeScreen) and (lastScreen ~= avatarScreen)  then
			rotation = vectors.vec2(-15,30)
		end
		if (screen == permissionsScreen) and (lastScreen ~= permissionsScreen) and (lastScreen ~= avatarScreen)  then
			rotation = vectors.vec2(-15,30)
		end
		lastScreen = screen
		
		if mousePressed then
		local cursorChange = (client.getMousePos() - lastMousePos) * (1/3)
		rotation:add(vec(-cursorChange.y,cursorChange.x))
		end
	end
end

function events.render(delta,context)
	if context == "FIGURA_GUI" then
		parallax.backgroundParent:setVisible(true)
		parallax.modelParent:setVisible(true)
		vanilla_model.HELD_ITEMS:setVisible(false)
		for k,v in pairs(parallax.models) do
			v.model:setVisible(false)
		end
	else
		parallax.backgroundParent:setVisible(false)
		parallax.modelParent:setVisible(false)
		vanilla_model.HELD_ITEMS:setVisible(true)
		for k,v in pairs(parallax.models) do
			v.model:setVisible(true)
		end
		return
	end

	local windowSize = client.getWindowSize()
	if windowSize ~= lastWindowSize then
		rotation = vectors.vec2(-15,30)
	end
	local mousePos = client.getMousePos()
	local paralaxRot = (mousePos / windowSize):sub(vec(0.5,0.5))
	--mousePos:sub(vec(windowSize.x,windowSize.y))
	for k,v in pairs(parallax.backgrounds) do
		v.root:setRot(-paralaxRot.y * v.rotation,paralaxRot.x * v.rotation,0)
	end
	--models.model.Camera.background:setRot(-paralaxRot.y,paralaxRot.x,0)
	
	for k,v in pairs(parallax.models) do
		v.parent:setRot(rotation.x-paralaxRot.y * v.rotation,paralaxRot.x * v.rotation,0)
			:setPos(-paralaxRot.x * v.displacement,-paralaxRot.y * v.displacement,-v.offset)
		v.roll:setRot(0,rotation.y,0)
	end

	lastMousePos = mousePos
	lastWindowSize = windowSize
	

end


function events.mouse_press(key, isPressed)
	if key ~= 0 then return end
	if host:isHost() then
		local screen = host:getScreen()
		if (screen ~= wardrobeScreen) and (screen ~= permissionsScreen) and (screen ~= avatarScreen) then 
			mousePressed = false
			return
		end
	end
	if isPressed == 1 then
		mousePressed = true
	else
		mousePressed = false
	end
end


return parallax