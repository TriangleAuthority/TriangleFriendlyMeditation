// FM-RT core: Friendly Meditation's real-time meditation, built on 5.x's own Meditation state.
// - Holding the meditation hotkey (HoldToMeditate, legacy's hold-N) sits Geralt down through 5.x's Meditate(), so
//   its checks and Preparations' refusals apply, but without the clock: in hotkey mode the state's OpenUI (called
//   when Geralt is seated) is skipped and starts FM's fast-forward instead.
// - The fast-forward runs while Geralt stays in 5.x's Meditation state (it only idles) from a calling wrapper of
//   the state's OnPlayerTickTimer: hours per minute ramp up to "Max time acceleration", effects are updated in
//   accelerated time (legacy's UpdateEffectsAccelerated), the facts quests read are set as 5.x's wait sets them.
// - Every stop passes the state's StopRequested (the hotkey, a hit, combat, moving, jumping, a blocking scene, the
//   clock), which ends the fast-forward at once; Geralt then stands up through 5.x's code. No healing at the end
//   (legacy never called MeditationRestoring).
// - No saving while meditating (legacy's no-save lock).
// - Slice 2: alchemy refill after one game hour of fast-forward, the time-scale option ("Speed up animations"),
//   the "Waiting is started/stopped" notifications, the fast-forward key (MeditationFastForward) for the manual
//   hotkey mode.

@addField(W3PlayerWitcher)
var fmHotkeyMode : bool;	// this meditation was started by FM's hotkey (no clock)

@addField(W3PlayerWitcher)
var fmFastForward : bool;

@addField(W3PlayerWitcher)
var fmNoSaveLock : int;

@addField(W3PlayerWitcher)
var fmStoredHPM : float;

@addField(W3PlayerWitcher)
var fmHPM : float;

@addField(W3PlayerWitcher)
var fmMaxHPM : float;

@addField(W3PlayerWitcher)
var fmHPMPerSecond : float;

@addField(W3PlayerWitcher)
var fmFastForwardStartSecs : float;

@addField(W3PlayerWitcher)
var fmUpdatedGameTime : GameTime;

@addField(W3PlayerWitcher)
var fmStoredGameTime : GameTime;

@addField(W3PlayerWitcher)
var fmFullHealth : bool;

// Game seconds of fast-forward so far and effect seconds applied (for the tests).
@addField(W3PlayerWitcher)
var fmEffectSecsApplied : float;

@addField(W3PlayerWitcher)
var fmSeated : bool;	// seated in hotkey mode (the fast-forward key works from here on)

@addField(W3PlayerWitcher)
var fmSeatedSecs : float;	// engine time when Geralt was seated (for the tests)

@addField(W3PlayerWitcher)
var fmRefilled : bool;	// this fast-forward session refilled alchemy already

@addField(W3PlayerWitcher)
var fmTimescale : bool;	// the time-scale option took over from the hours-per-minute ramp

@addField(W3PlayerWitcher)
var fmInMeditationTick : bool;	// inside 5.x's meditation tick (to tell its jump stop apart)

// Legacy's fmedRefillIntervalSeconds: one game hour of fast-forward refills alchemy, once per session.
function FMRefillIntervalSecs() : float
{
	return 3600.0;
}

@addMethod(W3PlayerWitcher)
function FMIsMeditating() : bool
{
	return GetCurrentStateName() == 'Meditation';
}

@addMethod(W3PlayerWitcher)
function FMIsFastForwarding() : bool
{
	return fmFastForward;
}

// The hotkey's start: 5.x's sit-down without the clock. False if meditation is not allowed here (Meditate shows
// why, through Preparations if it is installed).
@addMethod(W3PlayerWitcher)
function FMStartHotkeyMeditation() : bool
{
	if(FMIsMeditating() || GetCurrentStateName() == 'MeditationWaiting')
		return false;
	fmHotkeyMode = true;
	if(!Meditate())
	{
		fmHotkeyMode = false;
		return false;
	}
	return true;
}

// Any stop: the state's own stop request (Geralt stands up).
@addMethod(W3PlayerWitcher)
function FMEndMeditation()
{
	var med : W3PlayerWitcherStateMeditation;

	if(FMIsMeditating())
	{
		med = (W3PlayerWitcherStateMeditation)GetState('Meditation');
		med.StopRequested(true);
	}
}

