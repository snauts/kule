dofile("script/levels.lua")
dofile("script/ball.lua")
dofile("script/sfx.lua")

local CHAR_SPACE = 32
local CHAR_HASH  = 35
local CHAR_LEFT  = 60
local CHAR_RIGHT = 62
local CHAR_HOME  = 120

local function Pos(size, x)
	return size / 2 - (x - 0.5) * 16
end

local function GetPos(cell)
	return { x = -Pos(320, cell.i) + 8, y = Pos(240, cell.j) - 8 }
end

local function IsValid(cell)
	return cell.j >= 1 and cell.j <= #cell.level
           and cell.i >= 1 and cell.i <= #cell.level[cell.j]
end

local function Contents(cell)
	return string.byte(cell.level[cell.j], cell.i)
end

local function Cell(cell)
	return IsValid(cell) and Contents(cell) or CHAR_SPACE
end

local function Offset(cell, pos)
	return { level = cell.level, i = cell.i + pos.x, j = cell.j - pos.y }
end

local function Left(cell)
	return Offset(cell, { x = -1, y = 0 })
end

local function Right(cell)
	return Offset(cell, { x = 1, y = 0 })
end

local function Up(cell)
	return Offset(cell, { x = 0, y = 1 })
end

local function Down(cell)
	return Offset(cell, { x = 0, y = -1 })
end

local function IterateLevel(level, Fn)
	for j = 1, #level, 1 do
		for i = 1, #level[j], 1 do
			Fn({ level = level, i = i, j = j })
		end
	end
end

local function FirstLine(cell)
	return cell.j == 1
end

local function IsEmpty(cell)
	return Cell(cell) == CHAR_SPACE
end

local function IsWall(cell)
	return Cell(cell) == CHAR_HASH
end

local function IsEntry(cell)
	return IsEmpty(cell) and FirstLine(cell)
end

local function IsHome(cell)
	return Cell(cell) == CHAR_HOME
end

local function IsLeftSwitch(cell)
	return Cell(cell) == CHAR_LEFT
end

local function IsRightSwitch(cell)
	return Cell(cell) == CHAR_RIGHT
end

local function IsBottom(cell)
	return IsEmpty(cell) and IsEmpty(Up(cell)) and IsWall(Down(cell))
end

local function IsFallingSpot(cell)
	return IsEmpty(Left(cell)) or IsEmpty(Right(cell)) or IsWall(Up(cell))
end

local function NoFloor(cell)
	return IsEmpty(Down(cell)) or IsHome(Down(cell))
end

local function IsChute(cell)
	return IsEmpty(cell) and NoFloor(cell) and IsFallingSpot(cell)
end

local function ShadowPos(cell, pos)
	return vector.Offset(GetPos(cell), pos.x * 8, pos.y * 8)
end

