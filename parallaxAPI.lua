--#REGION setup
if #models:getChildren() == 0 then error("parallax requires a model file to function") end

---@class parallaxAPI
---@field backgrounds table<string,parallaxBackground> Table containing all parallaxBackground objects.
---@field models table<string,parallaxModel> Table containing all parallaxModel objects.
---@field backgroundParent ModelPart *INTERNAL* Background root parent. Should be a camera type with the pivot offset by vec(0,17.05,0).
---@field modelParent ModelPart *INTERNAL* Bodel root parent. Should be a camera type with the pivot offset by vec(0,17.05,0).
local parallax = {
	backgrounds = {},
	models = {},
	backgroundParent = models:getChildren()[1]:newPart("parallaxBackgrounds","CAMERA"),
	modelParent = models:getChildren()[1]:newPart("parallaxModels","CAMERA")
}

-- pivot set
parallax.backgroundParent:setPivot(0,17.05,0)
parallax.modelParent:setPivot(0,17.05,0)
--#ENDREGION

--#REGION background functions
---@class parallaxBackground
---@field ID string Background's ID.
---@field root ModelPart Background's root parent.
---@field parent ModelPart Background's parent.
---@field sprite SpriteTask Background's sprite task.
---@field update function Updates the background sprite, applying texture, offset, scale, etc.
---@field remove function Removes the background.
---@field texture Texture The backgrond's texture.	
---@field rotateAmount number The background's rotation factor. How much it rotates from the mouse. Updates automatically. Default is 20.
---@field moveAmount number The background's movement factor. How much it moves from the mouse.  Updates automatically. Default is 0.
---@field offset number The background's offset away from the screen. Default is 5.
---@field uvScale number The background's UV size. Independent of scale. Default is 1.
---@field scale number  The background's total size. Independent of UV. Default is 1000.
---@field new function *INTERNAL* Returns a new background. Doesn't generate background model parts.
local parallaxBackground = {}
parallaxBackground.__index = parallaxBackground

function parallaxBackground:new(ID,root,parent,sprite,texture,rotateAmount,moveAmount,offset,uvScale,scale)
	local self = setmetatable({},parallaxBackground)
	self.ID = ID
	self.root = root
	self.parent = parent
	self.sprite = sprite
	self.texture = texture
	self.rotateAmount = rotateAmount
	self.moveAmount = moveAmount
	self.offset = offset
	self.uvScale = uvScale
	self.scale = scale
	return self
end

function parallaxBackground:update()
	local texture = self.texture
	local sprite = self.sprite
	if texture then
		local textureDem = texture:getDimensions()
		local scale = self.scale
		sprite:setTexture(texture,textureDem.x * scale,textureDem.y * scale)
			:setPos(textureDem.x/2 * scale, textureDem.y/2 * scale,0)

		local uvPos = (1/self.uvScale) * scale
		for index,vertex in pairs(sprite:getVertices()) do
			local xMod = math.floor((index)/2) % 2
			local yMod = math.floor((index+1)/2) % 2
			vertex:setUV(uvPos * xMod, uvPos * yMod)
		end
	else
		sprite:setTexture(texture,1,1)
	end
	local offset = self.offset
	self.parent:setPos(0,0,offset)
	return self
end

function parallaxBackground:remove()
	self.root:remove()
	parallax.backgrounds[self.ID] = nil
end

---@param ID string
---@param texture Texture
---@param rotateAmount number
---@param moveAmount number
---@param offset number
---@param uvScale number
---@param scale number
function parallax.newBackground(ID,texture,rotateAmount,moveAmount,offset,uvScale,scale)
	if parallax.backgrounds[ID] then error('background named "' .. ID .. '" already exists') end
	if not rotateAmount then rotateAmount = 20 end
	if not moveAmount then moveAmount = 0 end
	if not offset then offset = 5 end
	if not uvScale then uvScale = 1 end
	if not scale then scale = 1000 end

	local root = parallax.backgroundParent:newPart(ID)
	local parent = root:newPart("parent")
	local sprite = parent:newSprite(ID)

	local parallaxBackground = parallaxBackground:new(ID,root,parent,sprite,texture,rotateAmount,moveAmount,offset,uvScale,scale)
	parallax.backgrounds[ID] = parallaxBackground
	parallaxBackground:update()
	return parallaxBackground
end
--#ENDREGION

