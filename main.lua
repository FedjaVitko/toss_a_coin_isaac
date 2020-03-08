local TossACoin = RegisterMod("toss_a_coin", 1)

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

TossACoin.TOSS_POWER = 20;
TossACoin.TOSS_ANGLE_MIN = -70;
TossACoin.TOSS_ANGLE_MAX = 70;

TossACoin.PENNY_CHANCE = 100;

TossACoin.SOUND_LEVEL = 1;

TossACoin.PITCH_INITIAL = 100;
TossACoin.PITCH_FINAL = 95;
TossACoin.PITCH_STEP = 1;
TossACoin.PITCH_UP = 10;
TossACoin.PITCH_MAX = 105;

local pitch = TossACoin.PITCH_INITIAL;

local log = 'debug';

function TossACoin:initMod()
  game = Game();
  sound = SFXManager();
  music = MusicManager();
  player = Isaac.GetPlayer(0);
  room = game:GetRoom();
  stopSfxAndResumeMusic();
end

function TossACoin:tossAConsumable()
  changeSpeedInRelationToPitch();

  if room.IsClear(room) then
    return
  end

  if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
    return
  end

  if player:HasTrinket(TrinketType.TRINKET_TOSS_A_COIN) then
    local entityType = EntityType.ENTITY_BOMBDROP;
    local entityVariant = BombVariant.BOMB_NORMAL;
    local entitySubType = BombSubType.BOMB_SUPERTROLL;

    if willThrowLuckyPenny() then
      music:Pause();
      sound:Play(
        SoundEffect.SOUND_TOSS_A_COIN,
        TossACoin.SOUND_LEVEL,
        0,
        true,
        pitch / 100
      );

      player:AnimateHappy();

      entityType = EntityType.ENTITY_PICKUP;
      entityVariant = PickupVariant.PICKUP_COIN;
      entitySubType = CoinSubType.COIN_LUCKYPENNY;
    end

    toss(
      entityType, 
      entityVariant,
      entitySubType,
      getDirectionToThrowVector(
        math.random(TossACoin.TOSS_ANGLE_MIN, TossACoin.TOSS_ANGLE_MAX),
        player:GetHeadDirection()
      )
    );
  end
end

function getDirectionToThrowVector(tossAngle, headDirection)
    local directionToThrowVector = {
      [direction.LEFT] = Vector(-TossACoin.TOSS_POWER, tossAngle),
      [direction.RIGHT] = Vector(TossACoin.TOSS_POWER, tossAngle),
      [direction.TOP] = Vector(tossAngle, -TossACoin.TOSS_POWER),
      [direction.DOWN] = Vector(tossAngle, TossACoin.TOSS_POWER)
    }

    return directionToThrowVector[headDirection];
end

function TossACoin:adjustSoundOnEnemyKill()
  if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
    pitch = pitch - TossACoin.PITCH_STEP;

    if (pitch <= TossACoin.PITCH_FINAL) then
      stopSfxAndResumeMusic();
    else
      adjustPitch();
    end

    changeSpeedInRelationToPitch();
  end
end

function TossACoin:adjustSoundOnLuckyPennyPickup(pickUp)
  if (pickUp:GetCoinValue() == 0) then -- if not a coin return
    return
  end

  if (sound:IsPlaying(SoundEffect.SOUND_TOSS_A_COIN)) then
    pitch = math.min(pitch + TossACoin.PITCH_UP, TossACoin.PITCH_MAX);
    adjustPitch();
    changeSpeedInRelationToPitch();

    game:SpawnParticles(
      pickUp.Position, -- position
      EffectVariant.CRACK_THE_SKY,
      1, -- number of particles
      0.9, -- speed
      Color(0.7, 0, 0, 0.5, 5, 5, 5), -- color
      1 -- height
    );
  end
end

function changeSpeedInRelationToPitch()
  if (pitch < TossACoin.PITCH_INITIAL) then
    room:SetBrokenWatchState(1) -- slow down
  elseif (pitch > TossACoin.PITCH_INITIAL) then
    room:SetBrokenWatchState(2) -- speed up
  else
    room:SetBrokenWatchState(0) -- normal speed
  end
end

function stopSfxAndResumeMusic()
  sound:Stop(SoundEffect.SOUND_TOSS_A_COIN);
  music:Resume();
  pitch = TossACoin.PITCH_INITIAL;
  changeSpeedInRelationToPitch();
end

function adjustPitch()
  sound:AdjustPitch(
    SoundEffect.SOUND_TOSS_A_COIN,
    pitch / 100
  );
end

function willThrowLuckyPenny()
  local willThrow = false;

  if (math.random(0, 100) < TossACoin.PENNY_CHANCE) then
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

function TossACoin:debug()
  Isaac.RenderText(log, 250, 100, 255, 0, 0, 255)
end

-- register callbacks

TossACoin:AddCallback(
  ModCallbacks.MC_POST_NEW_ROOM,
  TossACoin.tossAConsumable
);
TossACoin:AddCallback(
  ModCallbacks.MC_POST_NEW_LEVEL,
  TossACoin.initMod
);
TossACoin:AddCallback(
  ModCallbacks.MC_POST_NPC_DEATH,
  TossACoin.adjustSoundOnEnemyKill
);
TossACoin:AddCallback(
  ModCallbacks.MC_PRE_PICKUP_COLLISION,
  TossACoin.adjustSoundOnLuckyPennyPickup
);
TossACoin:AddCallback(
  ModCallbacks.MC_POST_RENDER,
  TossACoin.debug
); 
