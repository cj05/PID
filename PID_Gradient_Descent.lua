local GD = {}

--wip btw
function GD:Tuner(pid, callback, o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.pid = pid
  print("Setting Initial Parameters")
  (callback or self.pid.reconfig)(self.pid, 0, 0, 0)
  return o
end

return GD
