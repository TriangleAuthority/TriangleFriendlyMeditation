// Slice 1 (test only): FM-RT core with the hold hotkey. Channel 'FMTest'. The hotkey's events are called by script
// with a made-up key state (Ghost Mode's input simulation); a real key press is a separate check.
//   fmtest_hold_press()     presses HoldToMeditate: Geralt sits down through 5.x's Meditate()
//   fmtest_hold_seated()    ~3 s later: no clock, the fast-forward runs, saving locked, FM's input context kept
//   fmtest_hold_running()   a few seconds later: the HPM ramp, game time, effects in accelerated time, quest facts
//   fmtest_hold_release()   releases the hotkey (and 5.x's N release after it): Geralt stands up
//   fmtest_hold_after()     ~3 s later: back to normal, time speed restored, saving unlocked, no clock opened
//   fmtest_stop_a(), then a stop (MeditationForceAbort, a spawned enemy), then fmtest_stop_b(): the stop ends it

function FMTestHoldAction(pressed : bool) : SInputAction
{
	var action : SInputAction;

	action.aName = 'HoldToMeditate';
	if(pressed)
	{
		action.value = 1;
		action.lastFrameValue = 0;
	}
	else
	{
		action.value = 0;
		action.lastFrameValue = 1;
	}
	return action;
}

function FMTestLogState(label : string)
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	LogChannel('FMTest', "info " + label + ": state " + w.GetCurrentStateName() + ", hotkey mode " + w.fmHotkeyMode + ", fast-forward " + w.fmFastForward
		+ ", HPM " + theGame.GetHoursPerMinute() + ", context " + theInput.GetContext() + ", menu " + theGame.GetGuiManager().IsAnyMenu()
		+ ", saves locked " + theGame.AreSavesLocked() + ", action " + w.GetPlayerAction() + ", time " + GameTimeToString(theGame.GetGameTime()));
}

@addField(W3PlayerWitcher)
var fmTestGameSecs : float;

@addField(W3PlayerWitcher)
var fmTestEffectLeft : float;

@addField(W3PlayerWitcher)
var fmTestBaseHPM : float;

// A timed effect to watch (Swallow for 600 s).
function FMTestAddTimedEffect() : CBaseGameplayEffect
{
	var w : W3PlayerWitcher;
	var params : SCustomEffectParams;

	w = GetWitcherPlayer();
	w.RemoveAllBuffsOfType(EET_Swallow);
	params.effectType = EET_Swallow;
	params.creator = w;
	params.sourceName = "fmtest";
	params.duration = 600;
	w.AddEffectCustom(params);
	return w.GetBuff(EET_Swallow);
}

exec function fmtest_hold_press()
{
	var w : W3PlayerWitcher;
	var eff : CBaseGameplayEffect;

	w = GetWitcherPlayer();
	w.fmTestBaseHPM = theGame.GetHoursPerMinute();
	eff = FMTestAddTimedEffect();
	if(eff)
		LogChannel('FMTest', "info Swallow added, " + eff.GetTimeLeft() + " s left");
	else
		LogChannel('FMTest', "info Swallow did not attach");
	FMTestLogState("before");
	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(true));
	FMTestLogState("pressed");
}

exec function fmtest_hold_seated()
{
	var w : W3PlayerWitcher;
	var eff : CBaseGameplayEffect;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("seated");
	bad += FMTestCheck(w.FMIsMeditating() && w.fmHotkeyMode, "Geralt meditates in hotkey mode");
	bad += FMTestCheck(w.GetPlayerAction() == PEA_Meditation, "sitting (player action PEA_Meditation)");
	bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu(), "no clock menu");
	bad += FMTestCheck(w.fmFastForward, "the fast-forward runs (hold mode)");
	bad += FMTestCheck(theGame.AreSavesLocked(), "saving is locked");
	bad += FMTestCheck(theInput.GetContext() != 'Meditation', "the input context is not 5.x's 'Meditation' (" + theInput.GetContext() + ")");
	w.fmTestGameSecs = GameTimeToSeconds(theGame.GetGameTime());
	eff = w.GetBuff(EET_Swallow);
	if(eff)
		w.fmTestEffectLeft = eff.GetTimeLeft();
	FMTestResult("fmtest_hold_seated", bad);
}

