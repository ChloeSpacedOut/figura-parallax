vanilla_model.PLAYER:setVisible(false)

local parallax = require("parallaxAPI")
parallax.newBackground("background",textures["model.Skin"],50,0,5,0.5,100)
parallax.newBackground("background2",textures["model.Skin"],50,0,10,1,100)
parallax.addModel("model",models.model.root,10,0,100)