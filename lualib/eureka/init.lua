local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 8)

_M._VERSION = '0.0.1'

local mt = { __index = _M }

function _M.new(self)
    return setmetatable({}, mt)
end

return _M