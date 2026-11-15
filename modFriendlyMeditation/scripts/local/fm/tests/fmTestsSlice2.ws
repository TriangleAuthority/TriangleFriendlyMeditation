// Slice 2 (test only): the rest of FM-RT. Channel 'FMTest'. Events are called by script (made-up key states), as in
// slice 1; real keys are the owner's check at the end of the port.
//   fmtest_s2_opts(mode, timescale, silent)  sets the hotkey mode (0 hold, 1 toggle, 2 manual), "Speed up
//                                            animations" and "Be silent"
//   fmtest_s2_press(), fmtest_s2_release()   the meditation hotkey's press and release (release: N's after it)
//   fmtest_s2_ff(pressed)                    the fast-forward key's press or release
//   fmtest_s2_expect(meditating, ff, label)  checks Geralt's meditation and the fast-forward
//   fmtest_s2_jumpstop()                     a stop request from inside 5.x's tick with the stick at rest (= Jump)
//   fmtest_s2_refill_prep(), fmtest_s2_refill_check()   an emptied potion and alcohol; refilled after a game hour
//   fmtest_s2_timescale()                    while fast-forwarding with the time-scale option: it took over
//   fmtest_s2_after()                        after the stop: time speed, time scale, saving restored
//   fmtest_s2_strings()                      the notification strings resolve

function FMTestSetOption(option : name, value : string)
{
	theGame.GetInGameConfigWrapper().SetVarValue('modFriendlyMeditation', option, value);
}

function FMTestBoolString(b : bool) : string
{
	if(b)
		return "true";
	return "false";
}

exec function fmtest_s2_opts(mode : int, timescale : bool, silent : bool)
{
	var cfg : CModFMeditationConfig;

	FMTestSetOption('Virtual_fmedHotkeyBehavior', IntToString(mode));
	FMTestSetOption('fmedUseTimescale', FMTestBoolString(timescale));
	FMTestSetOption('fmedBeSilent', FMTestBoolString(silent));
	cfg = GetFMeditationConfig();
	LogChannel('FMTest', "info options: toggle " + cfg.HotkeyAsToggle() + ", manual " + cfg.HotkeyManualFastforward()
		+ ", timescale " + cfg.UseTimescale() + ", silent " + cfg.BeSilent() + ", max HPM " + cfg.MaxHPM() + ", HPM/s " + cfg.HPMPerSecond());
}

exec function fmtest_s2_press()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w.FMIsMeditating())
		w.fmTestBaseHPM = theGame.GetHoursPerMinute();
	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(true));
	FMTestLogState("pressed");
}

exec function fmtest_s2_release()
{
	var action : SInputAction;

	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(false));
	action.aName = 'PanelMeditation';
	action.value = 0;
	action.lastFrameValue = 1;
	thePlayer.GetInputHandler().OnCommPanelMeditation(action);
	FMTestLogState("released");
}

exec function fmtest_s2_ff(pressed : bool)
{
	var action : SInputAction;

	action.aName = 'MeditationFastForward';
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
	thePlayer.GetInputHandler().OnMeditationFastForward(action);
	FMTestLogState("fast-forward key " + pressed);
}

exec function fmtest_s2_expect(meditating : bool, ff : bool, label : string)
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState(label);
	bad += FMTestCheck(w.FMIsMeditating() == meditating, "meditating " + meditating);
	bad += FMTestCheck(w.fmFastForward == ff, "fast-forward " + ff);
	if(meditating)
	{
		bad += FMTestCheck(w.GetPlayerAction() == PEA_Meditation, "seated (PEA_Meditation)");
		bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu(), "no clock menu");
	}
	else
	{
		bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001, "time speed normal (" + theGame.GetHoursPerMinute() + ")");
		bad += FMTestCheck(!theGame.GetGuiManager().IsAnyMenu(), "no menu opened");
	}
	if(!ff)
		bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001 && AbsF(theGame.GetTimeScale() - 1) < 0.001,
			"time speed and time scale normal (" + theGame.GetHoursPerMinute() + ", " + theGame.GetTimeScale() + ")");
	FMTestResult("fmtest_s2_expect " + label, bad);
}

