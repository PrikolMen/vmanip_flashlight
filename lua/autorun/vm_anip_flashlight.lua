if (CLIENT) then

    -- Functions Localization
    local ProjectedTexture = ProjectedTexture
    local IsValid = IsValid

    -- Sounds
    local takeIn = Sound( "wbk/flashlight_takeIn.wav" )
    local takeOut = Sound( "wbk/flashlight_takeOut.wav" )

    -- Render Stuff
    local white = color_white
    local texture = "effects/flashlight001"

    do

        -- Functions Localization
        local CurTime = CurTime
        local math_random = math.random
        local timer_Simple = timer.Simple

        local net_Start = net.Start
        local net_WriteBool = net.WriteBool
        local net_SendToServer = net.SendToServer

        -- Flashlight Creating and blocking source flashlight
        hook.Add("PlayerBindPress", "VManip_Flashlight", function( ply, bind, pressed )
            if (bind == "impulse 100") then
                if (pressed) then
                    if (ply.VManip_Flashlight_Delay or 0) > CurTime() then
                        return true
                    end

                    ply.VManip_Flashlight_Delay = CurTime() + math_random( 6, 10 ) / 10

                    if ply:ShouldDrawLocalPlayer() then
                        local flashlight = VManip_Flashlight
                        if IsValid( flashlight ) then

                            net_Start( "VManip_Flashlight" )
                                net_WriteBool( false )
                            net_SendToServer()

                            flashlight:Remove()

                        else

                            net_Start( "VManip_Flashlight" )
                                net_WriteBool( true )
                            net_SendToServer()

                            local flashlight = ProjectedTexture()
                            flashlight:SetEnableShadows( true )
                            flashlight:SetFOV( ply:GetFOV() )
                            flashlight:SetShadowFilter( 0 )
                            flashlight:SetTexture( texture )
                            flashlight:SetColor( white )
                            flashlight:SetFarZ( 824 )

                            VManip_Flashlight = flashlight

                        end

                        return true
                    end

                    if (VManip:GetCurrentAnim() == "Flashlight_In") or (VManip:GetCurrentAnim() == "Flashlight_Shoulder_Take") then
                        if VManip:PlaySegment( "Flashlight_Out", true ) then
                            timer_Simple(0.3, function()
                                if IsValid( ply ) then
                                    net_Start( "VManip_Flashlight" )
                                        net_WriteBool( false )
                                    net_SendToServer()

                                    local flashlight = VManip_Flashlight
                                    if IsValid( flashlight ) then
                                        flashlight:Remove()
                                    end
                                end
                            end)

                            timer_Simple(0.5, function()
                                if IsValid( ply ) then
                                    ply:EmitSound( takeOut )
                                end
                            end)
                        end
                    else

                        if VManip:PlayAnim( "Flashlight_In" ) then
                            ply:EmitSound( takeIn )

                            timer_Simple(0.4, function()
                                if IsValid( ply ) then
                                    net_Start( "VManip_Flashlight" )
                                        net_WriteBool( true )
                                    net_SendToServer()

                                    local flashlight = VManip_Flashlight
                                    if IsValid( flashlight ) then
                                        flashlight:Remove()
                                    end

                                    local flashlight = ProjectedTexture()
                                    flashlight:SetEnableShadows( true )
                                    flashlight:SetFOV( ply:GetFOV() )
                                    flashlight:SetShadowFilter( 0 )
                                    flashlight:SetTexture( texture )
                                    flashlight:SetColor( white )

                                    VManip_Flashlight = flashlight

                                end
                            end)
                        end
                    end

                end

                return true
            end
        end)

    end

    do

        local function ThirdPersionRender( flashlight, ply )
            local attachment_id = ply:LookupAttachment( "eyes" )
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
        end

        local angleOffset = Angle( 180, -10, 0 )
        local function FirstPersionRender( flashlight, vm, ply )
            local att = vm:LookupAttachment( "FlashLight" )
            if (att > 0) then
                local posang = vm:GetAttachment( att )
                flashlight:SetPos( posang.Pos - (posang.Ang:Forward() * 10) )
                flashlight:SetAngles( posang.Ang + angleOffset )
                flashlight:Update()
            else
                ThirdPersionRender( flashlight, ply )
            end
        end

        local function LocalPlayerFlashlight( ply )
            local flashlight = VManip_Flashlight
            if IsValid( flashlight ) then
                if IsValid( ply ) then
                    if ply:Alive() then
                        if ply:ShouldDrawLocalPlayer() then
                            ThirdPersionRender( flashlight, ply )
                            return
                        end

                        local vm = VManip:GetVMGesture()
                        if IsValid( vm ) then
                            FirstPersionRender( flashlight, vm, ply )
                        else
                            ThirdPersionRender( flashlight, ply )
                        end
                    else
                        flashlight:Remove()
                    end
                end
            end
        end

        local function OtherPlayersFlashlight( ply )
            if ply:GetNWBool( "VManip_Flashlight", false ) then

                local flashlight = ply.VManip_Flashlight
                if IsValid( flashlight ) then
                    ThirdPersionRender( flashlight, ply )
                    return
                end

                local flashlight = ProjectedTexture()
                flashlight:SetEnableShadows( true )
                flashlight:SetShadowFilter( 0 )
                flashlight:SetTexture( texture )
                flashlight:SetColor( white )
                flashlight:SetFarZ( 824 )

                ply.VManip_Flashlight = flashlight
                flashlight:SetFOV( ply:GetFOV() )

            else

                local flashlight = ply.VManip_Flashlight
                if IsValid( flashlight ) then
                    flashlight:Remove()
                end

            end
        end

        local lpIndex
        hook.Add("RenderScene", "VManip_Flashlight", function()
            hook.Remove( "RenderScene", "VManip_Flashlight" )
            lpIndex = LocalPlayer():EntIndex()
        end)

        local player_GetHumans = player.GetHumans
        local ipairs = ipairs

        -- Flashlight posing in world and creating flashlight for other players
        hook.Add("Think", "VManip_Flashlight", function()
            for num, ply in ipairs( player_GetHumans() ) do
                if (lpIndex == ply:EntIndex()) then
                    LocalPlayerFlashlight( ply )
                else
                    OtherPlayersFlashlight( ply )
                end
            end
        end)

    end

end

-- Sounds
local switching = Sound( "wbk/flashlight_enable.wav" )

if (SERVER) then

    -- Disable source flashlight
    hook.Add("PlayerSwitchFlashlight", "VManip_Flashlight", function( ply, state )
        if not state then
            return
        end

        return false
    end)

    hook.Add("PlayerDeath", "VManip_Flashlight", function( ply )
        ply:SetNWBool( "VManip_Flashlight", false )
    end)

    util.AddNetworkString( "VManip_Flashlight" )

    local net_ReadBool = net.ReadBool
    local CurTime = CurTime

    local delayList = {}
    net.Receive("VManip_Flashlight", function( len, ply )
        local time = CurTime()
        if (delayList[ ply:EntIndex() ] or 0) > time then
            ply:Kick( "Please don't spam with a flashlight!" )
            return
        end

        delayList[ ply:EntIndex() ] = time + 0.5

        ply:SetNWBool( "VManip_Flashlight", net_ReadBool() )
        ply:EmitSound( switching )
    end)

end
