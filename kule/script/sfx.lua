local speed = 0.1

local rainbow = {
	{ r = 1.00, g = 0.00, b = 0.00, a = 1.0 },
	{ r = 1.00, g = 0.50, b = 0.00, a = 1.0 },
	{ r = 1.00, g = 1.00, b = 0.00, a = 1.0 },
	{ r = 0.00, g = 1.00, b = 0.00, a = 1.0 },
	{ r = 0.00, g = 1.00, b = 1.00, a = 1.0 },
	{ r = 0.00, g = 0.00, b = 1.00, a = 1.0 },
	{ r = 0.40, g = 0.10, b = 0.20, a = 1.0 },
}

local function Distance(item)
	return 1.0 - vector.Length(actor.GetPos(item)) / 192.0
end

local function GetColor(index)
	return rainbow[(math.floor(index)) % #rainbow + 1]
end

local function MoveColor(item, adjust)
	local index = Distance(item) * #rainbow + adjust
	local final = util.Mix(GetColor(index), GetColor(index + 1), index % 1)
	eapi.AnimateColor(item.tile, eapi.ANIM_CLAMP, final, speed, 0)
end

local function Rainbow()
	local adjust = 0
	local store = kule.elements
	local function Cycle()
		for i = 1, #store, 1 do
			MoveColor(store[i], adjust)
		end
		eapi.AddTimer(store[1].body, speed, Cycle)
		adjust = adjust + 1
	end
	Cycle()	
end

local sparkSize = { x = 16, y = 4 }
local sparkPos = { x = -8, y = -2 }
local sparkColor = { r = 1.0, g = 0.8, b = 0, a = 0.5 }
local sparkFade = { r = 1.0, g = 0.8, b = 0, a = 0.0 }
local sparkLife = 0.5

local function FadeSpark(tile, color)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, sparkLife, 0)
end

local function Spark(pos, dir, spread, sparkColor, fadeColor)
	local speed = math.random(100, 200)
	local body = eapi.NewBody(gameWorld, pos)
	local angle = math.random(-0.5 * spread, 0.5 * spread)
	local tile = eapi.NewTile(body, sparkPos, sparkSize, util.rhombus, 10)
	eapi.SetVel(body, vector.Normalize(vector.Rotate(dir, angle), speed))
	util.DelayedDestroy(body, sparkLife)
	eapi.SetColor(tile, sparkColor)
	util.RotateTile(tile, angle)
	FadeSpark(tile, fadeColor)
end

local function CopyColor(color, alpha)
	return util.SetColorAlpha(util.Map(util.Identity, color), alpha)
end

local function SwitchFlop(pos, dir, spread, color)
	local sparkFade = CopyColor(color, 0.0)
	local sparkColor = CopyColor(color, 0.5)

	for i = 1, 10, 1 do
		Spark(pos, dir, spread, sparkColor, sparkFade)
	end
end

local rayLife = 0.25
local raySize = { x = 2, y = 2 }
local rayOffset = { x = 0, y = -1 }
local rayDstSize = { x = 256, y = 64 }
local rayDstOffset = { x = 0, y = -32 }

local function FadeRay(tile)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, rayLife, 0)
end

local function Ray(body, angle)
	local tile = eapi.NewTile(body, rayOffset, raySize, util.triangle, 10)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, rayDstOffset, rayLife, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, rayDstSize, rayLife, 0)
	eapi.SetColor(tile, util.Gray(1.0))
	util.AnimateRotation(tile, 2, angle)
	FadeRay(tile)
end

local function HomeRays(pos)
	local body = eapi.NewBody(gameWorld, pos)
	util.DelayedDestroy(body, rayLife)
	for angle = 0, 359, 30 do
		Ray(body, angle)
	end
end

sfx = {
	Rainbow = Rainbow,
	HomeRays = HomeRays,
	SwitchFlop = SwitchFlop,
}
