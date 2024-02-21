local PID = require("PID")
local PIDtuner = require("PID_Ziegler_Nichols") -- Ziegler-Nichols algorithm for automatic pid tuning https://en.wikipedia.org/wiki/Ziegler%E2%80%93Nichols_method

local controller = PID:new(0, 0, 0) -- it doesnt care about starting coef

--crude simulation init
local timewarp = 100 -- incase you wanna speed things up as its pretty slow
local s = 0
local v = 0
local a = 0
local frametime = 1/20
-- so its realtime in minecraft as cc, aka 20 ticks a second
function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do
    -- nothing
  end
end

---auto tuning using Ziegler-Nichols algorithm, this gives a decent estimate of the values
local setpoint = 1 -- this should be 1.... changing it breaks the tuning for some reason
local loop = true
local wavethreshold = 5 -- how many peaks to wait for before changing the tune sampler param
local exitthreshold = 1e-5 -- how high the threshold is to exit the loop
local rate = 0.1 -- rate of change of the PID
print("Autotuning")

local tuner = PIDtuner:Tuner(controller, wavethreshold,exitthreshold)
--create a tuner wrapping the PID
while loop ~= false do
  v = v + a * frametime
  s = s + v * frametime
  --your average physics ticking equation
  a = controller:update(setpoint, s, frametime)
  --updates the PID
  loop = tuner:Run(rate)
  --runs the tuner sampler
  sleep(frametime / timewarp)
end
tuner:Apply(tuner.mode.PID)--look into ziegler file to see what can be used
--apply tuner
print("Autotuned : ",controller.Kp,controller.Ki,controller.Kd)
--test results

---pid usage timeeee
setpoint = 10000
local timewarp = 1 
count = 0
while s < 1e2*setpoint do
  v = v + a * frametime
  s = s + v * frametime
  a = controller:update(setpoint, s, frametime)
  print(s, setpoint)
  sleep(frametime / timewarp)
  if count % 60/frametime == 0 then setpoint = setpoint + math.random(-1000,1000) end
  count = count + 1
end
