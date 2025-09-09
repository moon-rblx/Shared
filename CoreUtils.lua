local TweenService = game:GetService('TweenService')

local CoreUtils = {}

-- ==== Math Utilities =====

function CoreUtils.Round(num, decimals)
    decimals = decimals or 0

    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

-- ==== Table Utilities =====

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