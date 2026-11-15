// Slice 5 (test only): FM-CLOCK. Channel 'FMTest'. 5.x's clock is opened through Meditate() (what N's tap and the
// radial menu call) and an hour chosen through its OnMeditate (what the clock's confirm calls).
//   fmtest_s5_open()               Meditate(): Geralt sits down, the clock opens once he is seated
//   fmtest_s5_clock(fire)          ~3-8 s later: seated with the clock open (in slow motion), FM's campfire if on
//   fmtest_s5_choose(hoursAhead)   chooses the hour that many hours ahead
//   fmtest_s5_running()            ~1 s later: FM's fast-forward from the clock, the slow motion lifted, clock open
//   fmtest_s5_after()              after the chosen hour: standing, the clock closed, the hour reached
//   fmtest_s5_close()              closes the clock (Escape) during the fast-forward

@addField(W3PlayerWitcher)
var fmTestTarget : int;

// Calling the clock's OnMeditate from a script (not from its confirm button) makes the clock's Flash call
// OnStopMeditate at once; 5.x's own wait gets the same stray stop (5.x aborted at 5:07 instead of 7:00, 2026-11-15).
// The test swallows that one call; a real choice on the clock is the owner's check.
@addField(W3PlayerWitcher)
var fmTestSwallowClockStop : bool;

@wrapMethod(CR4MeditationClockMenu)
function OnStopMeditate()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w.fmTestSwallowClockStop)
	{
		w.fmTestSwallowClockStop = false;
		LogChannel('FMTest', "info the clock's stray stop after a scripted choice swallowed");
		return true;
	}
	return wrappedMethod();
}

function FMTestClockMenu() : CR4MeditationClockMenu
{
	return GetWitcherPlayer().clockMenu;
}

exec function fmtest_s5_open()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.fmTestBaseHPM = theGame.GetHoursPerMinute();
	w.fmTestPressSecs = theGame.GetEngineTimeAsSeconds();
	LogChannel('FMTest', "info Meditate() returned " + w.Meditate() + "; ignite " + w.fmIgnite);
	FMTestLogState("opened");
}

exec function fmtest_s5_clock(fire : bool)
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("clock");
	LogChannel('FMTest', "info clock menu " + (bool)FMTestClockMenu() + ", time scale " + theGame.GetTimeScale() + ", campfire " + (bool)w.fmSpawnedCampFire);
	bad += FMTestCheck(w.FMIsMeditating() && w.GetPlayerAction() == PEA_Meditation && !w.fmHotkeyMode, "seated (not hotkey mode)");
	bad += FMTestCheck(FMTestClockMenu(), "the clock is open");
	bad += FMTestCheck(AbsF(theGame.GetTimeScale() - 0.1) < 0.01, "the clock's slow motion (" + theGame.GetTimeScale() + ")");
	bad += FMTestCheck(!w.fmFastForward, "no fast-forward yet");
	if(fire)
		bad += FMTestCheck(w.fmSpawnedCampFire && w.fmSpawnedCampFire.IsOnFire(), "FM's campfire burns");
	else
		bad += FMTestCheck(!w.fmSpawnedCampFire, "no campfire");
	FMTestResult("fmtest_s5_clock", bad);
}

exec function fmtest_s5_choose(hoursAhead : int)
{
	var w : W3PlayerWitcher;
	var clock : CR4MeditationClockMenu;

	w = GetWitcherPlayer();
	w.fmTestTarget = (GameTimeHours(theGame.GetGameTime()) + hoursAhead) % 24;
	clock = FMTestClockMenu();
	w.fmTestSwallowClockStop = true;
	if(clock)
		clock.OnMeditate(w.fmTestTarget);
	LogChannel('FMTest', "info chose " + w.fmTestTarget + ":00 on the clock (open " + (bool)clock + ")");
	FMTestLogState("chosen");
}

exec function fmtest_s5_running()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("running");
	LogChannel('FMTest', "info clock menu " + (bool)FMTestClockMenu() + ", time scale " + theGame.GetTimeScale() + ", target " + w.fmTargetHour);
	bad += FMTestCheck(w.FMIsMeditating() && w.fmClockMode && w.fmFastForward, "FM's fast-forward from the clock");
	bad += FMTestCheck(w.fmTargetHour == w.fmTestTarget, "target hour " + w.fmTargetHour);
	bad += FMTestCheck(w.GetCurrentStateName() == 'Meditation', "no 5.x MeditationWaiting");
	bad += FMTestCheck(AbsF(theGame.GetTimeScale() - 1) < 0.01, "the slow motion lifted (" + theGame.GetTimeScale() + ")");
	bad += FMTestCheck(theGame.GetHoursPerMinute() > w.fmTestBaseHPM, "hours per minute ramp up (" + theGame.GetHoursPerMinute() + ")");
	bad += FMTestCheck(FMTestClockMenu(), "the clock stays open");
	FMTestResult("fmtest_s5_running", bad);
}

exec function fmtest_s5_after()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("after");
	bad += FMTestCheck(!w.FMIsMeditating() && !w.fmFastForward && !w.fmClockMode, "standing, meditation ended");
	bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu() && !FMTestClockMenu(), "the clock closed");
	bad += FMTestCheck(GameTimeHours(theGame.GetGameTime()) == w.fmTestTarget, "the chosen hour " + w.fmTestTarget + " reached (" + GameTimeToString(theGame.GetGameTime()) + ")");
	bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001 && AbsF(theGame.GetTimeScale() - 1) < 0.01,
		"time speed and time scale normal (" + theGame.GetHoursPerMinute() + ", " + theGame.GetTimeScale() + ")");
	FMTestResult("fmtest_s5_after", bad);
}

exec function fmtest_s5_stopped()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("stopped");
	bad += FMTestCheck(!w.FMIsMeditating() && !w.fmFastForward && !w.fmClockMode, "standing, meditation ended");
	bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu() && !FMTestClockMenu(), "the clock closed");
	bad += FMTestCheck(GameTimeHours(theGame.GetGameTime()) != w.fmTestTarget, "stopped before the chosen hour");
	bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001 && AbsF(theGame.GetTimeScale() - 1) < 0.01,
		"time speed and time scale normal (" + theGame.GetHoursPerMinute() + ", " + theGame.GetTimeScale() + ")");
	FMTestResult("fmtest_s5_stopped", bad);
}

exec function fmtest_s5_close()
{
	var menu : CR4CommonMenu;

	menu = theGame.GetGuiManager().GetCommonMenu();
	if(menu)
		menu.CloseMenu();
	FMTestLogState("clock closed");
}