// Geralt is seated in hotkey mode (from the state's OpenUI): the fast-forward starts unless the hotkey is set to
// "Hold to enter meditation mode" (slice 2: then the fast-forward key starts it).
@addMethod(W3PlayerWitcher)
function FMSeated()
{
	fmSeated = true;
	fmSeatedSecs = theGame.GetEngineTimeAsSeconds();
	if(!fmConfig.HotkeyManualFastforward())
		FMStartFastForward();
}

@addMethod(W3PlayerWitcher)
function FMStartFastForward()
{
	if(fmFastForward || !FMIsMeditating() || !fmSeated)
		return;
	fmFastForward = true;
	fmRefilled = false;
	fmTimescale = false;
	fmMaxHPM = fmConfig.MaxHPM();
	fmHPMPerSecond = fmConfig.HPMPerSecond();
	fmStoredHPM = theGame.GetHoursPerMinute();
	fmHPM = fmStoredHPM;
	fmFastForwardStartSecs = theGame.GetEngineTimeAsSeconds();
	fmUpdatedGameTime = theGame.GetGameTime();
	fmStoredGameTime = theGame.GetGameTime();
	fmFullHealth = GetStat(BCS_Vitality) >= GetStatMax(BCS_Vitality);
	fmEffectSecsApplied = 0;
	theGame.GetFastForwardSystem().BeginFastForward();
	FactsSet('MeditationWaitStartDay', GameTimeDays(fmStoredGameTime));
	FactsSet('MeditationWaitStartHour', GameTimeHours(fmStoredGameTime));
	FactsSet('MeditationStarted', 1);
	if(!fmConfig.BeSilent())
		theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("message_fmed_started_fastforward"), , true);
}

@addMethod(W3PlayerWitcher)
function FMEndFastForward()
{
	if(!fmFastForward)
		return;
	fmFastForward = false;
	FMCheckWitcherHouseBuffs(GameTimeToSeconds(theGame.GetGameTime()) - GameTimeToSeconds(fmStoredGameTime));
	theGame.GetFastForwardSystem().AllowFastForwardSelfCompletion();
	theGame.SetHoursPerMinute(fmStoredHPM);
	if(fmTimescale)
	{
		theGame.RemoveTimeScale('FriendlyMeditation');
		fmTimescale = false;
	}
	FactsSet('MeditationStarted', 0);
	if(!fmConfig.BeSilent())
		theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("message_fmed_ended_fastforward"), , true);
}

// The fast-forward key (legacy's OnMeditationFastForward): a press while seated starts the fast-forward, a press
// or the release while fast-forwarding ends it, so in effect "hold to advance time".
@addMethod(W3PlayerWitcher)
function FMFastForwardKey(pressed : bool)
{
	if(fmFastForward)
		FMEndFastForward();
	else if(pressed)
		FMStartFastForward();
}

// Legacy's MeditationRefill: alchemy refilled once a session has run a game hour (through Ghost Mode's and
// Preparations' versions of SingletonItemsRefillAmmo when installed).
@addMethod(W3PlayerWitcher)
function FMCheckRefill()
{
	if(!fmRefilled && GameTimeToSeconds(theGame.GetGameTime()) - GameTimeToSeconds(fmStoredGameTime) >= FMRefillIntervalSecs())
	{
		inv.SingletonItemsRefillAmmo();
		fmRefilled = true;
	}
}

