module( "better_flashlight", package.seeall )
util.AddNetworkString( "Better Flashlight" )

-- Sounds
Sounds = {
    Sound( "better_flashlight/deploy.ogg" ),
    Sound( "better_flashlight/holster.ogg" ),
    Sound( "better_flashlight/toggle.ogg" )
}

local flashlight_power = CreateConVar( "flashlight_power", 1, FCVAR_ARCHIVE, " - flashlight charge loss", 0, 1 ):GetBool()
cvars.AddChangeCallback("flashlight_power", function( name, old, new )
    flashlight_power = new == "1"
end, "Better Flashlight")

-- Blocking Source Engine flashlight
hook.Add("PlayerSwitchFlashlight", "Better Flashlight", function( ply, bool )
    if not bool then
        return
    end

    return false
end)

function Enable( ply )
    ply:SetNWBool( "Better Flashlight", true )
end

function Disable( ply, send )
    ply:SetNWBool( "Better Flashlight", false )
    if (send == nil) then return end
    net.Start("Better Flashlight")
    net.Send( ply )
end

function Toggle( ply )
    if ply:FlashlightIsOn() then
        Disable( ply )
    else
        Enable( ply )
    end
end

-- Disable Flashlight after player death
hook.Add( "DoPlayerDeath", "Better Flashlight", Disable )

-- Disable Flashlight when entering vehicle
hook.Add( "PlayerEnteredVehicle", "Better Flashlight", Disable )

-- HEV Suit
local gmod_suit = cvars.Bool( "gmod_suit", false )
cvars.AddChangeCallback("gmod_suit", function( name, old, new )
    gmod_suit = new == "1"
end, "Better Flashlight")

-- Player Functions
do

    local PLAYER = FindMetaTable( "Player" )

    -- IsOn
    function PLAYER:FlashlightIsOn()
        return self:GetNWBool( "Better Flashlight", false )
    end

    -- Flashlight Allow
    function PLAYER:AllowFlashlight( bool )
        self:SetNWBool( "Better Flashlight Allowed", bool == true )
    end

    function PLAYER:IsSuitNoPower()
        return (gmod_suit) and self:IsSuitEquipped() and (self:GetSuitPower() < 5)
    end

    function PLAYER:TakeSuitPower( amount )
        self:SetSuitPower( math.min( 0, self:GetSuitPower() - amount ) )
    end

    function PLAYER:AddSuitPower( amount )
        self:SetSuitPower( math.min( 0, self:GetSuitPower() + amount ) )
    end

    local mp_flashlight = cvars.Bool( "mp_flashlight", false )
    cvars.AddChangeCallback("mp_flashlight", function( name, old, new )
        mp_flashlight = new == "1"

        game.GetWorld():SetNWBool( "mp_flashlight", mp_flashlight )
    end, "Better Flashlight")

    hook.Add("InitPostEntity", "Better Flashlight", function()
        game.GetWorld():SetNWBool( "mp_flashlight", mp_flashlight )
    end)

    -- Allow Flashlight
    function PLAYER:IsFlashlightAllowed()
        return self:GetNWBool( "Better Flashlight Allowed", true ) and mp_flashlight
    end

    -- Flashlight Texture
    function PLAYER:SetFlashlightTexture( path )
        self:SetNWString( "Better Flashlight Texture", path or "effects/flashlight001" )
    end

    -- Can Use
    function PLAYER:CanUseFlashlight()
        if self:GetNWBool( "Better Flashlight No Power", false ) or self:InVehicle() then
            return false
        end

        if self:Alive() then
            if self:FlashlightIsOn() then
                return true
            end

            if (mp_flashlight) and self:IsFlashlightAllowed() then
                if (flashlight_power) and self:IsSuitNoPower() then
                    return false
                end

                return true
            end
        end

        return false
    end

end

-- Net Controls
do

    local IsValid = IsValid
    local CurTime = CurTime

    local switch = {
        [0] = Enable,
        [1] = Disable,
        [2] = Toggle
    }

    local delayList = {}
    net.Receive("Better Flashlight", function( len, ply )
        if IsValid( ply ) and ply:Alive() then
            if (delayList[ ply:EntIndex() ] or 0) > CurTime() then
                ply:Kick( "Please don't spam with a flashlight!" )
                return
            end

            delayList[ ply:EntIndex() ] = CurTime() + 0.5

            local func = switch[ net.ReadUInt( 2 ) ]
            if (func == nil) then
                ply:Kick( "Please don't try hack flashlight!" )
            else
                func( ply )
                ply:EmitSound( Sounds[3] )
            end
        end
    end)

end

local function UpdateNWBool( ply, name, bool )
    if (ply:GetNWBool( name, false ) == bool) then
        return
    end

    ply:SetNWBool( name, bool )
end

local flashlight_power_less_speed = CreateConVar( "flashlight_power_less_speed", 10, FCVAR_ARCHIVE, " - flashlight charge loss rate", 0, 100 ):GetInt() / 100 * 0.5 + 0.2
cvars.AddChangeCallback("flashlight_power_less_speed", function( name, old, new )
    flashlight_power_less_speed = tonumber( new ) / 100 * 0.5 + 0.2
end, "Better Flashlight")

-- Blocking Props Pickup
-- hook.Add("AllowPlayerPickup", "Better Flashlight", function( ply, ent )
--     if ply:FlashlightIsOn() then
--         Disable( ply, true )
--         return false
--     end
-- end)

-- GLobal Think
hook.Add("PlayerPostThink", "Better Flashlight", function( ply )
    if (flashlight_power) then
        UpdateNWBool( ply, "Better Flashlight No Power", ply:IsSuitNoPower() )
    end

    if ply:FlashlightIsOn() then
        if (flashlight_power) and (gmod_suit) and ply:IsSuitEquipped() then
            if (ply:GetSuitPower() > 5) then
                ply:SetSuitPower( ply:GetSuitPower() - flashlight_power_less_speed )
            end
        end

        if ply:IsFlashlightAllowed() then
            return
        end

        Disable( ply )
    end
end)
