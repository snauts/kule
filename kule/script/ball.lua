local fallSpeed = 96
local rollSpeed = 64

local function IsFalling(bead)
	return eapi.GetVel(bead.body).y ~= 0
end

local function IsRolling(bead)
	return eapi.GetVel(bead.body).x ~= 0
end

local function Sound(fileName, volume)
	eapi.PlaySound(gameWorld, fileName, 0, volume or 1)
end

local red = { r = 1.0, g = 0.0, b = 0.0 }
local sparkColor = { r = 1.0, g = 0.8, b = 0.0 }

local ballImg = actor.LoadSprite("image/ball.png", { 16, 16 })

local function Ball(pos)
	local obj = {
		class = "Ball",
		sprite = ballImg,
		offset = { x = -8, y = -8 },
		spriteSize = { x = 16, y = 16 },
		bb = actor.Square(1),
		pos = pos,
		z = -2,
	}
	obj = actor.Create(obj)
	eapi.SetVel(obj.body, { x = 0, y = -fallSpeed })
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 32, 0)
	kule.Push(obj, kule.elements)
	Sound("sound/thunk.ogg")
end

local function Drop()
	ball.DisableInput()
	local pos = eapi.GetPos(ball.cursor)
	Ball(vector.Offset(pos, 0, 24))
	eapi.Destroy(ball.cursor)
end

local function ForbiddenLeft(dir)
	return dir < 0 and ball.place == 1
end

local function ForbiddenRight(dir)
	return dir > 0 and ball.place == #ball.entries
end

local function Move(dir)
	return function()
		if ForbiddenLeft(dir) or ForbiddenRight(dir) then
			-- TODO: angry sound
		else
			Sound("sound/click.ogg")
			ball.place = ball.place + dir
			local cell = ball.entries[ball.place]
			eapi.SetPos(ball.cursor, kule.GetPos(cell))
		end
	end
end

local function Create(pos)
	local down = string.char(158)
	local offset = { x = -4, y = -4 }
	ball.cursor = eapi.NewBody(gameWorld, pos)
	util.PrintOrange(offset, down, nil, ball.cursor, 0.2)
	ball.EnableInput()
end

local function DisableInput()
	input.Bind("Drop")
	input.Bind("Left")
	input.Bind("Right")
end

local function EnableInput()
	input.Bind("Drop", false, util.KeyDown(Drop))
	input.Bind("Left", false, util.KeyDown(Move(-1)))
	input.Bind("Right", false, util.KeyDown(Move(1)))
end

local function Arm()
	if #ball.entries > 0 then
		local middle = math.floor((#ball.entries + 1) / 2)
		ball.place = ball.place or middle
		Create(kule.GetPos(ball.entries[ball.place]))
	end
end

local function MakeTurn(cell, store)
	local obj = {
		class = "Turn",
		bb = actor.Square(1),
		pos = kule.GetPos(cell),
		direction = kule.TurnSide(cell),
		offset = { x = -8, y = -8 },
		sprite = util.transparent,
		cell = cell,
	}
	kule.Push(actor.Create(obj), store)
end

local function BallTurn(bead, turn)
	eapi.SetPos(bead.body, eapi.GetPos(turn.body))
	eapi.SetVel(bead.body, { x = rollSpeed * turn.direction, y = 0 })
	if turn.direction == 0 then kule.Fail(bead) end
end

actor.SimpleCollide("Ball", "Turn", BallTurn, false)

local function SwitchTile(obj)
	eapi.SetFrame(obj.tile, (obj.direction > 0) and 0 or 1)
end

local gateImg = eapi.ChopImage("image/gate.png", { 16, 16 })

local function Switch(cell, direction)
	local obj = {
		class = "Switch",
		bb = actor.Square(1),
		pos = kule.GetPos(cell),
		offset = { x = -8, y = - 8 },
		direction = direction,
		sprite = gateImg,
		cell = cell,
	}
	obj = actor.Create(obj)
	SwitchTile(obj)
	return obj
end

local function SwitchDir(switch)
	return { x = switch.direction, y = 0 }
end

local function BallSwitch(bead, switch)
	if IsFalling(bead) then
		BallTurn(bead, switch)
		local pos = actor.GetPos(switch)
		switch.direction = -switch.direction
		sfx.SwitchFlop(pos, SwitchDir(switch), 90, sparkColor)
		Sound("sound/metal.ogg")
		SwitchTile(switch)
	end
end

actor.SimpleCollide("Ball", "Switch", BallSwitch, false)

local function MakeChute(cell, store)
	local obj = {
		class = "Chute",
		bb = actor.Square(1),
		pos = kule.GetPos(cell),
		offset = { x = -8, y = -8 },
		sprite = util.transparent,
	}
	kule.Push(actor.Create(obj), store)
end

local function BallChute(bead, turn)
	eapi.SetPos(bead.body, eapi.GetPos(turn.body))
	eapi.SetVel(bead.body, { x = 0, y = -fallSpeed })
end

actor.SimpleCollide("Ball", "Chute", BallChute, false)

local function Home(cell)
	local obj = {
		class = "Home",
		bb = actor.Square(1),
		pos = kule.GetPos(cell),
		sprite = util.defaultFontset.sprites,
		offset = { x = -4, y = - 8 },
		z = -5,
	}
	obj = actor.Create(obj)
	ball.homes = ball.homes + 1
	eapi.SetFrame(obj.tile, 414)
	return obj
end

local function RedSparks(pos)
	for i = 1, 10, 1 do
		sfx.SwitchFlop(pos, { x = 1, y = 0 }, 360, red)
	end
end

local function BallHome(bead, home)
	local pos = actor.GetPos(home)
	eapi.SetPos(bead.body, pos)
	eapi.SetVel(bead.body, vector.null)
	eapi.StopAnimation(bead.tile)
	actor.DeleteShape(bead)
	if not home.occupied then
		home.occupied = true
		ball.safe = ball.safe + 1
		sfx.HomeRays(pos)
		if ball.safe == ball.homes then
			Sound("sound/win.ogg")
			kule.Victory()
		else
			Sound("sound/ding.ogg")
			ball.Arm()
		end
	else
		Sound("sound/bang.ogg")
		RedSparks(pos)
		kule.Fail(bead)
	end
end

actor.SimpleCollide("Ball", "Home", BallHome, false)

ball = {
	Arm = Arm,
	Home = Home,
	Switch = Switch,
	MakeTurn = MakeTurn,
	MakeChute = MakeChute,
	EnableInput = EnableInput,
	DisableInput = DisableInput,
	homes = 0,
	safe = 0,
}
