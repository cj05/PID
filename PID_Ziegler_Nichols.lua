local ZN = {}

--creates a tuner, why in a different file? oop standard and also it was so messy before i cant debug
function ZN:Tuner(pid, wavethreshold, exitthreshold, callback, o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.threshold = wavethreshold or 5
  self.exit = exitthreshold or 1e-5
  self.pid = pid
  print("Setting Initial Parameters")
  local f = (callback or self.pid.reconfig)
  f(self.pid, 0, 0, 0)
  return o
end

--monitoring phase of the tuner
--you can also input in the error
--you can also input in a custom callback function for custom pids
--returns if it is finished or not
function ZN:Run(rate, previous_error, callback)
  local err = self.pid.previousErr or previous_error -- it pulls the pid's previous error or uses the given error

  self.ZN_history = self.ZN_history or {}
  self.ZN_peaks = self.ZN_peaks or {}
  self.rate = self.rate or rate

  --record ZN_history
  table.insert(self.ZN_history, err)

  self:update_peak(self.ZN_history, self.ZN_peaks)

  --stalled?
  if (self.ZN_history[#self.ZN_history] == self.ZN_history[#self.ZN_history - 1]) or #self.ZN_peaks > self.threshold then

    if #self.ZN_peaks > 1 then
      local lp = self.ZN_history[self.ZN_peaks[#self.ZN_peaks]]
      local fp = self.ZN_history[self.ZN_peaks[1]]
      local range = -(fp - lp) / math.sqrt(lp * lp + fp * fp)
      --print(range,lp)
      if range > self.exit then
        print("Threshold Has Been Exceeded, Exiting Data Collection")
        self.ZN_Result_Amplitude = self.max(self.ZN_history, self.ZN_peaks)
        self.ZN_Result_Period = self.ZN_peaks[#self.ZN_peaks] - self.ZN_peaks[#self.ZN_peaks - 1]
        return false
      end
    end
    print(#self.ZN_peaks, self.threshold)



    local carry = self.ZN_history[#self.ZN_history]
    for k, _ in pairs(self.ZN_peaks) do self.ZN_peaks[k] = nil end
    for k, _ in pairs(self.ZN_history) do self.ZN_history[k] = nil end
    self.ZN_history[1] = carry

    self:adjust(rate, callback)
  end
  return true
end

function ZN:adjust(offset, callback)
  local f = (callback or self.pid.reconfig)
  f(self.pid, self.pid.Kp + offset, 0, 0)
  print("Adjusted Kp Up", self.pid.Kp)
end

function ZN:update_peak(data, peaks)
  peaks = peaks or {}
  for i = (peaks[#peaks] or 1) + 1, #data - 1 do
    --print(data[i] , data[i - 1] , data[i + 1])
    if data[i] > data[i - 1] and data[i] > data[i + 1] then
      table.insert(peaks, i)
      print("Peak Found", i)
    end
  end
  return peaks
end

function ZN.max(data, peak)
  local max = data[peak[1]]
  for k, _ in pairs(peak) do
    max = math.max(max, data[peak[k]])
  end
  return max
end

function ZN:Variation(history, peak)
  local average = 0
  for k, _ in pairs(peak) do
    average = average + history(peak[k])
  end
  average = average / #peak
  local variation = 0
  for k, _ in pairs(peak) do
    local diff = (history(peak[k]) - average)
    variation = variation + diff * diff
  end
  return variation
end

--applies the tuner
--you can also input in a custom callback function for custom pids
function ZN:Apply(mode, callback) -- https://en.wikipedia.org/wiki/Ziegler%E2%80%93Nichols_method
  local weight_table = {
    ["P"] = { 0.5, 0, 0 },
    ["PI"] = { 0.45, 0.54, 0 },
    ["PD"] = { 0.8, 0, 0.1 },
    ["PID"] = { 0.6, 1.2, 0.075 },
    ["PESSEN-INTEGRAL"] = { 0.7, 1.75, 0.105 },
    ["SOME-OVERSHOOT"] = { 1 / 3, 2 / 3, 1 / 9 },
    ["NO-OVERSHOOT"] = { 0.2, 0.4, 1 / 15 },
  }
  local weights = weight_table[mode]
  local f = (callback or self.pid.reconfig)
  f(self.pid, weights[1] * self.ZN_Result_Amplitude,
    weights[2] * self.ZN_Result_Amplitude / self.ZN_Result_Period,
    weights[3] * self.ZN_Result_Amplitude * self.ZN_Result_Period)
end

ZN.mode = {
  ["P"] = "P",
  ["PI"] = "PI",
  ["PD"] = "PD",
  ["PID"] = "PID",
  ["PESSEN-INTEGRAL"] = "PESSEN-INTEGRAL",
  ["SOME-OVERSHOOT"] = "SOME-OVERSHOOT",
  ["NO-OVERSHOOT"] = "NO-OVERSHOOT",
}

return ZN
