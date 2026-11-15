// Slice 6 (test only): FM-QUEN and FM-POP. Channel 'FMTest'.
//   autocast(ST_Quen) (modAutomation), then fmtest_s6_quen_a()   basic Quen's shield and buff are up
//   hold-mode meditation (fmtest_s2_press(), a few seconds), fmtest_s6_quen_b(), fmtest_s2_release()
//                                                            the buff ran out in accelerated time, the shield went too
//   fmtest_s6_pop()                                          after a campfire meditation: the meditation action started
//                                                            outside a meditation (what a place of power's channeling
//                                                            does) clears the campfire poses; the action is stopped again

exec function fmtest_s6_quen_a()
{
	var w : W3PlayerWitcher;
	var eff : CBaseGameplayEffect;
	var bad : int;

	w = GetWitcherPlayer();
	eff = w.GetBuff(EET_BasicQuen);
	LogChannel('FMTest', "info Quen active " + w.IsAnyQuenActive() + ", buff " + (bool)eff);
	if(eff)
		LogChannel('FMTest', "info Quen buff: " + eff.GetTimeLeft() + " s left of " + eff.GetInitialDuration());
	bad += FMTestCheck(w.IsAnyQuenActive() && eff, "basic Quen's shield and buff are up");
	FMTestResult("fmtest_s6_quen_a", bad);
}

exec function fmtest_s6_quen_b()
{
	var w : W3PlayerWitcher;
	var eff : CBaseGameplayEffect;
	var bad : int;

	w = GetWitcherPlayer();
	eff = w.GetBuff(EET_BasicQuen);
	LogChannel('FMTest', "info during the fast-forward: Quen active " + w.IsAnyQuenActive() + ", buff " + (bool)eff + ", fast-forward " + w.fmFastForward
		+ ", effect seconds " + w.fmEffectSecsApplied);
	bad += FMTestCheck(w.fmFastForward, "fast-forwarding");
	bad += FMTestCheck(!eff, "the Quen buff ran out in accelerated time");
	bad += FMTestCheck(!w.IsAnyQuenActive(), "the shield went with it");
	FMTestResult("fmtest_s6_quen_b", bad);
}

exec function fmtest_s6_pop()
{
	var w : W3PlayerWitcher;
	var ignite, campfire : float;
	var bad : int;

	w = GetWitcherPlayer();
	w.SetBehaviorVariable('MeditateWithIgnite', 1);
	w.SetBehaviorVariable('HasCampfire', 1);
	LogChannel('FMTest', "info before: MeditateWithIgnite " + w.GetBehaviorVariable('MeditateWithIgnite') + ", HasCampfire " + w.GetBehaviorVariable('HasCampfire')
		+ ", state " + w.GetCurrentStateName());
	w.PlayerStartAction(PEA_Meditation);
	ignite = w.GetBehaviorVariable('MeditateWithIgnite');
	campfire = w.GetBehaviorVariable('HasCampfire');
	w.PlayerStopAction(PEA_Meditation);
	LogChannel('FMTest', "info after the action's start: MeditateWithIgnite " + ignite + ", HasCampfire " + campfire);
	bad += FMTestCheck(!w.FMIsMeditating(), "outside a meditation");
	bad += FMTestCheck(ignite == 0 && campfire == 0, "no campfire poses for the action");
	FMTestResult("fmtest_s6_pop", bad);
}
