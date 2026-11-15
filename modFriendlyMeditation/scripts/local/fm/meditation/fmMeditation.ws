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
	if(!fmConfig.HotkeyManualFastforward())
		FMStartFastForward();
}

@addMethod(W3PlayerWitcher)
function FMStartFastForward()
{
	if(fmFastForward || !FMIsMeditating())
		return;
	fmFastForward = true;
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
}

@addMethod(W3PlayerWitcher)
function FMEndFastForward()
{
	if(!fmFastForward)
		return;
	fmFastForward = false;
	theGame.GetFastForwardSystem().AllowFastForwardSelfCompletion();
	theGame.SetHoursPerMinute(fmStoredHPM);
	FactsSet('MeditationStarted', 0);
}

// Legacy's MeditationUpdate, once per player tick while fast-forwarding.
@addMethod(W3PlayerWitcher)
function FMMeditationUpdate()
{
	var realTimeSecs, gameTimeSecs : float;

	if(GetDayPart(theGame.GetGameTime()) != GetDayPart(fmUpdatedGameTime))
		theGame.VibrateControllerVeryLight();

	// the effects get the game time that passed since the last update, in accelerated time (legacy's formula)
	gameTimeSecs = GameTimeToSeconds(theGame.GetGameTime() - fmUpdatedGameTime);
	realTimeSecs = ConvertGameSecondsToRealTimeSeconds(gameTimeSecs);
	effectManager.PerformUpdate(realTimeSecs * fmHPM / fmStoredHPM);
	fmEffectSecsApplied += realTimeSecs * fmHPM / fmStoredHPM;

	if(!fmFullHealth && GetStat(BCS_Vitality) >= GetStatMax(BCS_Vitality))
	{
		theGame.VibrateControllerLight();
		fmFullHealth = true;
	}

	if(fmHPM < fmMaxHPM)
	{
		fmHPM = MinF(fmMaxHPM, fmStoredHPM + (theGame.GetEngineTimeAsSeconds() - fmFastForwardStartSecs) * fmHPMPerSecond);
		theGame.SetHoursPerMinute(fmHPM);
	}
	fmUpdatedGameTime = theGame.GetGameTime();
}

// ---------------- the Meditation state ----------------

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnEnterState(prevStateName : name)
{
	if(prevStateName != 'MeditationWaiting')
		theGame.CreateNoSaveLock("FriendlyMeditation", virtual_parent.fmNoSaveLock);
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
	}
	return wrappedMethod(nextStateName);
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnPlayerTickTimer(deltaTime : float)
{
	var ret : bool;

	ret = wrappedMethod(deltaTime);
	// 5.x switches to an input context of its own while Geralt sits without a menu; in hotkey mode FM's keys must
	// keep working, so it goes back to the previous context (5.x then has nothing to restore when he stands up)
	if(virtual_parent.fmHotkeyMode && changedContext && theInput.GetContext() == 'Meditation')
	{
		theInput.RestoreContext('Meditation', false);
		changedContext = false;
	}
	if(virtual_parent.fmFastForward)
		virtual_parent.FMMeditationUpdate();
	return ret;
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function StopRequested(optional closeUI : bool)
{
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
