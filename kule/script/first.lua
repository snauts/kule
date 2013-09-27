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

util.Preload()
util.Goto("startup")
