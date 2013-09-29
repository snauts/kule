local function Info()
	local border = 4
	local text = {
		"KULE was a Polish game for ZX Spectrum.", 
		"It had a profound influence on me when",
		"I was a kid. This game formed my belief",
		"that world is totally deterministic.",
	}
	for i = 1, #text, 1 do
		local pos = { x = -160 + border, y = 120 - i * 16 - border }
		util.PrintOrange(pos, text[i], nil, nil, 0.2)
	end
end

local function Half(x)
	return 0.5 * x
end

local function Dim(tile)
	eapi.SetColor(tile, util.Map(Half, eapi.GetColor(tile)))
end

local function Blink(tile)
	local color = util.Map(Half, eapi.GetColor(tile))
	eapi.AnimateColor(tile, eapi.ANIM_REVERSE_LOOP, color, 0.1, 0)
end

local function Help()
	local text = "Press SPACE to start game!"
	local pos = util.TextCenter(text)
	util.Map(Blink, util.PrintOrange(pos, text, nil, nil, 0.2))

	local text = "Use ESC to exit game."
	local pos = vector.Offset(util.TextCenter(text), 0, -16)
	util.Map(Dim, util.PrintOrange(pos, text, nil, nil, 0.2))
end

local function AppendHelp(text)
	if state.progress > 1 then
		return text .. " (use " .. actor.arrows .. " to select)"
	else
		return text
	end
end

local tiles = { }
local function Level(num)
	if num >= 1 and num <= state.progress then
		local pos = { x = -156, y = -120 }
		local text = "Level:" .. num
		text = AppendHelp(text)
		util.Map(eapi.Destroy, tiles)
		tiles = util.PrintOrange(pos, text, nil, nil, 0.2)
		state.current = num
	end
end

local function Select(dir)
	return function() Level(state.current + dir) end
end

input.Bind("Left", false, util.KeyDown(Select(-1)))
input.Bind("Right", false, util.KeyDown(Select(1)))

input.Bind("Drop", false, util.KeyDown(function() util.Goto("kule") end))

Level(state.current)
Help()
Info()
