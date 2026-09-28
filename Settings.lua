local _, A = ...
A.Settings = {}
function A.Settings.Build()
    local U = A.UI
    local f = U.Panel(UIParent, 365, 420)
    A.Settings.frame = f
    f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG'); f:SetClampedToScreen(true)
    local title = U.Label(f, 'GameFontNormalLarge', 320)
    title:SetPoint('TOPLEFT', 18, -18); title:SetText("Fishin' Buds settings")
    local close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT', -3, -3); close:SetScript('OnClick', function() f:Hide() end)
    A.Settings.checks = {}
    for i, entry in ipairs({{'autoShow', 'Open while fishing'}, {'autoHide', 'Tuck away after fishing'},
        {'feedOnCast', 'Switch to Feed on every cast'}, {'celebrations', 'Celebrate catches and trophies'}, {'debug', 'Debug messages'}}) do
        local key = entry[1]
        local b = CreateFrame('CheckButton', nil, f, 'UICheckButtonTemplate')
        b:SetPoint('TOPLEFT', 17, -45 - (i - 1) * 34)
        local label = U.Label(b, nil, 290); label:SetPoint('LEFT', b, 'RIGHT', 2, 0); label:SetText(entry[2])
        b:SetScript('OnClick', function(self) A.db.settings[key] = self:GetChecked() == true end)
        A.Settings.checks[key] = b
    end
    local label = U.Label(f, nil, 315); label:SetPoint('TOPLEFT', 20, -224); label:SetText('Hide after (30-600 seconds)')
    local box = CreateFrame('EditBox', nil, f, 'InputBoxTemplate')
    box:SetSize(75, 26); box:SetPoint('TOPLEFT', 24, -247); box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(3)
    A.Settings.timeout = box
    local apply = U.Button(f, 'Apply', 72, function()
        local value = tonumber(box:GetText())
        if value then A.db.settings.idleSeconds = math.max(30, math.min(600, math.floor(value))) end
        box:SetText(tostring(A.db.settings.idleSeconds)); box:ClearFocus()
    end)
    apply:SetPoint('LEFT', box, 'RIGHT', 12, 0)
    local warningLabel = U.Label(f, nil, 315); warningLabel:SetPoint('TOPLEFT', 20, -288); warningLabel:SetText('Consumable warning (15-300 seconds)')
    local warning = CreateFrame('EditBox', nil, f, 'InputBoxTemplate')
    warning:SetSize(75, 26); warning:SetPoint('TOPLEFT', 24, -311); warning:SetAutoFocus(false); warning:SetNumeric(true); warning:SetMaxLetters(3)
    A.Settings.warning = warning
    local warningApply = U.Button(f, 'Apply', 72, function()
        local value = tonumber(warning:GetText())
        if value then A.db.settings.warningSeconds = math.max(15, math.min(300, math.floor(value))) end
        warning:SetText(tostring(A.db.settings.warningSeconds)); warning:ClearFocus(); A.Refresh()
    end)
    warningApply:SetPoint('LEFT', warning, 'RIGHT', 12, 0)
    local reset = U.Button(f, 'Reset window position', 180, function()
        A.db.settings.position = nil; U.frame:ClearAllPoints(); U.frame:SetPoint('RIGHT', UIParent, 'RIGHT', -65, 15)
    end)
    reset:SetPoint('BOTTOMLEFT', 18, 24)
    f:Hide()
end
function A.Settings.Toggle()
    local f = A.Settings.frame
    if f:IsShown() then f:Hide(); return end
    for key, b in pairs(A.Settings.checks) do b:SetChecked(A.db.settings[key]) end
    A.Settings.timeout:SetText(tostring(A.db.settings.idleSeconds))
    A.Settings.warning:SetText(tostring(A.db.settings.warningSeconds)); f:Show()
end
function A.Settings.Command(input)
    local cmd, arg = (input or ''):lower():match('^%s*(%S*)%s*(.-)%s*$')
    if cmd == '' then A.UI.Toggle()
    elseif cmd == 'show' then A.UI.Show(nil, false)
    elseif cmd == 'hide' then A.UI.frame:Hide()
    elseif cmd == 'settings' then A.Settings.Toggle()
    elseif cmd == 'debug' then A.db.settings.debug = not A.db.settings.debug; A.Print('Debug ' .. (A.db.settings.debug and 'on' or 'off'))
    elseif cmd == 'timeout' and tonumber(arg) then
        A.db.settings.idleSeconds = math.max(30, math.min(600, math.floor(tonumber(arg))))
        A.Print('Idle timeout: ' .. A.db.settings.idleSeconds .. ' seconds')
    elseif cmd == 'status' then
        A.RefreshBuffs()
        A.Print(A.UI.StatusText())
        A.Print('Readable journal scores: ' .. (A.Provider.journalCount or 0) .. '; locale: ' .. GetLocale())
        for _, category in ipairs({'lure', 'perception', 'tea'}) do
            local effect = A.Effects.Select(category)
            A.Print(category .. ': ' .. (effect and effect.name or 'none detected'))
        end
        for _, b in ipairs(A.buffs or {}) do
            A.Print('[' .. (b.category or 'unknown') .. '] ' .. b.name .. ' / ' .. A.Effects.Timer(b)
                .. ' / skill=' .. tostring(b.skillBonus) .. ' perception=' .. tostring(b.perceptionBonus)
                .. ' / ' .. b.source .. ' / ' .. (b.evidence or 'no numeric evidence') .. ' / spell=' .. tostring(b.spellID))
        end
    else A.Print('/fb [show | hide | settings | debug | status | timeout 90]') end
end
