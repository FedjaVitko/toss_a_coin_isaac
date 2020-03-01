local Mod = RegisterMod("toss_a_coin", 1)
local game = Game()
local sound = SFXManager()
local music = MusicManager()

TrinketType.TRINKET_TOSS_A_COIN = Isaac.GetTrinketIdByName("toss_a_coin");
SoundEffect.SOUND_TOSS_A_COIN = Isaac.GetSoundIdByName("toss_a_coin");

Mod.TOSS_POWER = 20;
Mod.TOSS_ANGLE_MIN = -70;
Mod.TOSS_ANGLE_MAX = 70;

Mod.PENNY_CHANCE = 20;

-- comparing floats is not easy, that's why I chose to go with int
Mod.PITCH_INITIAL = 100;
Mod.PITCH_FINAL = 70;
Mod.PITCH_STEP = 10;

local direction = {
    LEFT = 0,
    TOP = 1,
    RIGHT = 2,
    DOWN = 3
}
local player = Isaac.GetPlayer(0)

local pitch = Mod.PITCH_INITIAL;

local debug = 'debug';

function Mod:tossAConsumable()
    local player = Isaac.GetPlayer(0)
    local room = game:GetRoom();
    if room.IsClear(room) then
        return
    end

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
            sound:Play(SoundEffect.SOUND_TOSS_A_COIN, 4, 0, true, pitch / 100);
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

        if (pitch == Mod.PITCH_FINAL) then
            debug = 'went into the if statement';
            sound:Stop(SoundEffect.SOUND_TOSS_A_COIN);
            music:Resume();
            pitch = Mod.PITCH_INITIAL;
        else
            sound:AdjustPitch(SoundEffect.SOUND_TOSS_A_COIN, pitch / 100);
        end
    end
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
    Isaac.RenderText(debug, 250, 100, 255, 0, 0, 255)
end

Mod:AddCallback( ModCallbacks.MC_POST_NEW_ROOM, Mod.tossAConsumable);
Mod:AddCallback( ModCallbacks.MC_POST_NPC_DEATH, Mod.adjustSoundOnEnemyKill);
Mod:AddCallback( ModCallbacks.MC_POST_RENDER, Mod.debug); 