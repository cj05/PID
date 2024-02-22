local PID = {}

-- Creates a new PID instance
-- @param Kp (number) Proportional gain
-- @param Ki (number) Integral gain
-- @param Kd (number) Derivative gain
-- @param Imax (number) Maximum integral value
-- @param Imin (number) Minimum integral value
-- @param Iinit or 0 (number) Initial integral value
-- @param Errinit or 0 (number) Initial integral value
-- @param o or {} (table) Object to store PID values
function PID:new(Kp, Ki, Kd, Iinit, Errinit, Imax, Imin, o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.Kp = Kp or 0
  self.Ki = Ki or 0
  self.Kd = Kd or 0
  self.Iaccumulated = Iinit or 0
  self.previousErr = Errinit or 0
  self.Imax = Imax
  self.Imin = Imin
  return o
end

function PID:reconfig(Kp, Ki, Kd, Iinit, Errinit, Imax, Imin)
  self.Kp = Kp or self.Kp
  self.Ki = Ki or self.Ki
  self.Kd = Kd or self.Kd
  self.Iaccumulated = Iinit or self.Iaccumulated
  self.previousErr = Errinit or self.previousErr
  self.Imax = Imax or self.Imax
  self.Imin = Imin or self.Imin
end

function PID:update(setpoint, current, dt)
  local err = setpoint - current
  local P = err * self.Kp

  self.Iaccumulated = self.CalculateIntegral(err, self.Iaccumulated, dt)
  local Imaxclamped = self.Iaccumulated
  if self.Imax ~= nil then Imaxclamped = math.min(Imaxclamped, self.Imax) end
  local Iminclamped = Imaxclamped
  if self.Imin ~= nil then Iminclamped = math.max(Iminclamped, self.Imin) end
  self.Iaccumulated = Iminclamped
  local I = self.Iaccumulated * self.Ki



  local D = self.CalculateDerivative(err, self.previousErr, dt) * self.Kd
  self.previousErr = err

  return P + I + D
end

function PID.CalculateIntegral(err, accumulated, dt)
  return accumulated + err * dt
end

function PID.CalculateDerivative(err, previouserr, dt)
  return (err - previouserr) / dt
end

return PID
