module( "better_flashlight", package.seeall )

-- Sounds
Sounds = {
    Sound( "better_flashlight/deploy.ogg" ),
    Sound( "better_flashlight/holster.ogg" ),
    Sound( "better_flashlight/toggle.ogg" )
}

-- Base Functions
function Get( ply )
    return ply["Better Flashlight"]
end

function Set( ply, flashlight )
    ply["Better Flashlight"] = flashlight
end

-- Control Functions
do

    local net_Start = net.Start
    local net_WriteUInt = net.WriteUInt
    local net_SendToServer = net.SendToServer

    -- Enable
    function Enable()
        net_Start( "Better Flashlight" )
            net_WriteUInt( 0, 2 )
        net_SendToServer()
    end

    -- Disable
    function Disable()
        net_Start( "Better Flashlight" )
            net_WriteUInt( 1, 2 )
        net_SendToServer()
    end

    function Toggle()
        net_Start( "Better Flashlight" )
            net_WriteUInt( 2, 2 )
        net_SendToServer()
    end

end

-- Player Functions
do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:GetFlashlight()
        return Get( self )
    end

    -- IsOn
    function PLAYER:FlashlightIsOn()
        return self:GetNWBool( "Better Flashlight", false ) and not self:GetNWBool( "Better Flashlight No Power", false )
    end

    -- Flashlight Allow
    function PLAYER:AllowFlashlight()
    end

    -- Can Use
    do

        local mp_flashlight = "mp_flashlight"
        local math_random = math.random
        local cvars_Bool = cvars.Bool
        local gmod_suit = "gmod_suit"
        local CurTime = CurTime

        -- Flashlight Allow
        function PLAYER:IsFlashlightAllowed()
            return self:GetNWBool( "Better Flashlight Allowed", true ) and game.GetWorld():GetNWBool( mp_flashlight, false )
        end

        -- HEV Suit
        function PLAYER:IsSuitNoPower()
            return cvars_Bool( gmod_suit ) and self:IsSuitEquipped() and (self:GetSuitPower() < 5)
        end

        function PLAYER:CanUseFlashlight()
            if self:GetNWBool( "Better Flashlight No Power", false ) then
                return false
            end

            if (self["Better Flashlight Delay"] or 0) > CurTime() then
                return false
            end

            if self:FlashlightIsOn() then
                self["Better Flashlight Delay"] = CurTime() + math_random( 6, 10 ) / 10
                return true
            end

            if self:IsFlashlightAllowed() then
                if self:Alive() then
                    if self:IsSuitNoPower() then
                        return false
                    end

                    self["Better Flashlight Delay"] = CurTime() + math_random( 6, 10 ) / 10
                    return true
                end
            end

            return false
        end

    end

    -- ShouldDrawLocalFlashlight
    do

        local index
        hook.Add("RenderScene", "Better Flashlight", function()
            hook.Remove( "RenderScene", "Better Flashlight" )
            index = LocalPlayer():EntIndex()
        end)

        function PLAYER:ShouldDrawLocalFlashlight()
            if (index == self:EntIndex()) then
                if (VManip == nil) then
                    return false
                end

                if self:ShouldDrawLocalPlayer() then
                    return false
                end

                return true
            end

            return false
        end

    end

end

-- Flashlight Controls
do
    local timer_Simple = timer.Simple
    hook.Add("PlayerBindPress", "Better Flashlight", function( ply, bind, pressed )
        if (bind == "impulse 100") then
            if (pressed) and ply:CanUseFlashlight() then
                if ply:ShouldDrawLocalPlayer() or (VManip == nil) then
                    Toggle()
                    return true
                end

                if (VManip:GetCurrentAnim() == "Flashlight_In") or (VManip:GetCurrentAnim() == "Flashlight_Shoulder_Take") then
                    if VManip:PlaySegment( "Flashlight_Out", true ) then
                        timer_Simple(0.3, function()
                            if IsValid( ply ) then
                                ply:EmitSound( Sounds[2] )
                            end

                            Disable()
                        end)
                    end
                elseif VManip:PlayAnim( "Flashlight_In" ) then
                    ply:EmitSound( Sounds[1] )
                    timer_Simple(0.4, function()
                        Enable()
                    end)
                end
            end

            return true
        end
    end)
end

-- Net Action
net.Receive("Better Flashlight", function()
    if (VManip == nil) or VManip:IsActive() then
        return
    end

    local ply = LocalPlayer()
    if IsValid( ply ) and ply:Alive() then
        VManip:PlaySegment( "Flashlight_Out", true )
        ply:EmitSound( Sounds[2] )
    end
end)

-- Create Flashlight
do

    local ProjectedTexture = ProjectedTexture
    local texture = "effects/flashlight001"
    local white = color_white
    local IsValid = IsValid
    local ipairs = ipairs

    list = {}

    timer.Create("Better Flashlight", 1, 0, function()
        for num, data in ipairs( list ) do
            if IsValid( data[1] ) then
                if IsValid( data[2] ) then
                    continue
                end

                data[1]:Remove()
            end

            table.remove( list, num )
        end
    end)

    function GetList()
        return list
    end

    function Create( ply )
        local flashlight = ProjectedTexture()
        flashlight:SetEnableShadows( true )
        flashlight:SetShadowFilter( 0 )
        flashlight:SetTexture( texture )
        flashlight:SetColor( white )
        flashlight:SetFarZ( 824 )

        table.insert( list, { flashlight, ply } )

        if IsValid( ply ) and ply:IsPlayer() then
            flashlight:SetFOV( ply:GetFOV() )
        end

        return flashlight
    end

end

-- Flashlight posing in world and flashlight creating
do

    local flashlight_attachment = "FlashLight"
    local player_GetHumans = player.GetHumans
    local angleOffset = Angle( 180, -10, 0 )
    local eyes_attachment = "eyes"
    local IsValid = IsValid
    local ipairs = ipairs

    hook.Add("Think", "Better Flashlight", function()
        for num, ply in ipairs( player_GetHumans() ) do
            local flashlight = ply:GetFlashlight()
            if ply:FlashlightIsOn() then
                if IsValid( flashlight ) then
                    if ply:ShouldDrawLocalFlashlight() then
                        local vm = VManip:GetVMGesture()
                        if IsValid( vm ) then
                            local att = vm:LookupAttachment( flashlight_attachment )
                            if (att > 0) then
                                local posang = vm:GetAttachment( att )
                                flashlight:SetPos( posang.Pos - (posang.Ang:Forward() * 10) )
                                flashlight:SetAngles( posang.Ang + angleOffset )
                                flashlight:Update()
                                return
                            end
                        end
                    end

                    local attachment_id = ply:LookupAttachment( eyes_attachment )
                    if (attachment_id > 0) then
                        local attachment = ply:GetAttachment( attachment_id )
                        local ang = attachment.Ang
                        flashlight:SetPos( attachment.Pos + (ang:Forward() * 10) )
                        flashlight:SetAngles( ang )
                    else
                        flashlight:SetPos( ply:EyePos() )
                        flashlight:SetAngles( ply:EyeAngles() )
                    end

                    flashlight:Update()
                else
                    Set( ply, Create( ply ) )
                end
            elseif IsValid( flashlight ) then
                flashlight:Remove()
            end
        end
    end)

end