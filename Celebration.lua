local _, A = ...
A.Celebration = { queue = {}, nextAt = 0 }
A.Celebration.levels = { interesting = {duration = 4, color = {.64, .46, .21, 1}},
    record = {duration = 5, color = {.35, .8, .94, 1}}, exceptional = {duration = 6, color = {1, .64, .20, 1}} }
function A.Celebration.Build()
    local f = A.UI.Panel(UIParent, 370, 105)
    A.Celebration.frame = f
    f:SetPoint('TOP', UIParent, 'TOP', 0, -130); f:SetFrameStrata('HIGH'); f:EnableMouse(false)
    f.title = A.UI.Label(f, 'GameFontNormalLarge', 340); f.title:SetPoint('TOPLEFT', 15, -14)
    f.body = A.UI.Label(f, nil, 340); f.body:SetPoint('TOPLEFT', 15, -42)
    f:Hide()
end
A.On('CELEBRATE', function(post, level)
    if not A.db.settings.celebrations then return end
    local queue = A.Celebration.queue
    queue[#queue + 1] = { post = post, level = level or 'interesting' }
    if #queue > 5 then table.remove(queue, 1) end
end)
function A.Celebration.Tick()
    local C = A.Celebration
    if C.frame:IsShown() and GetTime() >= C.nextAt then C.frame:Hide() end
    if not A.db.settings.celebrations then C.queue = {}; C.frame:Hide(); return end
    if C.frame:IsShown() or A.Session.casting or A.Safe(InCombatLockdown) then return end
    local entry = table.remove(C.queue, 1)
    if not entry then return end
    local style = C.levels[entry.level] or C.levels.interesting
    local title, body = A.Feed.Display(entry.post)
    C.frame.title:SetText(entry.level == 'exceptional' and 'NOW THAT is a nice fish.' or title)
    C.frame.body:SetText(body)
    C.frame:SetBackdropBorderColor(unpack(style.color))
    C.frame:SetHeight(math.max(105, C.frame.body:GetStringHeight() + 58))
    C.frame:Show(); C.nextAt = GetTime() + style.duration
end
