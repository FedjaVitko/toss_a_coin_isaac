local Mod = RegisterMod("toss_a_coin", 1)
local game = Game();
local sound = SFXManager();
local music = MusicManager();
local player = Isaac.GetPlayer(0);
local room = game:GetRoom();

local direction = {
    LEFT = 0,
    TOP = 1,
    RIGHT = 2,
    DOWN = 3
}

TrinketType.TRINKET_TOSS_A_COIN = Isaac.GetTrinketIdByName("toss_a_coin");
SoundEffect.SOUND_TOSS_A_COIN = Isaac.GetSoundIdByName("toss_a_coin");

Mod.TOSS_POWER = 20;
Mod.TOSS_ANGLE_MIN = -70;
Mod.TOSS_ANGLE_MAX = 70;

Mod.PENNY_CHANCE = 20;

Mod.SOUND_LEVEL = 1;

Mod.PITCH_INITIAL = 100;
Mod.PITCH_FINAL = 70;
Mod.PITCH_STEP = 8;
Mod.PITCH_UP = 30;
Mod.PITCH_MAX = 170;

local pitch = Mod.PITCH_INITIAL;

local log = 'debug';

function Mod:initMod()
    game = Game();
    sound = SFXManager();
    music = MusicManager();
    player = Isaac.GetPlayer(0);
    room = game:GetRoom();
    stopSfxAndResumeMusic();
end

function Mod:tossAConsumable()
    debug='tossAConsumable'
    if room.IsClear(room) then
        return
    end

    changeSpeedInRelationToPitch();

    if player:HasTrinket(TrinketType.TRINKET_TOSS_A_COIN) then
        local headDirection = player:GetHeadDirection(player);
        local tossAngle = math.random(Mod.TOSS_ANGLE_MIN, Mod.TOSS_ANGLE_MAX); 
        local directionToThrowVector = {
            [direction.LEFT] = Vector(-Mod.TOSS_POWER, tossAngle),
            [direction.RIGHT] = Vector(Mod.TOSS_POWER, tossAngle),
            [direction.TOP] = Vector(tossAngle, -Mod.TOSS_POWER),
            [direction.DOWN] = Vector(tossAngle, Mod.TOSS_POWER)
        }

        local entityType = EntityType.ENTITY_BOMBDROP;
        local entityVariant = BombVariant.BOMB_NORMAL;
        local entitySubType = 0;
        local throwVector = directionToThrowVector[headDirection];

        if willThrowLuckyPenny() then
            music:Pause();
            sound:Play(SoundEffect.SOUND_TOSS_A_COIN, Mod.SOUND_LEVEL, 0, true, pitch / 100);

            entityType = EntityType.ENTITY_PICKUP;
            entityVariant = PickupVariant.PICKUP_COIN;
            entitySubType = CoinSubType.COIN_LUCKYPENNY;
            throwVector = directionToThrowVector[headDirection];
        end

        toss(entityType, entityVariant, entitySubType, throwVector);
    end
end

function Mod:adjustSoundOnEnemyKill()
    if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
        pitch = pitch - Mod.PITCH_STEP;

        if (pitch <= Mod.PITCH_FINAL) then
            stopSfxAndResumeMusic();
        else
            adjustPitch();
            changeSpeedInRelationToPitch();
        end
    end
end

function Mod:adjustSoundOnLuckyPennyPickup()
    if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
        -- TODO: only adjust pitch on lucky penny pickup
        pitch = math.min(pitch + Mod.PITCH_UP, Mod.PITCH_MAX);

        adjustPitch();
        changeSpeedInRelationToPitch();
    end
end

function changeSpeedInRelationToPitch()
    if (pitch <= Mod.PITCH_INITIAL) then
        room:SetBrokenWatchState(1) -- slow down
    else
        room:SetBrokenWatchState(2) -- speed up
    end
end

function stopSfxAndResumeMusic()
    sound:Stop(SoundEffect.SOUND_TOSS_A_COIN);
    music:Resume();
    pitch = Mod.PITCH_INITIAL;
end

function adjustPitch()
    sound:AdjustPitch(SoundEffect.SOUND_TOSS_A_COIN, pitch / 100);
end

function willThrowLuckyPenny()
    if (math.random(0, 100) > Mod.PENNY_CHANCE) then
        return true
    end
    return false
end

function toss(
    entityType,
    entityVariant,
    entitySubType,
    throwVector
)
    Isaac.Spawn(
        entityType,
        entityVariant,
        entitySubType,
        player.Position,
        throwVector,
        player
    ) 
end

function Mod:debug()
    local player = Isaac.GetPlayer(0)
    local headDirection = player.GetHeadDirection(player);
        local directionToThrowVector = {
            [direction.LEFT] = Vector(10, 15),
            [direction.TOP] = Vector(10, 15),
            [direction.RIGHT] = Vector(10, 15),
            [direction.DOWN] = Vector(10, 15)
        }

    Isaac.RenderText('headDirection:', 100, 50, 255, 0, 0, 255)
    Isaac.RenderText(headDirection, 150, 100, 255, 0, 0, 255)
    Isaac.RenderText(log, 250, 100, 255, 0, 0, 255)
end

Mod:AddCallback( ModCallbacks.MC_POST_NEW_ROOM, Mod.tossAConsumable);
Mod:AddCallback( ModCallbacks.MC_POST_GAME_STARTED, Mod.initMod);
Mod:AddCallback( ModCallbacks.MC_POST_NPC_DEATH, Mod.adjustSoundOnEnemyKill);
Mod:AddCallback( ModCallbacks.MC_PRE_PICKUP_COLLISION, Mod.adjustSoundOnLuckyPennyPickup);
Mod:AddCallback( ModCallbacks.MC_POST_RENDER, Mod.debug); 