local function UpdateKillfeedFont()
    local scale = 1
    if ConVarExists("gsrchud_scale") then
        scale = GetConVar("gsrchud_scale"):GetFloat()
    end
    
    surface.CreateFont("KillfeedFont", {
        font = "Verdana",
        size = 14 * scale,
        weight = 900,
        antialias = false,
    })
end

UpdateKillfeedFont()

cvars.AddChangeCallback("gsrchud_scale", function(cvar, old, new)
    UpdateKillfeedFont()
end, "UpdateKillfeedFontCallback")

local KILLFEED_FONT = "KillfeedFont"

local KillfeedEntries = {}

net.Receive("Killfeed_AddEntry", function()
    local attackerName = net.ReadString()
    local victimName = net.ReadString()
    local iconName = net.ReadString()


    local materialPath = "hl11/icons/" .. iconName .. ".png"
    local newEntry = {
        attacker = attackerName,
        victim = victimName,
        icon = iconName,
        material = Material(materialPath, "noclamp smooth"),
        expireTime = CurTime() + 6
    }
    table.insert(KillfeedEntries, 1, newEntry)

    if #KillfeedEntries > 5 then
        table.remove(KillfeedEntries, #KillfeedEntries)
    end

end)
local selfnick = nil
local textcolor = Color(255, 150, 50, 255)
local killiconCol = Color(238, 67, 25)

hook.Add("HUDPaint", "DrawKillfeed", function()
    local scale = 1
    if ConVarExists("gsrchud_scale") then
        scale = GetConVar("gsrchud_scale"):GetFloat()
    end

    local ScaledYStart = 20 * scale
    local ScaledXMargin = 20 * scale
    local ScaledIconSize = 48 * scale
    local ScaledPadding = 8 * scale
    
    local y = ScaledYStart
    for i = #KillfeedEntries, 1, -1 do
        local entry = KillfeedEntries[i]
        if CurTime() > entry.expireTime then
            table.remove(KillfeedEntries, i)
            continue
        end
        surface.SetFont(KILLFEED_FONT)
        local attackerW, attackerH = surface.GetTextSize(entry.attacker)
        local victimW, _ = surface.GetTextSize(entry.victim)
        local totalWidth = attackerW + ScaledPadding + ScaledIconSize + ScaledPadding + victimW
        local x = ScrW() - ScaledXMargin - totalWidth
        if selfnick == nil then selfnick = LocalPlayer():Nick() end
        if selfnick == entry.attacker or selfnick == entry.victim then
            draw.RoundedBox(4, x - ScaledPadding, y, totalWidth + ScaledPadding * 2, attackerH + (4 * scale), Color(100, 0, 0, 180))
        else
            draw.RoundedBox(4, x - ScaledPadding, y, totalWidth + ScaledPadding * 2, attackerH + (4 * scale), Color(20, 20, 20, 180))
        end
        draw.SimpleText(entry.attacker, KILLFEED_FONT, x, y + (2 * scale), textcolor, TEXT_ALIGN_LEFT)
        x = x + attackerW + ScaledPadding
        if entry.material and not entry.material:IsError() then
            surface.SetDrawColor(killiconCol)
            surface.SetMaterial(entry.material)
            surface.DrawTexturedRect(x, y, ScaledIconSize, ScaledIconSize/2)
        end
        x = x + ScaledIconSize + ScaledPadding
        draw.SimpleText(entry.victim, KILLFEED_FONT, x, y + (2 * scale), textcolor, TEXT_ALIGN_LEFT)
        y = y + attackerH + (8 * scale)
    end
end)