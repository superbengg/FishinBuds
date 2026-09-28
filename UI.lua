local _, A = ...
local U = { tab = 'Feed', rows = {} }
A.UI = U
-- All appearance choices live here so future device skins need no data changes.
U.skin = { background = { .035, .055, .065, .98 }, brass = { .64, .46, .21, 1 }, crystal = { .35, .8, .94, 1 } }
function U.Bar(parent, width, height, color, point, x, y)
    local t = parent:CreateTexture(nil, 'ARTWORK')
    t:SetSize(width, height); t:SetPoint(point or 'TOPLEFT', x or 0, y or 0)
    t:SetColorTexture(unpack(color)); return t
end
function U.Rivet(parent, point, x, y)
    U.Bar(parent, 7, 7, U.skin.brass, point, x, y)
    U.Bar(parent, 4, 1, {.12, .09, .05, 1}, point, x, y)
end
function U.Panel(parent, width, height)
    local f = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    f:SetSize(width, height)
    f:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    f:SetBackdropColor(unpack(U.skin.background)); f:SetBackdropBorderColor(unpack(U.skin.brass))
    return f
end
function U.Label(parent, size, width)
    local f = parent:CreateFontString(nil, 'OVERLAY', size or 'GameFontHighlightSmall')
    f:SetWidth(width or 338); f:SetJustifyH('LEFT'); f:SetWordWrap(true)
    return f
end
function U.Button(parent, label, width, click)
    local b = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    b:SetSize(width, 26)
    b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8', edgeFile='Interface\\Tooltips\\UI-Tooltip-Border', edgeSize=10})
    b:SetBackdropColor(.10, .12, .12, 1); b:SetBackdropBorderColor(unpack(U.skin.brass))
    b.text = U.Label(b, 'GameFontHighlightSmall', width - 8)
    b.text:SetPoint('CENTER'); b.text:SetJustifyH('CENTER'); b.text:SetText(label)
    b:SetScript('OnClick', click)
    b:SetScript('OnEnter', function(self) self:SetBackdropColor(.16, .23, .25, 1) end)
    b:SetScript('OnLeave', function(self) self:SetBackdropColor(.10, .12, .12, 1) end)
    return b
end
function U.SelectTab(tab)
    U.tab = tab; U.scroll:SetVerticalScroll(0); U.Render()
end
function U.Show(tab, auto)
    U.autoOpened = auto == true
    if tab then U.tab = tab; U.scroll:SetVerticalScroll(0) end
    A.RefreshBuffs()
    U.frame:Show(); U.Render()
end
function U.Toggle()
    if U.frame:IsShown() then U.frame:Hide() else U.Show(nil, false) end
