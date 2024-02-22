local PID = require("PID")
local PIDtuner = require("PID_Ziegler_Nichols") -- Ziegler-Nichols algorithm for automatic pid tuning https://en.wikipedia.org/wiki/Ziegler%E2%80%93Nichols_method

local controller = PID:new(0, 0, 0, 0, 0, 5, 5) -- it doesnt care about starting coef

--crude simulation init
local timewarp = 100 -- incase you wanna speed things up as its pretty slow
local s = 0
local v = 0
local a = 0
local frametime = 1 / 20
local g = 9.86
local mft = 20
local mbt = -20
-- so its realtime in minecraft as cc, aka 20 ticks a second
function sleep(n)
  local t = os.clock()
  while os.clock() - t <= n do
    -- nothing
  end
end

---auto tuning using Ziegler-Nichols algorithm, this gives a decent estimate of the values
local setpoint = 1
local offset = 0
local loop = true
local wavethreshold = 5 -- how many peaks to wait for before changing the tune sampler param
local exitthreshold = 1e-5 -- how high the threshold is to exit the loop
local rate = 0.1 -- rate of change of the PID
print("Autotuning")

local tuner = PIDtuner:Tuner(controller, rate, wavethreshold, exitthreshold)
--create a tuner wrapping the PID
while loop ~= false do
  --v = v * 0.99
  v = v + (a - g) * frametime
  s = s + v * frametime
  --s = math.max(s, 0) -- the ground
  --if(s == 0) then v = 0 end
  --your average physics ticking equation
  a = controller:update(setpoint, s - offset, frametime) + g
  a = math.min(math.max(a, mbt), mft)
  --print(s)
  --updates the PID
  local o
  loop, o = tuner:Run(rate, setpoint)
  offset = o + offset
  --runs the tuner sampler
  sleep(frametime / timewarp)
end
tuner:Apply(tuner.mode.PID, frametime) --look into ziegler file to see what can be used
--apply tuner
print("Autotuned : ", controller.Kp, controller.Ki, controller.Kd)
--test results

---pid usage timeeee
setpoint = 100
local timewarp = 1
count = 0
while s < 1e2 * setpoint do
  v = v + (a - g) * frametime
  s = s + v * frametime
  s = math.max(s, 0) -- the ground
  if (s == 0) then v = 0 end

  output = controller:update(setpoint, s, frametime)
  a = output + g
  --print(a)
  a = math.min(math.max(a, mbt), mft)
  print(s, setpoint, output)
  sleep(frametime / timewarp)
  --if count % 60/frametime == 0 then setpoint = setpoint + math.random(-10,10) end
  count = count + 1
end
