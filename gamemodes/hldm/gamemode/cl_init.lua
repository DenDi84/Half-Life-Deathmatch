include("shared.lua")
include("scoreboard.lua")
include("cl_menuinterface.lua")
include("cl_killfeed.lua")
include("cl_voice.lua")
include("cl_chatbox.lua")

local scrW = ScrW()
local scrH = ScrH()
local hudscalex = 150
local hudscaley = 50
local FONT_CACHE = {}

local barneystart = {
    [1] = "barney_startround/aimforhead.wav",
    [2] = "barney_startround/aintscared.wav",
    [3] = "barney_startround/ba_bring.wav",
    [4] = "barney_startround/ba_endline.wav",
    [5] = "barney_startround/ba_raincheck.wav"
}

local barneyend = {

    [1] = "barney_endround/ba_another.wav",
    [2] = "barney_endround/ba_close.wav",
    [3] = "barney_endround/ba_gotone.wav"

}

function GetFittingFont(text, baseFontName, maxWidth, maxFontSize)
    maxFontSize = maxFontSize or 30 

    for size = maxFontSize, 8, -1 do 
        local fontName = baseFontName .. "_" .. size
        
        if not FONT_CACHE[fontName] then
            surface.CreateFont(fontName, {
                font = "Trebuchet MS",
                size = size,
                weight = 900,
                antialias = true,
                additive = true,
                tall = 24
            })
            FONT_CACHE[fontName] = true
        end
        surface.SetFont(fontName)
        local textW, _ = surface.GetTextSize(text)

        if textW <= maxWidth then
            return fontName
        end
    end
    return baseFontName .. "_8"
end

local waitingDots = 0

timer.Create("WaitingTextAnim", 1, 0, function()
    waitingDots = waitingDots + 1
    if waitingDots > 3 then
        waitingDots = 0
    end
end)

local roundTimeLeft = 0

net.Receive("UpdateTime", function(len, ply)

    local newtime = net.ReadInt(16)

    roundTimeLeft = newtime

end)

local boxW, boxH = 150, 50
local boxX, boxY = (scrW/2) - boxW/2, 0
local padding = 5
local fittingFont
local CurState = 0
local globalcounter

net.Receive("roundstate", function(len, ply)

    CurState = net.ReadInt(3)

    if CurState == 3 then
        GAMEMODE:StartCountdownSFX()
    end

end)


surface.CreateFont("FontCounter", {
    font = "Trebuchet MS", 
    size = 40,
    weight = 900,
    antialias = true
})