exec function fmtest_hold_running()
{
	var w : W3PlayerWitcher;
	var eff : CBaseGameplayEffect;
	var gameSecs, effSecs : float;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("running");
	gameSecs = GameTimeToSeconds(theGame.GetGameTime()) - w.fmTestGameSecs;
	bad += FMTestCheck(theGame.GetHoursPerMinute() > w.fmTestBaseHPM && theGame.GetHoursPerMinute() <= w.fmMaxHPM,
		"HPM ramps up (" + w.fmTestBaseHPM + " -> " + theGame.GetHoursPerMinute() + ", max " + w.fmMaxHPM + ")");
	bad += FMTestCheck(gameSecs > 600, "game time runs fast: " + gameSecs + " game s since seated");
	eff = w.GetBuff(EET_Swallow);
	if(eff)
	{
		effSecs = w.fmTestEffectLeft - eff.GetTimeLeft();
		LogChannel('FMTest', "info Swallow: " + w.fmTestEffectLeft + " -> " + eff.GetTimeLeft() + " s left (" + effSecs + " s used)");
	}
	else
		LogChannel('FMTest', "info Swallow ran out (it had " + w.fmTestEffectLeft + " s)");
	LogChannel('FMTest', "info effect seconds applied by FM: " + w.fmEffectSecsApplied + "; game seconds / 15 (normal-time equivalent): " + (gameSecs / 15));
	bad += FMTestCheck(w.fmEffectSecsApplied > 30, "effects updated in accelerated time");
	bad += FMTestCheck(FactsQuerySum('MeditationStarted') == 1 && FactsQuerySum('MeditationWaitStartHour') >= 0, "quest facts set (start hour " + FactsQuerySum('MeditationWaitStartHour') + ")");
	FMTestResult("fmtest_hold_running", bad);
}

exec function fmtest_hold_release()
{
	var action : SInputAction;

	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(false));
	// 5.x's own meditation key is the same N: its release follows the hold
	action.aName = 'PanelMeditation';
	action.value = 0;
	action.lastFrameValue = 1;
	thePlayer.GetInputHandler().OnCommPanelMeditation(action);
	FMTestLogState("released");
}

exec function fmtest_hold_after()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("after");
	bad += FMTestCheck(!w.FMIsMeditating() && !w.fmFastForward && !w.fmHotkeyMode, "meditation ended");
	bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001, "time speed restored (" + theGame.GetHoursPerMinute() + ")");
	bad += FMTestCheck(!theGame.AreSavesLocked(), "saving unlocked");
	bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu(), "N's release opened no clock");
	bad += FMTestCheck(FactsQuerySum('MeditationStarted') == 0, "MeditationStarted cleared");
	w.RemoveAllBuffsOfType(EET_Swallow);
	FMTestResult("fmtest_hold_after", bad);
}

// Stops: fmtest_stop_a() presses the hotkey; once seated, stop it some way, then fmtest_stop_b().
exec function fmtest_stop_a()
{
	GetWitcherPlayer().fmTestBaseHPM = theGame.GetHoursPerMinute();
	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(true));
	FMTestLogState("pressed");
}

exec function fmtest_stop_force()
{
	FMTestLogState("before the stop");
	GetWitcherPlayer().MeditationForceAbort(true);
	FMTestLogState("stop requested");
}

exec function fmtest_stop_b()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	FMTestLogState("after the stop");
	FMTestResult("fmtest_stop_b", FMTestCheck(!w.FMIsMeditating() && !w.fmFastForward && AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001 && !theGame.AreSavesLocked(),
		"meditation ended, time speed and saving restored"));
}
