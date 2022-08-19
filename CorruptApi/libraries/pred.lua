---@class pred
local pred = {}

---@param target aiBaseClient
---@param input table
---@param return_always boolean
---@overload fun(target:aiBaseClient, input:table):predResult
---@return predResult
function pred.getPrediction(target, input, return_always) end

---@param target aiBaseClient
---@param time number
---@return vec3
function pred.positionAfterTime(target, time) end

---@type pred
_G.pred = {}



