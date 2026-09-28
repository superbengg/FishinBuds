local _, A = ...
A.Feed = {}
function A.Feed.Add(kind, title, body, record)
    local post = { id = A.Store.ID(), version = 1, origin = 'local', kind = kind,
        author = A.char.name, timestamp = record.timestamp, title = title, body = body,
        zone = record.zone, subzone = record.subzone, link = record.link,
        recordID = record.id, reactions = {}, quantity = record.quantity }
    table.insert(A.char.feed, 1, post); A.Trim(A.char.feed, 100)
    A.Debug('Feed event created', kind, post.id)
    return post
end
function A.Feed.Display(post)
    local title, body = post.title, post.body
    local name = (post.author or ''):match('^[^-]+') or post.author or 'An angler'
    if post.kind == 'first-catch' then
        title = 'First catch of the trip'
        if post.link then body = name .. ' caught ' .. post.link end
    elseif post.kind == 'rare-catch' then
        title = 'Rare Catch!'
        if post.link then body = name .. ' caught ' .. post.link .. (post.quantity and post.quantity > 1 and (' x' .. post.quantity) or '') end
    elseif post.kind == 'journal-best' then
        title = 'New journal best'
        body = body:gsub('\nJournal observation; individual catch score unavailable%.', '')
        if not body:find('Fishing journal', 1, true) then body = body .. '\nFishing journal / warband progress' end
    end
    return title, body
end
A.On('CATCH', function(c)
    if c.quality and c.quality >= 3 then
        local post = A.Feed.Add('rare-catch', 'Rare Catch!', (UnitName('player') or A.char.name) .. ' caught ' .. c.link .. ' x' .. c.quantity, c)
        A.Emit('CELEBRATE', post, 'interesting')
    elseif A.char.current and A.char.current.catches == 1 then
        A.Feed.Add('first-catch', 'First catch of the trip', (UnitName('player') or A.char.name) .. ' caught ' .. c.link, c)
    end
end)
A.On('RECORD', function(c, old)
    local post = A.Feed.Add('journal-best', 'New journal best',
        c.name .. '\n' .. string.format('Anglin\' Score: %.1f -> %.1f', old.score.value, c.score.value)
        .. '  /  ' .. (c.rank or 'Rank unknown') .. '\nFishing journal / warband progress', c)
    if A.char.current then A.Emit('CELEBRATE', post, c.trophy and not old.trophy and 'exceptional' or 'record') end
end)