function GM:HUDPaint()

    local ply = LocalPlayer()
    local hudcolor = Color(255, 150, 50, 175)
        -------ПАНЕЛЬКА ПО ЦЕНТРУ------

        --draw.RoundedBox(0, boxX, boxY, boxW, boxH, Color(0, 0, 0, 200))
        if CurState == 0 then
            local dotsString = string.rep(".", waitingDots)
            local wt = "Waiting for players" ..dotsString
            --roundTimeLeft = 0

            fittingFont = GetFittingFont(wt, "CloseCaption_Bold", boxW*2 - padding * 2, 19)
      
            draw.SimpleText(wt, fittingFont, boxX + boxW / 2, boxY + boxH / 2, hudcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        elseif (CurState == 1) then
            local minutes = math.floor(roundTimeLeft / 60)
            local seconds = roundTimeLeft % 60
            local timeString = string.format("%02d:%02d", minutes, seconds)

            fittingFont = GetFittingFont(timeString, "CloseCaption_Bold", boxW - padding * 2, 24)

            draw.SimpleText(timeString, fittingFont, boxX + boxW / 2, boxY + boxH / 2, hudcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        elseif (CurState == 3) then

            local t = "The match is about to start."
            fittingFont = GetFittingFont(t, "CloseCaption_Bold", 50, 24)
            draw.SimpleText(t, "Trebuchet24", scrW/2, (scrH/2)-(scrH/3), hudcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local displayCounter = math.Clamp((globalcounter or 0) + 1, 1, 10)
            draw.SimpleText(displayCounter, "FontCounter", scrW/2, (scrH/2)-(scrH/5), hudcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        ---кончилась панелька-------

        local startX = ScrW() - 400 
        local startY = 50          
        local lineHeight = 20      

        if ply:GetNWBool("IsSpectator", false) then
            
            local spec_target = ply:GetObserverTarget()
            local spec_mode = ply:GetObserverMode()
            local text = ""
            

            if IsValid(spec_target) and spec_target:IsPlayer() and spec_mode != OBS_MODE_ROAMING then
                text = spec_target:Nick()
            else
                text = "Freecam"
            end
            
        draw.SimpleText(text, "Trebuchet24", scrW/2, scrH-scrH/20, hudcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

end




function GM:StartCountdownSFX()

    if timer.Exists("SFXCounter") then
        timer.Remove("SFXCounter")
    end

    globalcounter = 10
        

    timer.Create("SFXCounter", 1, 10, function()

        local soundPath
        if globalcounter > 0 then
            if GetConVar("hldm_vocoder"):GetString() == "female" then
                soundPath = "vox_f/".. globalcounter..".wav" 
            else
                soundPath = "vox_m/".. globalcounter..".wav" 
            end
            surface.PlaySound(soundPath)
        end
        
        globalcounter = globalcounter - 1


        if globalcounter == 0 then

            timer.Simple(1, function()
                
                if barneystart and #barneystart > 0 then
                    local phrasenum = math.random(#barneystart)
                    surface.PlaySound(barneystart[phrasenum])
                end

            end)
        end
    end)
end

local isEndOfRoundCameraActive = false 

local cameraPosition = nil
local cameraAngle = nil


net.Receive("RoundEndCamera_SetState", function()
    local shouldBeActive = net.ReadBool()
    cameraPosition = net.ReadVector()
    cameraAngle = net.ReadAngle()

    if cameraPosition == nil then return end 

    local ply = LocalPlayer()

    if shouldBeActive then

        timer.Simple(3,function ()
            isEndOfRoundCameraActive = true
            ply:DrawViewModel(false)
        end)

        Scoreboard(true)

        surface.PlaySound( "buzzer/buzzer.wav" )

    else
        

        ply:DrawViewModel(true)
        isEndOfRoundCameraActive = false

    end
end)

local gsrcdeathcam = GetConVar("sv_gsrchud_allow_deathcam")
local isdeathcam = gsrcdeathcam:GetBool()
if not IsValid(gsrcdeathcam) then isdeathcam = false end

hook.Add("CalcView", "EndOfRoundCamera/DeathCamCustom", function(ply, pos, ang, fov)
    -- hide ragdoll
    local ragdoll = LocalPlayer():GetRagdollEntity()
    if ragdoll and IsValid(ragdoll) then ragdoll:SetNoDraw(true) end
    local view = {}
	
    if not LocalPlayer():Alive() and not isdeathcam and not isEndOfRoundCameraActive then
        view = {
            origin = ply:GetPos() + Vector(0, 0, 10),
            angles = ply:GetAngles() + Angle(0, 0, 90),
            fov = fov
        }
        return view
    end

    if not isEndOfRoundCameraActive then
        return 
    end

    view.origin = cameraPosition
    view.drawviewer = true
    view.fov = 90

    local amplitude = 2
    local speed = 0.5
    
    local offsetP = ((amplitude * math.sin(CurTime() * speed))/3)+1
    local offsetY = amplitude * math.cos(CurTime() * speed)

    view.angles = Angle(
        cameraAngle.p + offsetP,
        cameraAngle.y + offsetY,
        cameraAngle.r
    )



    return view
end)

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	return true
end

function GM:PlayerFootstep(ply, pos, foot, soundName, volume)

    if soundName == "player/footsteps/ladder1.wav"  or soundName == "player/footsteps/ladder2.wav" or soundName == "player/footsteps/ladder3.wav" or soundName == "player/footsteps/ladder4.wav" then return false end
    
    if not IsValid(ply) then return true end
    
    if ply.NextFootstepTime and CurTime() < ply.NextFootstepTime then
        return true 
    end

    if ply:GetVelocity():Length() <= 200 and ply:GetVelocity():Length() > 120 then return true end

    local tr = util.QuickTrace(pos, Vector(0, 0, -100), ply)
    if not tr.Hit then return true end

    local material = string.lower(util.GetSurfacePropName(tr.SurfaceProps))
    local customSounds = HLDM_SOUNDS.Footsteps[material]
    if customSounds == nil then customSounds = HLDM_SOUNDS.Footsteps["default"] end
    
    if customSounds == nil then
        return false
    end
    
    if !ply:IsOnGround() then return true end
    
    return true
end

hook.Add("PrePlayerDraw", "DisablePlayerShadows", function(ply)
    ply:DrawShadow(false)
end)

hook.Add( "Initialize", "some_unique_name", function()
	RunConsoleCommand("gsrchud_loading", 0)
end )

hook.Add( "PreRegisterSWEP", "crosshairDisable", function( swep_table, class )
    
    swep_table.DoDrawCrosshair = function(self, x, y)

        local crosshairs = surface.GetTextureID("hl1/sprites/crosshairs")

        local cvar_chair = GetConVar("hl1_cl_crosshair")
        local cvar_chair_scale = GetConVar("hl1_cl_crosshair_scale")
        local cvar_chair_col
        if GSRCHUD then
	        cvar_chair_col = GetConVar("hl1_cl_crosshair_gsrchud")
        end
        if !cvar_chair:GetBool() then return false end
        if self:GetPrimaryAmmoType() == -1 or !cvar_chair:GetBool() or !self.CrosshairXY then return true end
        
        local chColor = self.CrosshairColor
        
        if GSRCHUD and GSRCHUD.isEnabled() and cvar_chair_col:GetBool() then
            chColor = GSRCHUD.getCurrentColour()
        end
        
        surface.SetDrawColor(chColor)
        surface.SetTexture(crosshairs)
        
        local scale = cvar_chair_scale:GetFloat()

        local w, h = self.CrosshairWH[1] * scale, self.CrosshairWH[2] * scale
        local tx, ty = self.CrosshairXY[1], self.CrosshairXY[2]
        local txsizew, txsizeh = surface.GetTextureSize(crosshairs)
        
        x, y = x - w / 2 + scale / 2, y - h / 2 + scale / 2 + 1
        
        if self.Owner == LocalPlayer() and self.Owner:ShouldDrawLocalPlayer() then
            local tr = self.Owner:GetEyeTraceNoCursor()	
            local coords = tr.HitPos:ToScreen()
            x, y = coords.x - 10, coords.y - 10
        end
        
        surface.DrawTexturedRectUV(x, y, w, h, tx / txsizew, ty / txsizeh, (tx+self.CrosshairWH[1]) / txsizew, (ty+self.CrosshairWH[2]) / txsizeh)
        return true
    end

end)