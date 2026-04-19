hook.Add( "PreRegisterSWEP", "ReplaceFunction", function( swep, class )
    if class == "weapon_hl1_mp5" then
        SWEP.Secondary.DefaultClip = 0
    end
end)