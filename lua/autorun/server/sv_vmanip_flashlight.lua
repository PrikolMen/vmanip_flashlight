local toggle_snd = Sound( "vmanip/flashlight/toggle.ogg" )

-- Disable source flashlight
hook.Add("PlayerSwitchFlashlight", "VManip_Flashlight", function( ply, state )
    if not state then
        return
    end

    return false
end)

-- Disable Flashlight after player death
hook.Add("PlayerDeath", "VManip_Flashlight", function( ply )
    ply:SetNWBool( "VManip_Flashlight", false )
end)

do

    util.AddNetworkString( "VManip_Flashlight" )

    local net_ReadBool = net.ReadBool
    local IsValid = IsValid
    local CurTime = CurTime

    local delayList = {}
    net.Receive("VManip_Flashlight", function( len, ply )
        if IsValid( ply ) then
            if (delayList[ ply:EntIndex() ] or 0) > CurTime() then
                ply:Kick( "Please don't spam with a flashlight!" )
                return
            end

            delayList[ ply:EntIndex() ] = CurTime() + 0.5

            ply:SetNWBool( "VManip_Flashlight", net_ReadBool() )
            ply:EmitSound( toggle_snd )
        end
    end)

end