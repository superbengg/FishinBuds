local addonName, A = ...
A.name, A.version = addonName, '0.2.1'
A.listeners = {}
function A.On(event, fn)
    A.listeners[event] = A.listeners[event] or {}
    table.insert(A.listeners[event], fn)
end
function A.Emit(event, ...)
    for _, fn in ipairs(A.listeners[event] or {}) do fn(...) end
end
function A.Print(text) print('|cff71d5efFishin\' Buds:|r ' .. tostring(text)) end
function A.Debug(...)
    if not A.db or not A.db.settings.debug then return end
    local out = {}
    for i = 1, select('#', ...) do out[i] = tostring(select(i, ...)) end
    A.Print('[debug] ' .. table.concat(out, ' '))
end
function A.Public(v) return not (issecretvalue and issecretvalue(v)) end
function A.Safe(fn, ...)
    if type(fn) ~= 'function' then return nil end
    local result = { pcall(fn, ...) }
    if not result[1] then return nil end
    -- Callers needing tuples use pcall directly. No secret values escape here.
    if A.Public(result[2]) then return result[2] end
end
function A.Text(v) return A.Public(v) and type(v) == 'string' and v or nil end
function A.Number(v) return A.Public(v) and type(v) == 'number' and v or nil end
function A.Duration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return string.format('%d:%02d', math.floor(seconds / 60), seconds % 60)
end
function A.Trim(list, cap) while #list > cap do table.remove(list) end end
function A.Location()
    return A.Safe(GetZoneText) or 'Unknown waters', A.Safe(GetSubZoneText) or ''
end
function A.Refresh() A.Emit('REFRESH') end