--#REGION model functions
---@class parallaxModel
---@field ID string Background's ID.
---@field origional ModelPart The model part provided when the paralaxModel was created.
---@field parent ModelPart Model's parent.
---@field roll ModelPart The model. Used in model roll.
---@field remove function Removes the model.
---@field rotateAmount number Model's rotation factor. How much it rotates from the mouse. Default is 20.
---@field moveAmount number Model's movement factor. How much in moves from the mouse. Default is 0.
---@field offset number Model's offset away from the screen. Default is 100.
local parallaxModel = {}
parallaxModel.__index = parallaxModel

function parallaxModel:new(ID,origional,parent,roll,offset,rotateAmount,moveAmount)
	local self = setmetatable({},parallaxModel)
	self.ID = ID
	self.origional = origional
	self.parent = parent
	self.roll = roll
	self.offset = offset
	self.rotateAmount = rotateAmount
	self.moveAmount = moveAmount
	return self
end

function parallaxModel:remove()
	self.origional:setVisible(true)
	self.parent:remove()
	parallax.models[self.ID] = nil
end

---@param ID string
---@param model ModelPart
---@param rotateAmount number
---@param moveAmount number
---@param offset number
function parallax.addModel(ID,model,rotateAmount,moveAmount,offset)
	if parallax.models[ID] then error('model named "' .. ID .. '" already exists') end
	if not rotateAmount then rotateAmount = 20 end
	if not moveAmount then moveAmount = 0 end
	if not offset then offset = 100 end
	local parent =  parallax.modelParent:newPart(ID)
	parent:addChild(model:copy())
	parent:getChildren()[1]:setScale(1/math.worldScale)
	local roll = parent:getChildren()[1]
	local parallaxModel = parallaxModel:new(ID,model,parent,roll,offset,rotateAmount,moveAmount)
	parallax.models[ID] = parallaxModel
	return parallaxModel
end
--#ENDREGION

--#REGION host only
local lastScreen
local wardrobeScreen = "org.figuramc.figura.gui.screens.WardrobeScreen"
local avatarScreen = "org.figuramc.figura.gui.screens.AvatarScreen"
local permissionsScreen = "org.figuramc.figura.gui.screens.PermissionsScreen"
local mousePressed = false
local lastMousePos = client.getMousePos()

local modelRot = vectors.vec2(-15,30)
local lastWindowSize = client.getWindowSize()

if host:isHost() then
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

	function events.world_render()
		local screen = host:getScreen()
		if (screen == wardrobeScreen) and (lastScreen ~= wardrobeScreen) and (lastScreen ~= avatarScreen)  then
			modelRot = vectors.vec2(-15,30)
		end
		if (screen == permissionsScreen) and (lastScreen ~= permissionsScreen) and (lastScreen ~= avatarScreen)  then
			modelRot = vectors.vec2(-15,30)
		end
		lastScreen = screen

		if mousePressed then
			local cursorChange = (client.getMousePos() - lastMousePos) * (1/3)
			modelRot:add(vec(-cursorChange.y,cursorChange.x))
		end
	end
end
--#ENDREGION

--#REGION render
function events.render(delta,context)
	if context == "FIGURA_GUI" then
		parallax.backgroundParent:setVisible(true)
		parallax.modelParent:setVisible(true)
		vanilla_model.HELD_ITEMS:setVisible(false)
		for k,v in pairs(parallax.models) do
			v.origional:setVisible(false)
		end
	else
		parallax.backgroundParent:setVisible(false)
		parallax.modelParent:setVisible(false)
		vanilla_model.HELD_ITEMS:setVisible(true)
		for k,v in pairs(parallax.models) do
			v.origional:setVisible(true)
		end
		return
	end

	local windowSize = client.getWindowSize()
	if windowSize ~= lastWindowSize then
		modelRot = vectors.vec2(-15,30)
	end
	local mousePos = client.getMousePos()
	local paralaxRot = (mousePos / windowSize):sub(vec(0.5,0.5))
	for k,v in pairs(parallax.backgrounds) do
		v.root:setRot(-paralaxRot.y * v.rotateAmount,paralaxRot.x * v.rotateAmount,0)
			:setPos(-paralaxRot.x * v.moveAmount,-paralaxRot.y * v.moveAmount,-v.offset)
	end

	for k,v in pairs(parallax.models) do
		v.parent:setRot(modelRot.x-paralaxRot.y * v.rotateAmount,paralaxRot.x * v.rotateAmount,0)
			:setPos(-paralaxRot.x * v.moveAmount,-paralaxRot.y * v.moveAmount,-v.offset)
		v.roll:setRot(0,modelRot.y,0)
	end

	lastMousePos = mousePos
	lastWindowSize = windowSize
end

return parallax