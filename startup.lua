local PID = require("PID")
local PIDtuner = require("PID_Ziegler_Nichols")

local pidcontroller = PID:new(0, 0, 0, 0, 0, 5,5)

pprint = require("cc.pretty").pretty_print

local controller = peripheral.find("shipControlInterface")
    
function applyForces(a)
    --print(controller)
    local engines = {peripheral.find("kontraption:ion_thruster")}
    local mass = controller.getWeight()
    --print(#engines) 
    local thrustperengine = 100000
    local gravity = 10
    local maxThrust = thrustperengine * #engines
    --pprint(maxThrust)
    local targetThrust = (a+gravity)*mass
    local thrustratio = targetThrust / maxThrust
    controller.setMovement(0,thrustratio,0)
    --pprint(thrustratio)
end 

-- autotune

local setpoint = 1

local soffset = controller.getPosition()

local loop = true

local wavethreshold = 2 

local exitthreshold = 1e-5

local rate = 0.2
local start = 1
local deltatime = 0.05
print("Autotuning")

local tuner = PIDtuner:Tuner(pidcontroller,start, wavethreshold,exitthreshold)
local aoffset = 0
while loop ~= false do
    
    local position = controller.getPosition()
    local o
    a = pidcontroller:update(setpoint, position.y-soffset.y-aoffset, deltatime)
    loop,o = tuner:Run(rate,setpoint)
    if o~= 0 then print(aoffset+o) end
    --saoffset = aoffset+o
    --pprint(a)
    applyForces(a)
    sleep(deltatime)
end
tuner:Apply(tuner.mode.PD,deltatime)
print("Autotuned : ",pidcontroller.Kp,pidcontroller.Ki,pidcontroller.Kd)

setpoint = 0


--time to vibe with pid
term.clear()
while true do
    local position = controller.getPosition()
    local a = pidcontroller:update(setpoint,position.y,deltatime)
    applyForces(a)
    term.setCursorPos(0,1)
    print(" ")
    print("Setpoint: ",setpoint)
    print("Current : ",position.y)
    print("Output  : ",a)
    print("Autotuned : ", pidcontroller.Kp, pidcontroller.Ki, pidcontroller.Kd)--
    sleep(deltatime)
end
