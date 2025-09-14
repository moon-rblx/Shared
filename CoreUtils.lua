local TweenService = game:GetService('TweenService')

local CoreUtils = {}

-- ==== Math Utilities =====

function CoreUtils.Round(num, decimals)
    decimals = decimals or 0

    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

-- ==== Table Utilities =====

function CoreUtils.SearchTable(tbl, query, opts)
    opts = opts or {}
    local action = opts.action or 'print'
    local filename = opts.filename or 'search_results.txt'
    local q = query and tostring(query):lower() or nil

    local function matches(k, v)
        if not q then return true end
        if tostring(k):lower():find(q, 1, true) then return true end
        if type(v) ~= 'table' and tostring(v):lower():find(q, 1, true) then return true end
        return false
    end

    local function should_include(t)
        if not q then return true end
        for kk, vv in pairs(t) do
            if matches(kk, vv) then return true end
            if type(vv) == 'table' and should_include(vv) then return true end
        end
        return false
    end

    local function sorted_keys(t)
        local ks = {}
        for k in pairs(t) do ks[#ks+1] = k end
        table.sort(ks, function(a, b)
            local ta, tb = type(a), type(b)
            if ta == tb then
                if ta == 'number' then return a < b end
                if ta == 'string' then return a < b end
                return tostring(a) < tostring(b)
            else
                if ta == 'number' then return true end
                if tb == 'number' then return false end
                if ta == 'string' then return true end
                if tb == 'string' then return false end
                return tostring(ta) < tostring(tb)
            end
        end)
        return ks
    end

    local levels = {}
    local current = {}
    for _, k in ipairs(sorted_keys(tbl)) do
        local v = tbl[k]
        if type(v) == 'table' then
            if should_include(v) or matches(k, v) then
                current[#current+1] = {k = k, v = v, level = 1}
            end
        else
            if matches(k, v) then
                current[#current+1] = {k = k, v = v, level = 1}
            end
        end
    end

    local max_level = 0
    while #current > 0 do
        local next_level_nodes = {}
        for _, node in ipairs(current) do
            local k, v, level = node.k, node.v, node.level
            if level > max_level then max_level = level end
            levels[level] = levels[level] or {}
            if type(v) == 'table' then
                levels[level][#levels[level]+1] = 'Level '..level..': ['..tostring(k)..'] = {table}'
                for _, ck in ipairs(sorted_keys(v)) do
                    local cv = v[ck]
                    if type(cv) == 'table' then
                        if should_include(cv) or matches(ck, cv) then
                            next_level_nodes[#next_level_nodes+1] = {k = ck, v = cv, level = level + 1}
                        end
                    else
                        if matches(ck, cv) then
                            next_level_nodes[#next_level_nodes+1] = {k = ck, v = cv, level = level + 1}
                        end
                    end
                end
            else
                levels[level][#levels[level]+1] = 'Level '..level..': ['..tostring(k)..'] = '..tostring(v)
            end
        end
        current = next_level_nodes
    end

    local lines = {}
    for level = 1, max_level do
        local prefix = level == 1 and '' or string.rep('-', (level - 1) * 5)..' '
        local items = levels[level] or {}
        for _, line in ipairs(items) do
            lines[#lines+1] = prefix..line
        end
    end

    local out = table.concat(lines, '\n')
    if action == 'clipboard' and type(setclipboard) == 'function' then
        setclipboard(out)
    elseif action == 'file' and type(writefile) == 'function' then
        writefile(filename, out)
    else
        print(out)
    end
    return out, lines
end

-- ==== String Utilities =====

-- ==== Formatting Utilities =====

function CoreUtils.FormatNumber(num)
    local suffixes = { '', 'K', 'M', 'B', 'T', 'Qd' }
    local tier = math.floor(math.log(math.abs(num), 1000))

    if tier < 1 then
        return tostring(num)
    elseif tier >= #suffixes then
        tier = #suffixes - 1
    end

    local suffix = suffixes[tier + 1]
    local scale = 1000 ^ tier
    local formatted = CoreUtils.Round(num / scale, 1)

    return tostring(formatted) .. suffix
end

function CoreUtils.FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))

    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format('%02d:%02d:%02d', hrs, mins, secs)
end

function CoreUtils.FormatDay(seconds)
    seconds = math.max(0, math.floor(seconds))

    local days = math.floor(seconds / 86400)
    local parts = {}

    if days > 0 then table.insert(parts, days .. 'd') end

    local remainder = seconds % 86400
    if remainder > 0 then
        local formatted = CoreUtils.FormatTime(remainder)
        if days > 0 then
            formatted = formatted:gsub('^00:', '')
        end
        table.insert(parts, formatted)
    end

    return table.concat(parts, ' ')
end

-- ==== Movement / Positioning Utilities =====

function CoreUtils.CalculateDistance(pointA, pointB)
    return (pointA - pointB).Magnitude
end

function CoreUtils.TweenTo(player, destination, speed)
    local Character = player.Character or player.CharacterAdded:Wait()
    local playerHRP = Character:WaitForChild('HumanoidRootPart', 5)

    local distance = CoreUtils.CalculateDistance(playerHRP.Position, destination.Position)
    local duration = distance / speed
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(playerHRP, info, {CFrame = destination})

    tween:Play()
    CoreUtils.CreateAnchor(playerHRP)
    tween.Completed:Wait()

    return tween
end

function CoreUtils.TeleportTo(player, destination)
    local Character = player.Character or player.CharacterAdded:Wait()
    local playerHRP = Character:WaitForChild('HumanoidRootPart', 5)

    playerHRP.CFrame = destination
    CoreUtils.CreateAnchor(playerHRP)

    return true
end

function CoreUtils.CreateAnchor(playerHRP)
    local existing = playerHRP:FindFirstChild('Anchor')
    if existing and existing:IsA('Attachment') then
        return existing
    end

    local attachment = Instance.new('Attachment')
    attachment.Name = 'Anchor'
    attachment.Parent = playerHRP

    local linearVelocity = Instance.new('LinearVelocity')
    linearVelocity.Name = 'AnchorVelocity'
    linearVelocity.MaxForce = math.huge
    linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    linearVelocity.Attachment0 = attachment
    linearVelocity.Parent = attachment

    return attachment
end

function CoreUtils.DestroyAnchor(playerHRP)
    local anchor = playerHRP:FindFirstChild('Anchor')
    if anchor and anchor:IsA('Attachment') then
        anchor:Destroy()
        return true
    end

    return false
end


return CoreUtils



