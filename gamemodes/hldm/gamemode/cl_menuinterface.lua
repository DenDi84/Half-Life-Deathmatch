local Colorscheme = {
    ["MAIN_GREEN"] = Color(76, 88, 68),
    ["SELECTED"] = Color(152, 137, 54),
    ["HIGHTLIGHT"] = Color(116, 128, 108),
    ["SHADOW"] = Color(36, 48, 28),
    ["DARK"] = Color(62, 70, 55),
    ["TEXTWHITE"] = Color(160,170,149)
}

local HudThemes = {

    "Half-Life",
    "Half-life (320x240)",
    "Half-Life: Opposing Force",
    "Half-Life: Opposing Force (320x200)",
    "Half-Life: Opposing Force PRESS DEMO",
    "Half-Life: Blue Shift",
    "Half-Life: Decay (Gina Cross)",
    "Half-Life: Decay (Colette Green)",
    "Counter-Strike",
    "Counter-Strike: Condition Zero Deleted Scenes",
    "Sven Co-op",
    "They Hunger",
    "Afraid of Monster\'s: Director\'s cut",
    "Half-Life 1.5: Weapon Edition",
    "Half-Life: Echoes",
    "Brutal Half-Life",
    "Half-Nuked",

}

local VocoderTypes = {

    "Male",
    "Female",

}

surface.CreateFont("Tahoma", {
    font = "Tahoma", size = 24, weight = 500, antialias = false
})
surface.CreateFont("TahomaSmaller", {
    font = "Tahoma", size = 18, weight = 500, antialias = false
})

MainMenu = {}

local modelFiles = file.Find("models/player/hl1/*.mdl", "GAME")
local lastselectedmodel = lastselectedmodel or "models/player/hl1/player.mdl"


local function outliner(w, h, isactive, istab, inv)
    isactive = isactive or false
    istab = istab or false
    inv = inv or false

    local baseButtonColor = Colorscheme["MAIN_GREEN"]
    local highlightColor = Colorscheme["HIGHTLIGHT"]
    local shadowColor = Colorscheme["SHADOW"]

    if not inv then
        surface.SetDrawColor(highlightColor)
        surface.DrawRect(0, 0, w, 1)     
        surface.DrawRect(0, 1, 1, h - 1)   

        if istab then
            if isactive then
                surface.SetDrawColor(baseButtonColor)
                surface.DrawRect(1, h - 1, w - 1, 1) 
            else
                surface.SetDrawColor(highlightColor)
                surface.DrawRect(1, h - 1, w - 1, 1) 
            end
        else
            surface.SetDrawColor(shadowColor)
            surface.DrawRect(1, h - 1, w - 1, 1) 
        end
        surface.SetDrawColor(shadowColor)
        surface.DrawRect(w - 1, 0, 1, h - 1) 
    else
        surface.SetDrawColor(shadowColor)
        surface.DrawRect(0, 0, w, 1)     
        surface.DrawRect(0, 1, 1, h - 1)   
        surface.SetDrawColor(highlightColor)
        surface.DrawRect(1, h - 1, w - 1, 1) 
        surface.DrawRect(w - 1, 0, 1, h - 1)

    end
end

local function checkboxes(labeltext,parent,x,y,cmd)


    local checkboxlabel = vgui.Create("DCheckBoxLabel", parent)
    checkboxlabel:SetPos( x, y )						-- Set the position
	checkboxlabel:SetText(labeltext)					-- Set the text next to the box
	checkboxlabel:SetConVar(cmd)				-- Change a ConVar when the box it ticked/unticked
	checkboxlabel:SizeToContents()
    checkboxlabel:SetChecked( false )


    local checkbox = checkboxlabel.Button
    checkbox.Paint = function(self,w,h)

        local boxSize = h  
        local boxY = (h - boxSize) / 2 

        if self:GetChecked() then

        local check_p1 = { x = w * 0.2, y = h * 0.5 }
        local check_p2 = { x = w * 0.45, y = h * 0.75 }
        local check_p3 = { x = w * 0.8, y = h * 0.25 }

        
        surface.SetDrawColor(color_white)
        surface.DrawLine(check_p1.x, boxY + check_p1.y, check_p2.x, boxY + check_p2.y)
        surface.DrawLine(check_p2.x, boxY + check_p2.y, check_p3.x, boxY + check_p3.y-1)
    end

        outliner(w,h)

    end
    local checklabel = checkboxlabel.Label
    checklabel.Paint = function(self,w,h)

        if checkbox:GetChecked() then
            self:SetTextColor(Colorscheme["SELECTED"])
        else
            self:SetTextColor(color_white)
        end
        
    end
