vanilla_model.PLAYER:setVisible(false)

local parallax = require("parallaxAPI")
parallax.newBackground("test",textures["model.Skin"],50,0,5,0.5,100)
parallax.newBackground("test2",textures["model.Skin"],50,0,10,1,100)
parallax.addModel("bawa",models.model.root,10,0,100)