local function Push(item, store)
	store[#store + 1] = item
end

local function WallTile(store, item, offset, size, color, z)
	item.body = eapi.NewBody(gameWorld, item.pos)
	item.tile = eapi.NewTile(item.body, offset, size, util.white, z)
	eapi.SetColor(item.tile, util.Gray(color))
	Push(item, store)
end

local function Shadow(store, cell, pos, color, z)
	local function Border(lo, hi)
		return function(i) return i ~= 0 and lo or hi end
	end
	if not IsWall(Offset(cell, pos)) then
		local size = util.Map(Border(2, 16), pos)
		local offset = util.Map(Border(-1, -8), pos)
		local item = { pos = ShadowPos(cell, pos) }
		WallTile(store, item, offset, size, color, z)
	end
end

local function Wall(store, cell, color)
	local size = { x = 16, y = 16 }
	local offset = { x = -8, y = -8 }
	local item = { pos = GetPos(cell) }
	WallTile(store, item, offset, size, color, 0)
end

local function InsertWall(cell, store)
	Wall(store, cell, 0.6)

	Shadow(store, cell, { x =  1, y =  0 }, 0.8, 2)
	Shadow(store, cell, { x = -1, y =  0 }, 0.4, 1)
	Shadow(store, cell, { x =  0, y =  1 }, 0.8, 2)
	Shadow(store, cell, { x =  0, y = -1 }, 0.4, 1)
end

local function Switch(cell, direction, store)
	Push(ball.Switch(cell, direction), store)
end

local function MakeHome(cell, store)
	Push(ball.Home(cell), store)
end

local function When(Check, cell, Insert, ...)
	if Check(cell) then Insert(cell, ...) end
end

local function Generate(level)
	local store = { }
	ball.entries = { }
	local function Draw(cell)
		When(IsWall, cell, InsertWall, store)
		When(IsEntry, cell, Push, ball.entries)
		When(IsLeftSwitch, cell, Switch, -1, store)
		When(IsRightSwitch, cell, Switch, 1, store)
		When(IsBottom, cell, ball.MakeTurn, store)
		When(IsChute, cell, ball.MakeChute, store)
		When(IsHome, cell, MakeHome, store)
	end
	IterateLevel(level, Draw)
	return store
end

local function Displace(item)
	local angle = math.random(-30, 30)
	local pos = eapi.GetPos(item.body)
	local displace = { x = 0, y = 300 }
	displace = vector.Rotate(displace, angle)
	pos = vector.Add(pos, displace)
	eapi.SetPos(item.body, pos)
	item.displace = displace
end

local function Stop(item)
	eapi.SetVel(item.body, vector.null)
	eapi.SetAcc(item.body, vector.null)
	eapi.SetPos(item.body, item.pos)
        eapi.SetAngle(item.tile, 0)
end

local function GoIntoPlace(item)
	util.RotateTile(item.tile, math.random(-360, 360))
	eapi.AnimateAngle(item.tile, eapi.ANIM_CLAMP, vector.null, 0, 1, 0)
	eapi.SetVel(item.body, vector.Scale(item.displace, -2))
	eapi.SetAcc(item.body, vector.Scale(item.displace, 2))
	util.Delay(item.body, 1, Stop, item)
end

local function CrumbleItem(item)
	local angle = -0.2 * item.pos.x
	eapi.SetAcc(item.body, vector.Rotate({ x = 0, y = -480 }, angle))
end

local function Rank(item)
	return item.pos.x + 320 * item.pos.y
end

local function Test(itemA, itemB)
	return Rank(itemA) < Rank(itemB)
end

local function Arrive(level)
	local duration = 2
	local store = Generate(level)
	util.Map(Displace, store)
	table.sort(store, Test)
	for i = 1, #store, 1 do
		local item = store[i]
		local delay = duration * i / #store
		util.Delay(item.body, delay, GoIntoPlace, item)
	end
	eapi.PlaySound(gameWorld, "sound/arrive.ogg", 0, 1)
	eapi.AddTimer(staticBody, duration + 1, ball.Arm)
	kule.elements = store
end

local function TurnSide(cell)
	local left = IsWall(Left(cell))
	local right = IsWall(Right(cell))
	return (left and 1 or 0) + (right and -1 or 0)
end

local function RandomVector()
	return vector.Rotate({ x = 1, y = 0 }, math.random(0, 359))
end

local function Explode(center)
	return function(item)
		local speed = 200 + 50 * math.random()
		local vel = vector.Sub(eapi.GetPos(item.body), center)
		if vector.Length(vel) == 0 then vel = RandomVector() end
		eapi.SetVel(item.body, vector.Normalize(vel, speed))
		util.AnimateRotation(item.tile, 0.25 * (1 + math.random()))
	end
end

local function Start(map)
	if not map then
		util.Goto("startup")
	else
		Arrive(map)
	end
end

local function Reset()
	ball.safe = 0
	ball.homes = 0
	ball.place = nil
	util.Map(actor.Delete, kule.elements)
	Start(levels[state.current].map)
end

local function Fail(center)
	util.Map(Explode(eapi.GetPos(center.body)), kule.elements)
	eapi.AddTimer(staticBody, 2, Reset)
end

local function StopText(body)
	local function ScrollAway()
		input.Bind("Drop")
		util.DelayedDestroy(body, 1)
		eapi.SetAcc(body, { x = 0, y = -512 })
		Reset()
	end
	input.Bind("Drop", false, util.KeyDown(ScrollAway))
	eapi.SetVel(body, vector.null)
	eapi.SetAcc(body, vector.null)
	eapi.SetPos(body, vector.null)
end

local function RemoveGibberish(gibberish)
	local function Remove() util.Map(actor.Delete, gibberish) end
	eapi.AddTimer(staticBody, 1.0, Remove)
	kule.elements = nil
end

local function DrawBox(body, offset, size, color, z)
	local tile = eapi.NewTile(body, offset, size, util.white, z)
	eapi.SetColor(tile, util.Gray(color))
end

local function TextBox(body)
	DrawBox(body, { x = -154, y = -14 }, { x = 308, y = 28 }, 0.25, 80)
	DrawBox(body, { x = -152, y = -12 }, { x = 304, y = 24 }, 0.20, 90)
	DrawBox(body, { x = -154, y = -14 }, { x = 306, y = 26 }, 0.15, 85)
end

local function AdvanceLevel()
	local text = util.ConvertString(levels[state.current].motd)
	local body = eapi.NewBody(gameWorld, { x = 0, y = 256 })
	util.PrintOrange(util.TextCenter(text), text, nil, body, 0.0)
	util.Delay(body, 1, StopText, body)
	eapi.SetVel(body, { x = 0, y = -512 })
	eapi.SetAcc(body, { x = 0, y = 512 })
	RemoveGibberish(kule.elements)
	TextBox(body)
end

local function CrumbleAway()
	local store = kule.elements
	for i = 1, #store, 1 do
		local item = store[i]
		local delay = 0.5 * i / #store
		util.Delay(item.body, delay, CrumbleItem, item)
	end
end

local function Spin(item)
	util.AnimateRotation(item.tile, 0.2 * (1 + math.random()))
end

local function DoTheSpin()
	util.Map(Spin, kule.elements)
end

local function UpdateProgress()
	state.current = state.current + 1
	state.progress = math.max(state.progress, state.current)
        local saveFile = io.open("saavgaam", "w")
        if saveFile then
		saveFile:write("state.progress = " .. state.progress .. "\n")
		io.close(saveFile)
        end
end

local function Victory()
	UpdateProgress()
	util.DoEventsRelative({ { 0.0, sfx.Rainbow },
				{ 1.0, DoTheSpin },
				{ 1.0, CrumbleAway },
				{ 1.0, AdvanceLevel } })
end

kule = {
	TurnSide = TurnSide,
	Victory = Victory,
	GetPos = GetPos,
	Push = Push,
	Fail = Fail,
}

AdvanceLevel()