// Legacy's MeditationUpdate, once per player tick while fast-forwarding.
@addMethod(W3PlayerWitcher)
function FMMeditationUpdate()
{
	var realTimeSecs, gameTimeSecs : float;

	if(GetDayPart(theGame.GetGameTime()) != GetDayPart(fmUpdatedGameTime))
		theGame.VibrateControllerVeryLight();

	// the effects get the game time that passed since the last update, in accelerated time (legacy's formula);
	// under the time scale the engine's own tick runs them faster instead
	if(!fmTimescale)
	{
		gameTimeSecs = GameTimeToSeconds(theGame.GetGameTime() - fmUpdatedGameTime);
		realTimeSecs = ConvertGameSecondsToRealTimeSeconds(gameTimeSecs);
		effectManager.PerformUpdate(realTimeSecs * fmHPM / fmStoredHPM);
		fmEffectSecsApplied += realTimeSecs * fmHPM / fmStoredHPM;
	}

	if(!fmFullHealth && GetStat(BCS_Vitality) >= GetStatMax(BCS_Vitality))
	{
		theGame.VibrateControllerLight();
		fmFullHealth = true;
	}

	FMCheckRefill();

	if(!fmTimescale)
	{
		if(fmHPM < fmMaxHPM)
		{
			fmHPM = MinF(fmMaxHPM, fmStoredHPM + (theGame.GetEngineTimeAsSeconds() - fmFastForwardStartSecs) * fmHPMPerSecond);
			theGame.SetHoursPerMinute(fmHPM);
		}
		else if(fmConfig.UseTimescale())
		{
			// legacy's "Speed up animations": at the top speed, the whole game runs faster instead
			fmTimescale = true;
			theGame.GetFastForwardSystem().AllowFastForwardSelfCompletion();
			theGame.SetHoursPerMinute(fmStoredHPM);
			theGame.SetTimeScale(fmHPM / fmStoredHPM, 'FriendlyMeditation', 100);
		}
	}
	fmUpdatedGameTime = theGame.GetGameTime();

	// from the clock: up to the chosen hour (legacy's check)
	if(fmClockMode && GameTimeHours(theGame.GetGameTime()) == fmTargetHour)
		FMEndClockMeditation();
}

// ---------------- the Meditation state ----------------

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnEnterState(prevStateName : name)
{
	if(prevStateName != 'MeditationWaiting')
		theGame.CreateNoSaveLock("FriendlyMeditation", virtual_parent.fmNoSaveLock);
	virtual_parent.FMReadCameraOptions();
	return wrappedMethod(prevStateName);
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnLeaveState(nextStateName : name)
{
	virtual_parent.FMEndFastForward();
	if(nextStateName != 'MeditationWaiting')
	{
		theGame.ReleaseNoSaveLock(virtual_parent.fmNoSaveLock);
		virtual_parent.fmHotkeyMode = false;
		virtual_parent.fmSeated = false;
		virtual_parent.fmIgnite = false;
		virtual_parent.fmClockMode = false;
		virtual_parent.fmClockPending = false;
	}
	return wrappedMethod(nextStateName);
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnPlayerTickTimer(deltaTime : float)
{
	var ret : bool;

	virtual_parent.fmInMeditationTick = true;
	ret = wrappedMethod(deltaTime);
	virtual_parent.fmInMeditationTick = false;
	// 5.x switches to an input context of its own while Geralt sits without a menu; in hotkey mode FM's keys must
	// keep working, so it goes back to the previous context (5.x then has nothing to restore when he stands up)
	if(virtual_parent.fmHotkeyMode && changedContext && theInput.GetContext() == 'Meditation')
	{
		theInput.RestoreContext('Meditation', false);
		changedContext = false;
	}
	if(virtual_parent.fmClockPending && !isEntryFunctionLocked)
	{
		virtual_parent.fmClockPending = false;
		virtual_parent.FMStartClockFastForward();
	}
	if(virtual_parent.fmFastForward)
		virtual_parent.FMMeditationUpdate();
	return ret;
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function StopRequested(optional closeUI : bool)
{
	// 5.x's tick stands Geralt up on the stick or on Jump; Jump is Space, legacy's fast-forward key, and legacy
	// blocked jumping while meditating: in hotkey mode only the stick stops it from the tick
	if(virtual_parent.fmInMeditationTick && virtual_parent.fmHotkeyMode && virtual_parent.bLAxisReleased)
		return;
	virtual_parent.FMEndFastForward();
	wrappedMethod(closeUI);
}

// Seated: in hotkey mode no clock, FM's fast-forward instead (also when 5.x's Meditate() asks for the clock again
// while Geralt sits, e.g. the meditation key released after the hold).
@wrapMethod(W3PlayerWitcherStateMeditationBase)
function OpenUI(fadeInTime : float)
{
	if(virtual_parent.fmHotkeyMode)
	{
		// no clock: 5.x's camera (when FM's is off) need not make room for it
		menuNotYetOpen = false;
		virtual_parent.FMSeated();
		return;
	}
	wrappedMethod(fadeInTime);
}

// A blocking scene ends FM's meditation too (5.x stops only MeditationWaiting there; legacy stopped both).
@wrapMethod(W3PlayerWitcher)
function OnBlockingSceneStarted(scene : CStoryScene)
{
	FMEndMeditation();
	return wrappedMethod(scene);
}
