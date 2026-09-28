"""Offline Lua 5.1 tests. Requires Python + lupa; never loaded by WoW."""
from pathlib import Path
import sys
if len(sys.argv) > 1:
    sys.path.insert(0, sys.argv[1])
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'tests' / 'wow_mock.lua').read_text(encoding='utf-8'))
lua.execute('A = {}')
files = [line.strip() for line in (root / 'FishinBuds.toc').read_text().splitlines() if line.endswith('.lua')]
for file in files:
    chunk = lua.eval('function(source, name) return assert(loadstring(source, name)) end')((root / file).read_text(encoding='utf-8'), '@' + file)
    chunk('FishinBuds', lua.globals().A)
scenarios = (root / 'tests' / 'scenarios.lua').read_text(encoding='utf-8')
# Exercise effects with the initialized v0.1 state, before event regression cases.
marker = "assert(A.Provider.Skill().bonus == 15)"
before, after = scenarios.split(marker, 1)
lua.execute(before + marker)
lua.execute((root / 'tests' / 'effects.lua').read_text(encoding='utf-8'))
lua.execute((root / 'tests' / 'tea.lua').read_text(encoding='utf-8'))
lua.execute(after)
snapshot = lua.eval('''function()
    local function encode(v)
        if type(v) == 'string' then return string.format('%q', v) end
        if type(v) ~= 'table' then return tostring(v) end
        local result = {'{'}
        for k, value in pairs(v) do result[#result+1] = '[' .. encode(k) .. ']=' .. encode(value) .. ',' end
        result[#result+1] = '}'
        return table.concat(result)
    end
    FishinBudsDB.schema = 1 -- prior test deliberately set the future-version guard
    return 'FishinBudsDB = ' .. encode(FishinBudsDB)
end''')()
reloaded = LuaRuntime(unpack_returned_tuples=True)
reloaded.execute((root / 'tests' / 'wow_mock.lua').read_text(encoding='utf-8'))
reloaded.execute(snapshot)
reloaded.execute('A = {}')
for file in files:
    chunk = reloaded.eval('function(source, name) return assert(loadstring(source, name)) end')((root / file).read_text(encoding='utf-8'), '@' + file)
    chunk('FishinBuds', reloaded.globals().A)
reloaded.execute('''
local saved = FishinBudsDB.characters['Player-1']
local total, recent, feed = saved.stats.catches, #saved.recent, #saved.feed
emit('ADDON_LOADED', 'FishinBuds')
assert(A.char.stats.catches == total and #A.char.recent == recent and #A.char.feed == feed)
assert(A.db.settings.autoShow == false and A.db.settings.warningSeconds == 60)
assert(A.db.characters['Player-2'].stats.catches == 0)
assert(type(A.db.settings.feedOnCast) == 'boolean')
print('SavedVariables serialization and fresh-runtime reload passed.')
''')
print(f'PASS: {len(files)} addon files loaded and all Lua 5.1 scenarios passed.')