end
function U.Build()
    local f = U.Panel(UIParent, 410, 604)
    U.frame = f
    f:SetFrameStrata('MEDIUM'); f:SetClampedToScreen(true); f:SetMovable(true)
    f:SetBackdropColor(.115, .10, .075, .99)
    for _, corner in ipairs({'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT'}) do
        U.Rivet(f, corner, corner:find('LEFT') and 9 or -9, corner:find('TOP') and -9 or 9)
    end
    U.Bar(f, 318, 2, U.skin.brass, 'TOPLEFT', 43, -51)
    U.Bar(f, 70, 2, U.skin.crystal, 'TOPLEFT', 43, -51)
    local pos = A.db.settings.position
    if type(pos) == 'table' and type(pos.x) == 'number' and type(pos.y) == 'number' then
        f:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', pos.x, pos.y)
    else f:SetPoint('RIGHT', UIParent, 'RIGHT', -65, 15) end
    local header = CreateFrame('Frame', nil, f)
    header:SetPoint('TOPLEFT', 8, -8); header:SetSize(342, 42)
    header:EnableMouse(true); header:RegisterForDrag('LeftButton')
    header:SetScript('OnDragStart', function() f:StartMoving() end)
    header:SetScript('OnDragStop', function()
        f:StopMovingOrSizing(); A.db.settings.position = { x = f:GetLeft(), y = f:GetBottom() }
    end)
    local icon = header:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(28, 28); icon:SetPoint('LEFT', 7, 0); icon:SetTexture('Interface\\Icons\\Trade_Engineering')
    local title = U.Label(header, 'GameFontNormalLarge', 270)
    title:SetPoint('LEFT', 43, 6); title:SetText("Fishin' Buds")
    local subtitle = U.Label(header, nil, 270)
    subtitle:SetPoint('LEFT', 44, -12); subtitle:SetText('|cff71d5efGNOMISH FIELD COMMUNICATOR|r')
    local close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT', -4, -5); close:SetScript('OnClick', function() f:Hide() end)
    local status = U.Panel(f, 382, 244); status:SetPoint('TOPLEFT', 14, -59)
    U.skill = U.Label(status, 'GameFontHighlightSmall', 354); U.skill:SetPoint('TOPLEFT', 14, -12)
    U.Bar(status, 354, 1, {.32, .30, .21, 1}, 'TOPLEFT', 14, -34)
    U.readouts = {}
    for i, category in ipairs({'lure', 'perception', 'tea'}) do
        local meter = CreateFrame('Frame', nil, status)
        meter:SetSize(354, 43); meter:SetPoint('TOPLEFT', 14, -42 - (i - 1) * 46)
        meter.heading = U.Label(meter, 'GameFontNormal', 354); meter.heading:SetPoint('TOPLEFT')
        meter.name = U.Label(meter, nil, 354); meter.name:SetPoint('TOPLEFT', 0, -19)
        meter.name:SetMaxLines(1)
        meter:EnableMouse(true)
        meter:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
            GameTooltip:AddLine(A.Effects.labels[category])
            local found = false
            for _, effect in ipairs(A.buffs or {}) do
                if effect.category == category then
                    found = true; GameTooltip:AddLine(effect.name, 1, 1, 1, true)
                    local bonus = A.Effects.BonusText(effect)
                    GameTooltip:AddLine((bonus ~= '' and bonus .. ' / ' or '') .. A.Effects.Timer(effect), .45, .83, .94, true)
                end
            end
            if not found then GameTooltip:AddLine('None detected. Other fishing effects are listed under Me.', 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        meter:SetScript('OnLeave', function() GameTooltip:Hide() end)
        U.readouts[category] = meter
    end
    U.Bar(status, 354, 1, {.32, .30, .21, 1}, 'TOPLEFT', 14, -179)
    U.location = U.Label(status, nil, 354); U.location:SetPoint('TOPLEFT', 14, -189); U.location:SetMaxLines(1)
    U.session = U.Label(status, nil, 248); U.session:SetPoint('TOPLEFT', 14, -214)
    U.tool = U.Button(status, 'Fishing tool', 94, function() end)
    U.tool:SetPoint('BOTTOMRIGHT', -9, 8)
    U.tool:SetScript('OnEnter', function(b)
        local slots = A.Provider.ToolSlots()
        GameTooltip:SetOwner(b, 'ANCHOR_LEFT')
        if slots[1] then GameTooltip:SetInventoryItem('player', slots[1])
        else GameTooltip:AddLine('No fishing tool equipped.') end
        GameTooltip:Show()
    end)
    U.tool:SetScript('OnLeave', function() GameTooltip:Hide() end)
    U.tabs = {}
    for i, tab in ipairs({'Feed', 'Me', 'Buds', 'Realm', 'Records'}) do
        local b = U.Button(f, tab, 74, function() U.SelectTab(tab) end)
        b:SetPoint('TOPLEFT', 14 + (i - 1) * 77, -311)
        b.selected = U.Bar(b, 54, 2, U.skin.crystal, 'BOTTOM', 0, 3)
        U.tabs[tab] = b
    end
    local scroll = CreateFrame('ScrollFrame', nil, f, 'UIPanelScrollFrameTemplate')
    U.scroll = scroll
    scroll:SetPoint('TOPLEFT', 17, -346); scroll:SetPoint('BOTTOMRIGHT', -34, 43)
    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(354, 1); scroll:SetScrollChild(content); U.content = content
    local footer = U.Label(f, nil, 230)
    footer:SetPoint('BOTTOMLEFT', 17, 16); footer:SetText('|cff8dabaeA little company by the water.|r')
    local settings = U.Button(f, 'Settings', 80, function() A.Settings.Toggle() end)
    settings:SetPoint('BOTTOMRIGHT', -14, 10)
    f:Hide()
end
function U.StatusText()
    local skill, s = A.Provider.Skill(), A.char.current
    local zone, subzone = A.Location()
    local rank = skill.current and (skill.current .. ' / ' .. (skill.maximum or '?')) or 'Unavailable'
    local bonus = skill.bonus and ('  +' .. skill.bonus .. '  (effective ' .. ((skill.current or 0) + skill.bonus) .. ')') or '  Bonus unavailable'
    return '|cff71d5ef' .. (s and 'FISHING SESSION' or 'READY WHEN YOU ARE') .. '|r  ' .. (s and A.Duration(time() - s.started) or '0:00')
        .. '  |  ' .. (s and s.catches or 0) .. ' catches / ' .. (s and s.casts or 0) .. ' casts\nFishing: ' .. rank .. bonus
        .. '\n' .. zone .. (subzone ~= '' and (' / ' .. subzone) or '')
end
function U.UpdateStatus()
    local skill, s = A.Provider.Skill(), A.char.current
    local effective = skill.current and skill.bonus and skill.current + skill.bonus
    U.skill:SetText('Fishing |cff71d5ef' .. (skill.current or '?') .. '/' .. (skill.maximum or '?')
        .. '|r  /  ' .. (skill.bonus and ('+' .. skill.bonus) or '?') .. ' bonus  /  Effective |cff71d5ef' .. (effective or '?') .. '|r')
    local zone, subzone = A.Location()
    U.location:SetText(subzone ~= '' and (zone .. ' / ' .. subzone) or zone)
    U.session:SetText(s and (s.catches .. ' catches / ' .. s.casts .. ' casts / ' .. A.Duration(time() - s.started)) or 'Ready when you are.')
    for category, meter in pairs(U.readouts) do
        local effect, count = A.Effects.Select(category)
        local label = category == 'tea' and 'RELAXED TEA' or (category == 'lure' and 'LURE' or 'PERCEPTION')
        if not effect then
            meter.heading:SetText('|cffffcd72' .. label .. '  /  None detected|r')
            meter.name:SetText(category == 'tea' and 'Sanguithorn Tea / Relaxed' or
                (category == 'lure' and 'Other fishing effects live under Me.' or 'A phial for the next fishing trip?'))
        else
            local timer, remaining = A.Effects.Timer(effect)
            local amount
            if category == 'lure' then amount = effect.skillBonus else amount = effect.perceptionBonus end
            local warning = remaining and remaining <= A.db.settings.warningSeconds
            local color = warning and '|cffffb060' or '|cff71d5ef'
            local bonus = amount and (' +' .. amount .. (category == 'tea' and ' Perception' or '')) or ' active'
            meter.heading:SetText(color .. label .. bonus .. '  /  ' .. timer
                .. (warning and '  /  Expiring' or '') .. '|r')
            meter.name:SetText(effect.name .. (count > 1 and (' (+' .. (count - 1) .. ' more)') or ''))
        end
    end
end
function U.Row(index, title, body, link)
    local row = U.rows[index]
    if not row then
        row = U.Panel(U.content, 352, 90)
        row.title = U.Label(row, 'GameFontNormal', 326); row.title:SetPoint('TOPLEFT', 12, -12); row.title:SetMaxLines(1)
        row.body = U.Label(row, nil, 326); row.body:SetPoint('TOPLEFT', 12, -34)
        row:EnableMouse(true)
        row:SetScript('OnEnter', function(self)
            if self.link then GameTooltip:SetOwner(self, 'ANCHOR_LEFT'); GameTooltip:SetHyperlink(self.link); GameTooltip:Show() end
        end)
        row:SetScript('OnLeave', function() GameTooltip:Hide() end)
        -- A future reactions strip can be added to this reusable post renderer.
        U.rows[index] = row
    end
    row.title:SetText(title); row.body:SetText(body); row.link = link
    local height = math.max(84, row.body:GetStringHeight() + 48)
    row:SetHeight(height); row:ClearAllPoints(); row:SetPoint('TOPLEFT', 0, -U.offset)
    row:Show(); U.offset = U.offset + height + 7
end
local function locationTime(r)
    return (r.subzone ~= '' and r.subzone or r.zone or 'Unknown waters') .. '  /  ' .. date('%m/%d %H:%M', r.timestamp)
end
function U.Render()
    if not U.frame or not U.frame:IsShown() then return end
    U.UpdateStatus(); U.offset = 0
    for _, row in ipairs(U.rows) do row:Hide() end
    for tab, button in pairs(U.tabs) do
        button.selected:SetShown(tab == U.tab)
        button.text:SetText((tab == U.tab and '|cff71d5ef' or '|cffdac69e') .. tab .. '|r')
        button:SetBackdropBorderColor(unpack(tab == U.tab and U.skin.crystal or U.skin.brass))
    end
    local n = 0
    local function add(title, body, link) n = n + 1; U.Row(n, title, body, link) end
    if U.tab == 'Feed' then
        for _, post in ipairs(A.char.feed) do
            local title, body = A.Feed.Display(post)
            add(title, body .. '\n|cff8dabae' .. locationTime(post) .. '|r', post.link)
        end
        if n == 0 then add('A quiet frequency', 'Cast a line. Your first catch and fishing highlights will find their way here.') end
    elseif U.tab == 'Me' then
        local s, current = A.char.stats, A.char.current
        add(A.char.name, string.format('Lifetime: %d casts / %d catches / %d items\nRare catches: %d\nTime by the water: %s', s.casts, s.catches, s.items, s.rare, A.Duration(s.seconds + (current and current.lastActivity - current.started or 0))))
        for _, buff in ipairs(A.buffs or {}) do
            local remaining = buff.expires and buff.expires > 0 and math.max(0, buff.expires - GetTime())
            local bonus = A.Effects.BonusText(buff)
            add(buff.name, (A.Effects.labels[buff.category] or 'Fishing effect')
                .. (bonus ~= '' and ('\n' .. bonus) or '')
                .. (buff.category ~= 'equipment' and ('\n' .. A.Effects.Timer(buff)) or ''))
        end
        for i, session in ipairs(A.char.sessions) do
            add('Previous session', date('%m/%d %H:%M', session.started) .. '  /  ' .. A.Duration(session.lastActivity - session.started)
                .. '\n' .. session.casts .. ' casts / ' .. session.catches .. ' catches / ' .. session.items .. ' items')
            if i >= 3 then break end
        end
        for i, c in ipairs(A.char.recent) do
            add('Recent catch', c.link .. ' x' .. c.quantity .. '\n' .. locationTime(c), c.link)
            if i >= 50 then break end
        end
    elseif U.tab == 'Records' then
        add('Your fishing notebook', 'Your journal bests and memorable catches. Journal scores can be shared across your warband.\nTrophy milestones: ' .. #A.char.trophies)
        local records = {}
        for _, r in pairs(A.char.journal) do records[#records + 1] = r end
        table.sort(records, function(a, b) return a.score.value > b.score.value end)
        for _, r in ipairs(records) do add(r.name, string.format('Journal best: %.1f points  /  %s\n%s', r.score.value, r.rank or 'Rank unavailable', locationTime(r))) end
        for _, r in ipairs(A.char.trophies) do add('Trophy: ' .. r.name, 'A new milestone in your fishing journal.\n' .. locationTime(r)) end
        if #records == 0 then add('A fresh page', 'No Anglin\' scores to show yet. Your recent catches are waiting under Me.') end
        for _, c in ipairs(A.char.recent) do
            if c.quality and c.quality >= 3 then add('A catch to remember', c.link .. '\n' .. locationTime(c), c.link) end
        end
    elseif U.tab == 'Buds' then
        add('Save a spot for your Buds', 'Fishing is better with company. Sharing adventures with friends is coming later.\n\nFor now, this little device follows your own fishing trips.')
    else
        add('The realm frequency is quiet', 'One day, tales from anglers across the realm will reach this little receiver.\n\nUntil then, your own highlights are waiting in Records.')
    end
    U.content:SetHeight(math.max(1, U.offset))
end
A.On('REFRESH', U.Render)