end


local activebutton = nil

local function tabsheet(self, w, h)
    local mainColor = Colorscheme["MAIN_GREEN"]
    surface.SetDrawColor(mainColor)
    surface.DrawRect(1, 1, w - 2, h - 2)

    surface.SetFont("TahomaSmaller")
    surface.SetTextColor(color_white)
    surface.SetTextPos(w / 12, (h / 12) + 1)
    surface.DrawText(self.buttontext)

    outliner(w, h, activebutton == self, true)
end

local function bottombuttons(buttontext, parent, x, y, onClickFunction)
    local dbut = vgui.Create("DButton", parent)
    local bW, bH = 75, 25
    dbut:SetSize(bW, bH)
    dbut:SetPos(x, y)
    dbut:SetText("")
    dbut.DoClick = onClickFunction

    dbut.Paint = function(self, w, h)
        local baseButtonColor = Colorscheme["MAIN_GREEN"]
        local highlightColor = Color(baseButtonColor.r + 40, baseButtonColor.g + 40, baseButtonColor.b + 40)
        local shadowColor = Color(baseButtonColor.r - 40, baseButtonColor.g - 40, baseButtonColor.b - 40)
        local mainColor = baseButtonColor

        if self:IsDown() then
            mainColor = shadowColor
            local temp = highlightColor
            highlightColor = shadowColor
            shadowColor = temp
        elseif self:IsHovered() then
            mainColor = highlightColor
        end

        outliner(w, h)
        surface.SetDrawColor(mainColor)
        surface.DrawRect(1, 1, w - 2, h - 2)
        surface.SetFont("TahomaSmaller")
        surface.SetTextColor(color_white)
        surface.SetTextPos(w / 12, (h / 12) + 1)
        surface.DrawText(buttontext)
    end
    return dbut
end

