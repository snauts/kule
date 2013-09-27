-- Program configuration.

local eapi = eapi or { }

Cfg = {
        name = "Kule",
	version = "devel",

	-- Display.
	fullscreen	= true,
	windowWidth	= 320,
	windowHeight	= 240,
	screenBPP	= 0,
	
	-- Sound.
	channels	= 16,
	frequency	= 22050,
	chunksize	= 512,
	stereo		= true,

	-- Debug things.
	debug		= false,
	useDesktop	= true,
	screenWidth	= 320,
	screenHeight	= 240,
	printExtensions = false,
	FPSUpdateInterval = 1000,
	gameSpeed = 0,
        defaultShapeColor = {r=0,g=1,b=0},

	-- Default control scheme: actions mapped to keys.
	controls = {
		Left  = { "Left",  "Joy0 A0-", "Joy0 B1004" },
		Right = { "Right", "Joy0 A0+", "Joy0 B1002" },

		Drop  = { "Space", "Z", "X", "Joy0 B1" },
		Quit  = { "Escape", "Joy0 B7" },
	},

        -- Engine config.
        poolsize = {
                world      = 12,
                body       = 4000,
                tile       = 4000,
                shape      = 4000,
                group      = 100,
                camera     = 10,
                texture    = 100,
                spritelist = 200,
                sound      = 100,
                music      = 10,
                timer      = 4000,
                gridcell   = 50000,
                property   = 20000,
                collision  = 1000
        },
        collision_dist = 1,
        cam_vicinity_factor = 0.5
}

return Cfg
