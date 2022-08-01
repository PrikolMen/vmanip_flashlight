module( "better_flashlight", package.seeall )

-- Sounds
Sounds = {

    -- Basic Sounds
    Sound( "better_flashlight/deploy.ogg" ),
    Sound( "better_flashlight/holster.ogg" ),
    Sound( "better_flashlight/toggle.ogg" ),

    -- Shoulder Sounds
    Sound( "better_flashlight/shoulder_move_1.ogg" ),
    Sound( "better_flashlight/shoulder_move_2.ogg" ),
    Sound( "better_flashlight/shoulder_attach.ogg" ),
    Sound( "better_flashlight/shoulder_detach.ogg" )

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

    -- Toggle
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


-- Shoulder Mode
do

    Shoulder = false

    function SetShoulder( bool )
        Shoulder = bool == true
    end

    function IsShoulder()
        return Shoulder or false
    end

end

-- Flashlight is active
do

    local activeAnims = {
        ["Flashlight_Shoulder_Take"] = true,
        ["Flashlight_Shoulder_Put"] = true,
        ["Flashlight_In"] = true
    }

    function IsActive()
        return activeAnims[ VManip:GetCurrentAnim() ] or false
    end

end

-- Flashlight Controls
do
    local timer_Simple = timer.Simple

    concommand.Add("flashlight_shoulder", function( ply )
        if IsShoulder() then
            local anim = VManip:PlayAnim( "Flashlight_Shoulder_Take" )
            SetShoulder( anim )
            if anim then
                ply:EmitSound( Sounds[5] )

                timer_Simple(0.4 * FrameTime(), function()
                    if IsValid( ply ) then
                        ply:EmitSound( Sounds[7] )
                    end

                    timer_Simple(0.6 * FrameTime(), function()
                        VManip:PlayAnim( "Flashlight_In" )
                    end)
                end)
            end
        elseif IsActive() then
            local anim = VManip:PlaySegment( "Flashlight_Shoulder_Put", true )
            SetShoulder( anim )
            if anim then
                SetShoulder( true )
                ply:EmitSound( Sounds[4] )

                timer_Simple(0.1 * FrameTime(), function()
                    if IsValid( ply ) then
                        ply:EmitSound( Sounds[6] )
                    end
                end)
            end
        end
    end)

    function Impulse100( ply, bind, pressed )
        if (pressed) and ply:CanUseFlashlight() then
            if ply:ShouldDrawLocalPlayer() or (VManip == nil) then
                return Toggle()
            end

            if ply:KeyDown( IN_WALK ) then
                RunConsoleCommand("flashlight_shoulder")
                return
            end

            if IsActive() then

                if VManip:PlaySegment( "Flashlight_Out", true ) then
                    timer_Simple(0.3 * FrameTime(), function()
                        if IsValid( ply ) then
                            ply:EmitSound( Sounds[2] )
                            if ply:FlashlightIsOn() then
                                Disable()
                            end
                        end
                    end)
                end

            else

                if IsShoulder() then
                    if VManip:PlayAnim( "Flashlight_EnableDisable" ) then
                        ply:EmitSound( Sounds[5] )

                        timer_Simple(0.4 * FrameTime(), function()
                            if IsValid( ply ) then
                                ply:EmitSound( Sounds[2] )
                                if ply:FlashlightIsOn() then
                                    Disable()
                                else
                                    Enable()
                                end
                            end
                        end)
                    end

                    return
                end

                if VManip:IsActive() then return end
                if VManip:PlayAnim( "Flashlight_In" ) then
                    ply:EmitSound( Sounds[1] )
                    timer_Simple(0.4 * FrameTime(), function()
                        if IsValid( ply ) then
                            if ply:FlashlightIsOn() then
                                return
                            end

                            Enable()
                        end
                    end)
                end

            end

        end
    end

end

-- Impulse 100 Grabber
hook.Add("PlayerBindPress", "Better Flashlight", function( ply, bind, pressed )
    if (bind == "impulse 100") then
        Impulse100( ply, bind, pressed )
        return true
    end
end)

-- Net Action
do
    local timer_Simple = timer.Simple
    net.Receive("Better Flashlight", function()
        if (VManip == nil) then
            return
        end

        local ply = LocalPlayer()
        if IsValid( ply ) and ply:Alive() then
            if VManip:PlaySegment( "Flashlight_Out", true ) then
                timer_Simple(0.3 * FrameTime(), function()
                    if IsValid( ply ) then
                        ply:EmitSound( Sounds[2] )
                    end
                end)
            end
        end
    end)
end

-- Create Flashlight
do

    local ProjectedTexture = ProjectedTexture
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
        flashlight:SetTexture( ply:GetNWString( "Better Flashlight Texture", "effects/flashlight001" ) )
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