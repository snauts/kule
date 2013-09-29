dofile("config.lua")
dofile("script/util.lua")
dofile("script/vector.lua")

camera     = nil
gameWorld  = nil
staticBody = nil

state = { progress = 1 }
if util.FileExists("saavgaam") then 
	dofile("saavgaam")
end
state.current = state.progress

util.Preload()
util.Goto("startup")
