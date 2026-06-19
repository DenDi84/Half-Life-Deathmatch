local issb = false
local ply
function Scoreboard(toggle)
    if toggle then
        local servername = GetHostName()
        Panel = vgui.Create("DFrame")
        Panel:SetTitle("")
        Panel:SetSize(ScrW() * .7, ScrH() * .85)
        Panel:Center()
        Panel:MakePopup()
        Panel:ShowCloseButton(false)
        Panel:SetDraggable(false)
        
        Panel.OnKeyCodePressed = function(self, key)
            if key == KEY_TAB then
                self:Remove()
                issb = false
                return true
            end
        end
        
        Panel.Paint = function(self, w, h)
            surface.SetDrawColor(0,0,0,230)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(servername,"CloseCaption_Bold",ScrW() * .04, ScrH() * 0.02, Color(250,140,0,255) )
            draw.SimpleText("FRAGS","HudHintTextLarge",ScrW() * 0.45, ScrH() * 0.057, Color(250,140,0,255) )
            draw.SimpleText("DEATHS","HudHintTextLarge",ScrW() * 0.5, ScrH() * 0.057, Color(250,140,0,255) )
            draw.SimpleText("PING","HudHintTextLarge",ScrW() * 0.55, ScrH() * 0.057, Color(250,140,0,255) )
            draw.SimpleText("VOICE","HudHintTextLarge",ScrW() * 0.6, ScrH() * 0.057, Color(250,140,0,255) )
            draw.SimpleText("Spectators: ","HudHintTextLarge",ScrW() * .04, ScrH()*0.81 , Color(128,128,128 ) )
        end
        local ypos = Panel:GetTall() * .1
        local unmuted = Material( "icon32/unmuted.png", "noclamp smooth" )
        local muted = Material( "icon32/muted.png", "noclamp smooth" )
        local muteornot = false
        local plysforsort = player.GetAll()
        table.sort(plysforsort, function(a,b) return a:Frags() > b:Frags() end)
        local itemHeight = Panel:GetTall() * 0.025
        local specnames = {}

        for k,v in ipairs(plysforsort) do
            if not v:IsValid() then return end
            if not v:GetNWBool("IsSpectator", false) then 
                local playerpanel = vgui.Create("DPanel", Panel)
                playerpanel:SetPos(0, ypos)
                playerpanel:SetSize(Panel:GetWide(), itemHeight)
                playerpanel.Paint = function(self, w, h)
                    if v:IsValid() then
                        if v == ply then
                            surface.SetDrawColor(Color(250,140,0,20))
                            surface.DrawRect(0, 0, w, h)
                        end
                    local name = v:Nick()
                    if v:IsBot() and v:GetNWString("SpecialBotName") != "" then
                        name = v:GetNWString("SpecialBotName")
                    end
                    local frags = v:Frags()
                    local deaths = v:Deaths()
                    local ping = v:Ping()
                    draw.SimpleText(name,"CenterPrintText", w * .058, h * 0.08, Color(250,140,0,255) )
                    draw.SimpleText(frags,"CenterPrintText", w * 0.655, h * 0.08, Color(250,140,0,255) )
                    draw.SimpleText(deaths,"CenterPrintText", w * 0.73, h * 0.08, Color(250,140,0,255) )
                    draw.SimpleText(ping,"CenterPrintText", w * 0.795, h * 0.08, Color(250,140,0,255) )
                    end
                end
                
                local mutebutton = vgui.Create("DButton", Panel)
                mutebutton:SetPos(ScrW() * 0.6 ,ypos-3)
                mutebutton:SetSize(32, 32) 
                mutebutton:SetText("")
                
                mutebutton.Paint = function(self, w, h)
                    if !v:IsValid() then return end
                    local isMuted = v:IsMuted()
                    surface.SetDrawColor(Color(0,0,0))
                    if isMuted then
                        surface.SetMaterial(muted)
                    else
                        surface.SetMaterial(unmuted)
                    end
                    surface.DrawTexturedRect(0, 0, w * 0.9, h * 0.9)
                end

                mutebutton.DoClick = function()
                    v:SetMuted(not v:IsMuted())
                end
                ypos = ypos + playerpanel:GetTall() * 1.1

            else
                table.insert(specnames, v:Name())
            end
        end

        if #specnames > 0 then
            local specStr = table.concat(specnames, ", ")
            local specpanel = vgui.Create("DPanel",Panel,"SpectatorPanel")
            specpanel:SetPos(0, Panel:GetTall()* 0.95)
            specpanel:SetSize(Panel:GetWide(), Panel:GetTall() * 0.025)

            specpanel.Paint = function(self, w, h)
                draw.SimpleText(specStr, "HudHintTextLarge", w * 0.14, h * 0.5, Color(128, 128, 128), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    else
        if IsValid(Panel) then
            Panel:Remove()
        end
    end
    return toggle
end

function GM:ScoreboardShow()
    if issb == true then
        return false
    end
    ply = LocalPlayer()
    Scoreboard(true)
    issb = true
end

function GM:ScoreboardHide()
    Scoreboard(false)
    issb = false
end