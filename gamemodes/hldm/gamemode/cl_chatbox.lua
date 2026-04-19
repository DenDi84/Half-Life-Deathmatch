HLChat = {}

local W, H = ScrW(), ScrH()

function HLChat.Create()
    HLChat.dframe = vgui.Create("DPanel")
    HLChat.dframe:SetSize(W * .25, H * .2)
    HLChat.dframe:SetPos(20, H * .7)
    HLChat.dframe.Paint = function() end

    HLChat.rich = vgui.Create("RichText", HLChat.dframe)
    HLChat.rich:SetPos(0, 0)
    HLChat.rich:SetSize(W * .25, H * .2 - 40)
    HLChat.rich:SetVerticalScrollbarEnabled(false)

    HLChat.rich.PerformLayout = function(self)
        self:SetFontInternal("ChatFont")
        self:SetBGColor(Color(0, 0, 0, 0))
        self:SetFGColor(color_black)
    end

    HLChat.richbg = vgui.Create("DPanel", HLChat.dframe)
    HLChat.richbg:SetPos(0, 0)
    HLChat.richbg:SetSize(W * .25, H * .2 - 40)
    HLChat.richbg:SetZPos(-1)
    HLChat.richbg.alpha = 0
    HLChat.richbg.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, self.alpha * 0.6))
    end

    HLChat.fadeTimer  = nil
    HLChat.fadeAlpha  = 0 
    HLChat.isfading   = false
    HLChat.richVisible = false

    HLChat.inputbg = vgui.Create("DPanel", HLChat.dframe)
    HLChat.inputbg:SetPos(0, H * .2 - 38)
    HLChat.inputbg:SetSize(W * .25, 38)
    HLChat.inputbg:SetVisible(false)
    HLChat.inputbg.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 180))
    end

    HLChat.text = vgui.Create("DTextEntry", HLChat.inputbg)
    HLChat.text:SetPos(5, 5)
    HLChat.text:SetSize(W * .25 - 15, 28)
    HLChat.text:SetDrawBackground(false)
    HLChat.text:SetTextColor(color_white)
    HLChat.text:SetVerticalScrollbarEnabled( false )
    

    HLChat.text.OnKeyCodeTyped = function(self, key)
        if key == KEY_ESCAPE then
            self:SetValue("")
            HLChat.Close()
        elseif key == KEY_ENTER then
            local msg = self:GetValue()
            if msg ~= "" then
                RunConsoleCommand("say", msg)
            end
            self:SetValue("")
            HLChat.Close()
        end
    end

    HLChat.dframe.Think = function(self)
        if HLChat.IsOpen then return end

        local now = CurTime()

        if HLChat.richVisible and not HLChat.isfading then
            if HLChat.fadeTimer and now > HLChat.fadeTimer then
                HLChat.isfading = true
            end
        end

        if HLChat.isfading then
            HLChat.fadeAlpha = HLChat.fadeAlpha - (FrameTime() / 1.5)
            if HLChat.fadeAlpha <= 0 then
                HLChat.fadeAlpha   = 0
                HLChat.isfading    = false
                HLChat.richVisible = false
            end
        end

        HLChat.rich:SetAlpha(math.Round(HLChat.fadeAlpha * 255))
        HLChat.richbg.alpha = HLChat.fadeAlpha
    end

    HLChat.IsOpen = false
end

function HLChat.AddMessage(ply, msg)
    if ply then
        HLChat.rich:InsertColorChange(255, 200, 50, 255)
        HLChat.rich:AppendText(ply:Nick() .. ": ")
    end
    HLChat.rich:InsertColorChange(250, 140, 0, 255)
    HLChat.rich:AppendText(msg .. "\n")

    HLChat.fadeAlpha   = 1
    HLChat.isfading    = false
    HLChat.richVisible = true
    HLChat.fadeTimer   = CurTime() + 5

    HLChat.rich:SetAlpha(255)
end

hook.Add("PlayerBindPress", "overrideChatbind", function(ply, bind, pressed)
    if bind == "messagemode" then
        HLChat.Open()
    elseif bind == "messagemode2" then
        HLChat.Open(true)
    else
        return
    end
end)

hook.Add( "OnPauseMenuShow", "DisableMenu", function()
	if HLChat.IsOpen == true then return false end
end )

hook.Add( "HUDShouldDraw", "noMoreDefault", function( name )
	if name == "CHudChat" then
		return false
	end
end )

hook.Add("OnPlayerChat", "HLChatReceivePlayer", function(ply, text, teamChat, isDead)
    if IsValid(ply) then
        HLChat.AddMessage(ply, text)
        surface.PlaySound("chat/talk.wav")
    end
    return true
end)

hook.Add("ChatText", "HLChatReceiveSystem", function(index, name, text, type)
    local ply = Player(index)
    if IsValid(ply) then return end
    
    HLChat.rich:InsertColorChange(255, 255, 255, 255)
    HLChat.rich:AppendText(text .. "\n")
    
    HLChat.fadeAlpha   = 1
    HLChat.isfading    = false
    HLChat.richVisible = true
    HLChat.fadeTimer   = CurTime() + 5
    HLChat.rich:SetAlpha(255)
end)

function HLChat.Open(bTeam)
    if HLChat.IsOpen then return end
    HLChat.IsOpen = true

    HLChat.fadeAlpha   = 1
    HLChat.isfading    = false
    HLChat.richVisible = true
    HLChat.rich:SetAlpha(255)

    HLChat.inputbg:SetVisible(true)

    HLChat.popup = vgui.Create("DFrame")
    HLChat.popup:SetSize(W, H)
    HLChat.popup:SetPos(0, 0)
    HLChat.popup:ShowCloseButton(false)
    HLChat.popup:SetTitle("")
    HLChat.popup:SetDraggable(false)
    HLChat.popup.Paint = function() end
    HLChat.popup:MakePopup()

    HLChat.text:SetParent(HLChat.popup)
    HLChat.text:SetPos(20 + 5, H * .7 + H * .2 - 33)
    HLChat.text:SetSize(W * .25 - 15, 28)
    HLChat.text:RequestFocus()
    HLChat.text:SetText("")

end

function HLChat.Close()
    if not HLChat.IsOpen then return end
    HLChat.IsOpen = false

    HLChat.text:SetParent(HLChat.inputbg)
    HLChat.text:SetPos(5, 5)
    HLChat.text:SetSize(W * .25 - 15, 28)

    HLChat.inputbg:SetVisible(false)

    HLChat.fadeTimer = CurTime() + 5

    if IsValid(HLChat.popup) then
        HLChat.popup:Remove()
        HLChat.popup = nil
    end
end

HLChat.Create()