// A stop request from inside 5.x's meditation tick with the stick at rest: what Jump (Space) causes.
exec function fmtest_s2_jumpstop()
{
	var w : W3PlayerWitcher;
	var med : W3PlayerWitcherStateMeditation;

	w = GetWitcherPlayer();
	med = (W3PlayerWitcherStateMeditation)w.GetState('Meditation');
	LogChannel('FMTest', "info stick released " + w.bLAxisReleased);
	w.fmInMeditationTick = true;
	med.StopRequested(true);
	w.fmInMeditationTick = false;
	FMTestLogState("jump stop requested");
}

@addField(W3PlayerWitcher)
var fmTestPotion : SItemUniqueId;

exec function fmtest_s2_refill_prep()
{
	var w : W3PlayerWitcher;
	var ids : array<SItemUniqueId>;

	w = GetWitcherPlayer();
	ids = w.inv.AddAnItem('Swallow 1', 1);
	w.fmTestPotion = ids[0];
	w.inv.AddAnItem('Dwarven spirit', 3);
	w.inv.SingletonItemRemoveAmmo(w.fmTestPotion, w.inv.SingletonItemGetAmmo(w.fmTestPotion));
	LogChannel('FMTest', "info Swallow ammo " + w.inv.SingletonItemGetAmmo(w.fmTestPotion) + " of " + w.inv.SingletonItemGetMaxAmmo(w.fmTestPotion)
		+ ", Dwarven spirit " + w.inv.GetItemQuantityByName('Dwarven spirit'));
}

exec function fmtest_s2_refill_check()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	LogChannel('FMTest', "info Swallow ammo " + w.inv.SingletonItemGetAmmo(w.fmTestPotion) + " of " + w.inv.SingletonItemGetMaxAmmo(w.fmTestPotion)
		+ ", Dwarven spirit " + w.inv.GetItemQuantityByName('Dwarven spirit') + ", refilled flag " + w.fmRefilled);
	bad += FMTestCheck(w.fmRefilled, "FM refilled after a game hour");
	bad += FMTestCheck(w.inv.SingletonItemGetAmmo(w.fmTestPotion) == w.inv.SingletonItemGetMaxAmmo(w.fmTestPotion), "Swallow refilled");
	FMTestResult("fmtest_s2_refill_check", bad);
}

exec function fmtest_s2_timescale()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("timescale");
	LogChannel('FMTest', "info time scale " + theGame.GetTimeScale() + ", FM HPM " + w.fmHPM + ", stored " + w.fmStoredHPM);
	bad += FMTestCheck(w.fmFastForward && w.fmTimescale, "the time scale took over");
	bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmStoredHPM) < 0.001, "hours per minute back to normal (" + theGame.GetHoursPerMinute() + ")");
	bad += FMTestCheck(AbsF(theGame.GetTimeScale() - w.fmHPM / w.fmStoredHPM) < 0.5, "time scale " + theGame.GetTimeScale() + " = max HPM / normal HPM");
	FMTestResult("fmtest_s2_timescale", bad);
}

exec function fmtest_s2_after()
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	FMTestLogState("after");
	bad += FMTestCheck(!w.FMIsMeditating() && !w.fmFastForward && !w.fmTimescale && !w.fmSeated, "meditation ended");
	bad += FMTestCheck(AbsF(theGame.GetHoursPerMinute() - w.fmTestBaseHPM) < 0.001, "time speed restored (" + theGame.GetHoursPerMinute() + ")");
	bad += FMTestCheck(AbsF(theGame.GetTimeScale() - 1) < 0.001, "time scale restored (" + theGame.GetTimeScale() + ")");
	FMTestResult("fmtest_s2_after", bad);
}

exec function fmtest_s2_strings()
{
	var a, b : string;
	var bad : int;

	a = GetLocStringByKeyExt("message_fmed_started_fastforward");
	b = GetLocStringByKeyExt("message_fmed_ended_fastforward");
	LogChannel('FMTest', "info notifications: '" + a + "', '" + b + "'");
	bad += FMTestCheck(a == "Waiting is started" && b == "Waiting is stopped", "notification strings resolve");
	FMTestResult("fmtest_s2_strings", bad);
}