local DermaPanel
function MainMenu:Show()
    if IsValid(DermaPanel) then DermaPanel:Remove() end


    lastselectedmodel = GetConVar("hldm_cl_playermodel"):GetString()
    if lastselectedmodel == "" or lastselectedmodel == "models/player.mdl" then
        lastselectedmodel = "models/player/hl1/player.mdl" 
    end

    local pW, pH = 630, 470
    local margin = 15
    local steamMat = Material("vgui/resource/icon_steam")

    DermaPanel = vgui.Create("DFrame")
    DermaPanel:SetSize(pW, pH)
    DermaPanel:Center()
    DermaPanel:SetTitle("")
    DermaPanel:SetDraggable(false)
    DermaPanel:MakePopup()
    DermaPanel:ShowCloseButton(false)
    DermaPanel.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Colorscheme["MAIN_GREEN"])
        draw.SimpleText("Main menu", "Tahoma", 100, 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        surface.SetMaterial(steamMat)
        surface.DrawTexturedRect(margin, margin, 24, 24)
        outliner(w, h)
    end

    local closeButton = vgui.Create("DButton", DermaPanel)
    closeButton:SetSize(25, 25)
    closeButton:SetPos(pW - 25 - margin, margin)
    closeButton:SetText("")
    closeButton.DoClick = function() DermaPanel:Close() end
    local iconStop = Material("gui/html/stop")
    closeButton.Paint = function(self, w, h)
        local baseButtonColor = Colorscheme["MAIN_GREEN"]
        local highlightColor = Color(baseButtonColor.r + 40, baseButtonColor.g + 40, baseButtonColor.b + 40)
        local shadowColor = Color(baseButtonColor.r - 40, baseButtonColor.g - 40, baseButtonColor.b - 40)
        local mainColor = baseButtonColor
        if self:IsDown() then mainColor = shadowColor
        elseif self:IsHovered() then mainColor = highlightColor end
        outliner(w, h)
        surface.SetDrawColor(mainColor)
        surface.DrawRect(1, 1, w - 2, h - 2)
        surface.SetDrawColor(color_white)
        surface.SetMaterial(iconStop)
        surface.DrawTexturedRect((w - 16) / 2, (h - 16) / 2, 16, 16)
    end


    local insideframe = vgui.Create("DFrame", DermaPanel)
    insideframe:SetSize(pW * 0.952, pH * 0.75)
    insideframe:SetPos(margin, 80)
    insideframe:SetTitle("")
    insideframe:SetDraggable(false)
    insideframe:ShowCloseButton(false)
    insideframe.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Colorscheme["MAIN_GREEN"])
        outliner(w, h)
    end
    
    local panels = {}
    local function OpenMenuPanel(panelToOpen)
        for name, panel in pairs(panels) do
            if IsValid(panel) then panel:SetVisible(false) end
        end
        if panelToOpen and IsValid(panelToOpen) then panelToOpen:SetVisible(true) end
    end

    local playermodelTabPanel = vgui.Create("DPanel", insideframe)
    playermodelTabPanel:Dock(FILL)
    playermodelTabPanel:DockMargin(0,-16,0,0)
    playermodelTabPanel.Paint = nil 

    panels.playermodels = playermodelTabPanel 

    local modelListFrame = vgui.Create("DFrame", playermodelTabPanel)
    modelListFrame:SetSize(pW * 0.5, pH * 0.7)
    modelListFrame:SetPos(0, 0) 
    modelListFrame:SetTitle("Playermodels")
    modelListFrame:SetDraggable(false)
    modelListFrame:ShowCloseButton(false)
    modelListFrame.Paint = function(self, w, h) outliner(w, h) end

    local DDScrollPanel = vgui.Create("DScrollPanel", modelListFrame)
    DDScrollPanel:Dock(FILL)

    local iconLayout = vgui.Create("DIconLayout", DDScrollPanel)
    iconLayout:Dock(FILL)
    iconLayout:SetSpaceX(5)
    iconLayout:SetSpaceY(5)
    iconLayout:DockPadding(5, 5, 5, 5)


    local Dmodelframe = vgui.Create("DFrame", playermodelTabPanel) 
    Dmodelframe:SetSize(pW * 0.4, pH * 0.7)
    Dmodelframe:SetPos(modelListFrame:GetWide() + margin, 0) 
    Dmodelframe:SetTitle("Playermodel")
    Dmodelframe:SetDraggable(false)
    Dmodelframe:ShowCloseButton(false)
    Dmodelframe.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, color_black)
        outliner(w, h)
    end
    
    local showedpm = vgui.Create("DModelPanel", Dmodelframe)
    --showedpm:Dock(FILL)
    showedpm:SetSize(pW * .55, pH * .65 )
    --showedpm:SetSize(400, 500 )
    showedpm:Center()
    showedpm:SetModel(lastselectedmodel)
    function showedpm:LayoutEntity(Entity) return end 
    function showedpm.Entity:GetPlayerColor() return Vector(1, 1, 1) end 

  
    local nextsend = CurTime()
    for k, v in ipairs(modelFiles) do
        local Icon = iconLayout:Add("SpawnIcon")
        Icon:SetSize(67, 67)
        Icon:SetModel("models/player/hl1/" .. v)
        Icon.DoClick = function(self)

            lastselectedmodel = self:GetModelName()
            if IsValid(showedpm) then
                showedpm:SetModel(lastselectedmodel)
            end

        end
    end

    local optionsTabPanel = vgui.Create("DPanel", insideframe)
    optionsTabPanel:Dock(FILL)
    optionsTabPanel:DockMargin(0,-25,0,0)
    optionsTabPanel.Paint = nil
    panels.options = optionsTabPanel 

    local hudthemestext = vgui.Create("DLabel",optionsTabPanel)
    hudthemestext:SetPos(margin,margin/2+1)
    hudthemestext:SetText("Select HUD theme")
    hudthemestext:SizeToContents()

    local isopened = false

    local hudthemeselector = vgui.Create("DComboBox",optionsTabPanel)
    hudthemeselector:SetSize(200,30)
    hudthemeselector:SetPos(margin,margin*2)
    hudthemeselector:SetValue("Select HUD")
    hudthemeselector:SetTextColor( color_white )
    hudthemeselector:SetFont("TahomaSmaller")
    for k,v in ipairs(HudThemes) do
        hudthemeselector:AddChoice(v)
    end
    hudthemeselector.OnSelect = function(self,index,value)
        RunConsoleCommand("gsrchud_theme", index)
        isopened = false
    end
    hudthemeselector.Paint = function(self,w,h)
        draw.RoundedBox(2, 0, 0, w, h, Colorscheme["DARK"])
        outliner(w,h,false,false,true)
    end

    local function hudopen()
        if not isopened then
            hudthemeselector:OpenMenu()
            local theMenu = hudthemeselector.Menu
            local menupanel = theMenu.Panel
            menupanel:SetWidth(200)
            theMenu:SetWidth(200)
            --print(menupanel)
            theMenu.Paint = function(self,w,h) --
                draw.RoundedBox(2, 0, 0, w, h, Colorscheme["MAIN_GREEN"])
                outliner(w,h,false,false,true)
            end
            local items = theMenu.Panel:GetCanvas():GetChildren()
            for _, v in ipairs(items) do 
               --print("v in cycle: ", v)
                --print("v:classname : ", v:GetClassName())
                if IsValid(v) and v:GetClassName() == "Label" then
                    v:SetWidth(200)
                    v.Paint = function(self,w,h)
                        self:SetTextColor( Colorscheme["TEXTWHITE"] )
                        if self:IsHovered() then
                            draw.RoundedBox(2, 0, 0, w, h, Colorscheme["SELECTED"])
                            self:SetTextColor( color_white )
                        end
                    end


                end
            end

            isopened = true
        else
            hudthemeselector:CloseMenu()
            isopened = false
        end
    end
    hudthemeselector.DoClick = function(self)
        hudopen()
    end



    local vocodertext = vgui.Create("DLabel",optionsTabPanel)
    vocodertext:SetPos(margin*26-5,margin/2+1)
    vocodertext:SetText("Select Voice Modulator")
    vocodertext:SizeToContents()

    local insideframepanelW = optionsTabPanel:GetWide()
    local vocoderselector = vgui.Create("DComboBox",optionsTabPanel)
    vocoderselector:SetSize(200,30)
    vocoderselector:SetPos(margin*26-5,margin*2)
    vocoderselector:SetValue("Select Voice Modulator")
    vocoderselector:SetTextColor( color_white )
    vocoderselector:SetFont("TahomaSmaller")
    for k,v in ipairs(VocoderTypes) do
        vocoderselector:AddChoice(v)
    end
    vocoderselector.OnSelect = function(self,index,value)
        RunConsoleCommand("hldm_vocoder", value:lower())
        isopened = false
    end
    vocoderselector.Paint = function(self,w,h)
        draw.RoundedBox(2, 0, 0, w, h, Colorscheme["DARK"])
        outliner(w,h,false,false,true)
    end

    local function vocoderopen()
        if not isopened then
            vocoderselector:OpenMenu()
            local theMenu = vocoderselector.Menu
            local menupanel = theMenu.Panel
            menupanel:SetWidth(200)
            theMenu:SetWidth(200)
            --print(menupanel)
            theMenu.Paint = function(self,w,h) --
                draw.RoundedBox(2, 0, 0, w, h, Colorscheme["MAIN_GREEN"])
                outliner(w,h,false,false,true)
            end
            local items = theMenu.Panel:GetCanvas():GetChildren()
            for _, v in ipairs(items) do 
                if IsValid(v) and v:GetClassName() == "Label" then
                    v:SetWidth(200)
                    v.Paint = function(self,w,h)
                        self:SetTextColor( Colorscheme["TEXTWHITE"] )
                        if self:IsHovered() then
                            draw.RoundedBox(2, 0, 0, w, h, Colorscheme["SELECTED"])
                            self:SetTextColor( color_white )
                        end
                    end
                end
            end

            isopened = true
        else
            vocoderselector:CloseMenu()
            isopened = false
        end
    end
    vocoderselector.DoClick = function(self)
        vocoderopen()
    end

    local hudsizetext = vgui.Create("DLabel",optionsTabPanel)
    hudsizetext:SetPos(margin,margin*6)
    hudsizetext:SetText("HUD Scale: ")
    hudsizetext:SizeToContents()

    local scaleslide = vgui.Create("DNumSlider", optionsTabPanel)
    scaleslide:SetPos(-128,margin*7)
    scaleslide:SetSize( 350, 25 )			-- Set the size
    scaleslide:SetMin( 0.5 )				 	-- Set the minimum number you can slide to
    scaleslide:SetMax( 3 )				-- Set the maximum number you can slide to
    scaleslide:SetDecimals( 2 )				-- Decimal places - zero for whole number
    scaleslide:SetConVar( "gsrchud_scale" )	-- Changes the ConVar when you slide

    local slideline = scaleslide.Slider 
    slideline.Paint = function(self,w,h)

        draw.RoundedBox(2, 0, h/3, w, h/4, Colorscheme["DARK"])
        --outliner(w,h,false,false,true)

        local strokesnum = 25
        local stripeX = 7
        for i = 0, strokesnum do
            local stripeX = stripeX + 29*i
            surface.SetDrawColor(Colorscheme["HIGHTLIGHT"])
            surface.DrawRect(stripeX, 16, 1, 10)
        end

    end

    local hudsizetext = vgui.Create("DLabel",optionsTabPanel)
    hudsizetext:SetPos(margin,margin*11)
    hudsizetext:SetText("HUD Alpha: ")
    hudsizetext:SizeToContents()

    local alphaslide = vgui.Create("DNumSlider", optionsTabPanel)
    alphaslide:SetPos(-128,margin*12)
    alphaslide:SetSize( 350, 25 )			-- Set the size
    alphaslide:SetMin( 0 )				 	-- Set the minimum number you can slide to
    alphaslide:SetMax( 255 )				-- Set the maximum number you can slide to
    alphaslide:SetDecimals( 0 )				-- Decimal places - zero for whole number
    alphaslide:SetConVar( "gsrchud_alpha" )	-- Changes the ConVar when you slide

    local alphaline = alphaslide.Slider 
    alphaline.Paint = function(self,w,h)

        draw.RoundedBox(2, 0, h/3, w, h/4, Colorscheme["DARK"])
        --outliner(w,h,false,false,true)

        local strokesnum = 25
        local stripeX = 7
        for i = 0, strokesnum do
            local stripeX = stripeX + 36*i
            surface.SetDrawColor(Colorscheme["HIGHTLIGHT"])
            surface.DrawRect(stripeX, 16, 1, 10)
        end

    end

    
    local viewlabel = vgui.Create("DLabel",optionsTabPanel)
    viewlabel:SetPos(margin*26-5,margin*6)
    viewlabel:SetText("Viewmodel FOV: ")
    viewlabel:SizeToContents()

    local viewslider = vgui.Create("DNumSlider", optionsTabPanel)
    viewslider:SetPos(margin*16,margin*7)
    viewslider:SetSize( 350, 25 )			-- Set the size
    viewslider:SetMin( 60 )				 	-- Set the minimum number you can slide to
    viewslider:SetMax( 120 )				-- Set the maximum number you can slide to
    viewslider:SetDecimals( 0 )				-- Decimal places - zero for whole number
    viewslider:SetConVar( "hl1_cl_viewmodelfov" )	-- Changes the ConVar when you slide

    local vmslider = viewslider.Slider 
    vmslider.Paint = function(self,w,h)

        draw.RoundedBox(2, 0, h/3, w, h/4, Colorscheme["DARK"])
        --outliner(w,h,false,false,true)

        local strokesnum = 25
        local stripeX = 7
        for i = 0, strokesnum do
            local stripeX = stripeX + 36*i
            surface.SetDrawColor(Colorscheme["HIGHTLIGHT"])
            surface.DrawRect(stripeX, 16, 1, 10)
        end

    end


    local aimscaletext = vgui.Create("DLabel",optionsTabPanel)
    aimscaletext:SetPos(margin*26-5,margin*11)
    aimscaletext:SetText("Size of Custom Crosshair: ")
    aimscaletext:SizeToContents()

    local aimscale = vgui.Create("DNumSlider", optionsTabPanel)
    aimscale:SetPos(margin*16,margin*12)
    aimscale:SetSize( 350, 25 )			-- Set the size
    aimscale:SetMin( 1 )				 	-- Set the minimum number you can slide to
    aimscale:SetMax( 5 )				-- Set the maximum number you can slide to
    aimscale:SetDecimals( 2 )				-- Decimal places - zero for whole number
    aimscale:SetConVar( "hl1_cl_crosshair_scale" )	-- Changes the ConVar when you slide

    local aimslider = aimscale.Slider 
    aimslider.Paint = function(self,w,h)

        draw.RoundedBox(2, 0, h/3, w, h/4, Colorscheme["DARK"])
        --outliner(w,h,false,false,true)

        local strokesnum = 25
        local stripeX = 7
        for i = 0, strokesnum do
            local stripeX = stripeX + 29*i
            surface.SetDrawColor(Colorscheme["HIGHTLIGHT"])
            surface.DrawRect(stripeX, 16, 1, 10)
        end

    end


    local denicon = Material("creditsicons/denicon.jpg", "noclamp smooth")
    local upseticon = Material("creditsicons/upset.jpg", "noclamp smooth")
    local seregaicon = Material("creditsicons/sereganeon.jpg", "noclamp smooth")
    local dyametricon = Material("creditsicons/dyametr.jpg", "noclamp smooth")
    local creditsTabPanel = vgui.Create("DPanel", insideframe)
    creditsTabPanel:Dock(FILL)
    creditsTabPanel:DockMargin(0,-25,0,0)
    creditsTabPanel.Paint = function(self,w,h)
        surface.SetMaterial(denicon)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(margin*2, margin, 64, 64)

        surface.SetMaterial(seregaicon)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(margin*2, margin*6, 64, 64)

        surface.SetMaterial(upseticon)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(margin*2, margin*11, 64, 64)

        surface.SetMaterial(dyametricon)
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(margin*2, margin*16, 64, 64)

        surface.SetTextColor(Color(0,140,255))
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin+1)
        surface.DrawText("DenDi85")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*3)
        surface.DrawText("Main Developer of HLDM Gamemode")

        surface.SetTextColor(Color(199,0,0))
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*6+1)
        surface.DrawText("Sereganeon")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*8)
        surface.DrawText("Fixing and adaptation maps from HLDM:Source to GMod")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*11+1)
        surface.DrawText("Upset")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*13+1)
        surface.DrawText("SWEPs, other code fragments and solutions from HL:COOP")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*16+1)
        surface.DrawText("DyaMetR")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*7+5,margin*18+1)
        surface.DrawText("HUD")

        surface.SetTextColor(color_white)
        surface.SetFont("TahomaSmaller")
        surface.SetTextPos(margin*8+5,margin*21+5)
        surface.DrawText("The Alium community - testing, advising and feedback")
    end

    panels.credits = creditsTabPanel

    checkboxes("HUD Filter",optionsTabPanel,margin,margin*16,"gsrchud_filter")

    checkboxes("HL2 ViewBob",optionsTabPanel,margin*26,margin*16,"hl1_cl_hl2bob")

    checkboxes("WON Viewbob",optionsTabPanel,margin*26,margin*18,"hl1_cl_bob_won")

    checkboxes("Enable Custom Crosshair",optionsTabPanel,margin*26,margin*20,"hl1_cl_crosshair")

    bottombuttons("Reset", optionsTabPanel, margin, margin*19, function() RunConsoleCommand("gsrchud_reset") RunConsoleCommand("gsrchud_loading",0) end)
    
    

    local bW, bH = 75, 25
    local upsize = -3
    
    local optionsbutton = vgui.Create("DButton", DermaPanel)
    optionsbutton:SetSize(bW, bH)
    optionsbutton:SetPos(15, 56)
    optionsbutton:SetText("")
    optionsbutton.buttontext = "Options"
    optionsbutton.Paint = tabsheet

    local pmbutton = vgui.Create("DButton", DermaPanel)
    local pmbW = optionsbutton:GetPos() + bW + 1
    pmbutton:SetSize(bW + 25, bH)
    pmbutton:SetPos(pmbW, 56)
    pmbutton:SetText("")
    pmbutton.buttontext = "Playermodels"
    pmbutton.Paint = tabsheet

    local creditsbutton = vgui.Create("DButton", DermaPanel)
    local cbbW = pmbutton:GetPos() + bW + 25 + 1
    creditsbutton:SetSize(bW, bH)
    creditsbutton:SetPos(cbbW, 56)
    creditsbutton:SetText("")
    creditsbutton.buttontext = "Credits"
    creditsbutton.Paint = tabsheet


    OpenMenuPanel(nil) 
    OpenMenuPanel(panels.options)


    local function UpdateButtonsState()

        if (activebutton == pmbutton) then
            pmbutton:SetSize(bW + 25, bH - upsize)
            pmbutton:SetPos(pmbW, 56 + upsize)
        else
            pmbutton:SetSize(bW + 25, bH)
            pmbutton:SetPos(pmbW, 56)
        end
        -- Кнопка Options
        if (activebutton == optionsbutton) then
            optionsbutton:SetSize(bW, bH - upsize)
            optionsbutton:SetPos(15, 56 + upsize)
        else
            optionsbutton:SetSize(bW, bH)
            optionsbutton:SetPos(15, 56)
        end

        if (activebutton == creditsbutton) then
            creditsbutton:SetSize(bW, bH - upsize)
            creditsbutton:SetPos(cbbW, 56 + upsize)
        else
            creditsbutton:SetSize(bW, bH)
            creditsbutton:SetPos(cbbW, 56)
        end
        
    end


    local function TabButtonClick(button, panel_to_toggle)
        if (activebutton == button) then
            --OpenMenuPanel(nil)
            activebutton = nil
        else
            OpenMenuPanel(panel_to_toggle)
            activebutton = button
        end
        UpdateButtonsState()
    end

    optionsbutton.DoClick = function(self)
        TabButtonClick(self, panels.options)
    end

    pmbutton.DoClick = function(self)
        TabButtonClick(self, panels.playermodels)
    end
    
    creditsbutton.DoClick = function(self)
        TabButtonClick(self, panels.credits)
    end
    
    bottombuttons("OK", DermaPanel, 370,438, function() 
        RunConsoleCommand("hldm_cl_playermodel", lastselectedmodel)
        DermaPanel:Close() 
    end)
    bottombuttons("Cancel", DermaPanel, 370+85,438, function() DermaPanel:Close() end)
    bottombuttons("Apply", DermaPanel, 370+170,438, function() 
        RunConsoleCommand("hldm_cl_playermodel", lastselectedmodel)
    end)
    bottombuttons("Spectate", DermaPanel, margin+1, 438, function() RunConsoleCommand("hldm_gotospec") end)
end

concommand.Add("hldm_mainmenu", function() MainMenu:Show() end)