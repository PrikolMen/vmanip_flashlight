-- Functions Localization
local ProjectedTexture = ProjectedTexture
local IsValid = IsValid

-- Sounds
local deploy_snd = Sound( "vmanip/flashlight/deploy.ogg" )
local holster_snd = Sound( "vmanip/flashlight/holster.ogg" )
local toggle_snd = Sound( "vmanip/flashlight/toggle.ogg" )

-- Flashlight Creating
local CreateFlashlight
do

    local white = color_white
    local texture = "effects/flashlight001"

    function CreateFlashlight()
        local flashlight = ProjectedTexture()
        flashlight:SetEnableShadows( true )
        flashlight:SetShadowFilter( 0 )
        flashlight:SetTexture( texture )
        flashlight:SetColor( white )
        flashlight:SetFarZ( 824 )
        return flashlight
    end

end

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

                        VManip_Flashlight = CreateFlashlight()
                        VManip_Flashlight:SetFOV( ply:GetFOV() )
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
                                ply:EmitSound( holster_snd )
                            end
                        end)
                    end
                else

                    if VManip:PlayAnim( "Flashlight_In" ) then
                        ply:EmitSound( deploy_snd )

                        timer_Simple(0.4, function()
                            if IsValid( ply ) then
                                net_Start( "VManip_Flashlight" )
                                    net_WriteBool( true )
                                net_SendToServer()

                                local flashlight = VManip_Flashlight
                                if IsValid( flashlight ) then
                                    flashlight:Remove()
                                end

                                VManip_Flashlight = CreateFlashlight()
                                VManip_Flashlight:SetFOV( ply:GetFOV() )
                            end
                        end)
                    end
                end

            end

            return true
        end
    end)

end

-- Flashlight Render
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

        ply.VManip_Flashlight = CreateFlashlight()
        ply.VManip_Flashlight:SetFOV( ply:GetFOV() )

    else

        local flashlight = ply.VManip_Flashlight
        if IsValid( flashlight ) then
            flashlight:Remove()
        end

    end
end

do

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