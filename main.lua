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

Mod.PENNY_CHANCE = 10;

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
  if room.IsClear(room) then
    return
  end

  changeSpeedInRelationToPitch();

  if player:HasTrinket(TrinketType.TRINKET_TOSS_A_COIN) then
    local entityType = EntityType.ENTITY_BOMBDROP;
    local entityVariant = BombVariant.BOMB_NORMAL;
    local entitySubType = BombSubType.BOMB_SUPERTROLL;

    if willThrowLuckyPenny() then
      music:Pause();
      sound:Play(
        SoundEffect.SOUND_TOSS_A_COIN,
        Mod.SOUND_LEVEL,
        0,
        true,
        pitch / 100
      );

      entityType = EntityType.ENTITY_PICKUP;
      entityVariant = PickupVariant.PICKUP_COIN;
      entitySubType = CoinSubType.COIN_LUCKYPENNY;
    end

    toss(
      entityType, 
      entityVariant,
      entitySubType,
      getDirectionToThrowVector(
        math.random(Mod.TOSS_ANGLE_MIN, Mod.TOSS_ANGLE_MAX),
        player:GetHeadDirection()
      )
    );
  end
end

function getDirectionToThrowVector(tossAngle, headDirection)
    local directionToThrowVector = {
      [direction.LEFT] = Vector(-Mod.TOSS_POWER, tossAngle),
      [direction.RIGHT] = Vector(Mod.TOSS_POWER, tossAngle),
      [direction.TOP] = Vector(tossAngle, -Mod.TOSS_POWER),
      [direction.DOWN] = Vector(tossAngle, Mod.TOSS_POWER)
    }

    return directionToThrowVector[headDirection];
end

function Mod:adjustSoundOnEnemyKill()
  if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
    pitch = pitch - Mod.PITCH_STEP;

    if (pitch <= Mod.PITCH_FINAL) then
      stopSfxAndResumeMusic();
    else
      adjustPitch();
    end

    changeSpeedInRelationToPitch();
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
  if (pitch < Mod.PITCH_INITIAL) then
    room:SetBrokenWatchState(1) -- slow down
  elseif (pitch > Mod.PITCH_INITIAL) then
    room:SetBrokenWatchState(2) -- speed up
  else
    room:SetBrokenWatchState(0) -- normal speed
  end
end

function stopSfxAndResumeMusic()
  sound:Stop(SoundEffect.SOUND_TOSS_A_COIN);
  music:Resume();
  pitch = Mod.PITCH_INITIAL;
end

function adjustPitch()
  sound:AdjustPitch(
    SoundEffect.SOUND_TOSS_A_COIN,
    pitch / 100
  );
end

function willThrowLuckyPenny()
  local willThrow = false;

  if (math.random(0, 100) < Mod.PENNY_CHANCE) then
    willThrow = true;
  end

  return willThrow;
end

function toss(entityType, entityVariant, entitySubType, throwVector)
  Isaac.Spawn(
    entityType,
    entityVariant,
    entitySubType,
    player.Position,
    throwVector,
    player
  ); 
end

function Mod:debug()
  Isaac.RenderText(log, 250, 100, 255, 0, 0, 255)
end

Mod:AddCallback( ModCallbacks.MC_POST_NEW_ROOM, Mod.tossAConsumable);
Mod:AddCallback( ModCallbacks.MC_POST_NEW_LEVEL, Mod.initMod);
Mod:AddCallback( ModCallbacks.MC_POST_NPC_DEATH, Mod.adjustSoundOnEnemyKill);
Mod:AddCallback( ModCallbacks.MC_PRE_PICKUP_COLLISION, Mod.adjustSoundOnLuckyPennyPickup);
Mod:AddCallback( ModCallbacks.MC_POST_RENDER, Mod.debug); 
