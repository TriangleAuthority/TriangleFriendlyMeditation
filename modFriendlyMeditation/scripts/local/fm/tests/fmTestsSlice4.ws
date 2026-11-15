// Slice 4 (test only): FM-FIRE. Channel 'FMTest'. Use with slice 2's helpers in manual hotkey mode
// (fmtest_s2_opts(2, false, false), fmtest_s2_release()), so no time passes.
//   fmtest_s4_opts(spawn, keep)   "Spawn campfire" and "Do not remove campfire"
//   fmtest_s4_press()             the hotkey's press, with the time it was pressed
//   fmtest_s4_fire(expect)        ~7 s later: FM's campfire burns 0.8 m in front of Geralt (or there is none);
//                                 how long the sit-down took (the Igni pose is longer if 5.x's graph plays it)
//   fmtest_s4_gone(expectGone)    ~4 s after standing up: the campfire was removed (or kept)
//   fmtest_s4_cleanup()           removes a kept campfire

@addField(W3PlayerWitcher)
var fmTestPressSecs : float;

@addField(W3PlayerWitcher)
var fmTestFire : W3Campfire;

exec function fmtest_s4_opts(spawn : bool, keep : bool)
{
	theGame.GetInGameConfigWrapper().SetVarValue('modFriendlyMeditation', 'fmedSpawnCampfire', FMTestBoolString(spawn));
	theGame.GetInGameConfigWrapper().SetVarValue('modFriendlyMeditation', 'fmedDoNotDespawnCampfire', FMTestBoolString(keep));
	LogChannel('FMTest', "info campfire options: spawn " + GetFMeditationConfig().SpawnCampFire() + ", keep " + GetFMeditationConfig().DoNotDespawnCampFire());
}

exec function fmtest_s4_press()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.fmTestPressSecs = theGame.GetEngineTimeAsSeconds();
	w.fmTestFire = w.fmSpawnedCampFire;
	thePlayer.GetInputHandler().OnHoldToMeditate(FMTestHoldAction(true));
	LogChannel('FMTest', "info pressed: ignite " + w.fmIgnite + ", MeditateWithIgnite " + w.GetBehaviorVariable('MeditateWithIgnite')
		+ ", state " + w.GetCurrentStateName() + ", action " + w.GetPlayerAction());
}

exec function fmtest_s4_fire(expect : bool)
{
	var w : W3PlayerWitcher;
	var fire : W3Campfire;
	var fpos, pos, ahead : Vector;
	var bad : int;

	w = GetWitcherPlayer();
	fire = w.fmSpawnedCampFire;
	LogChannel('FMTest', "info sit-down took " + (w.fmSeatedSecs - w.fmTestPressSecs) + " s; MeditateWithIgnite " + w.GetBehaviorVariable('MeditateWithIgnite')
		+ ", action " + w.GetPlayerAction());
	bad += FMTestCheck(w.FMIsMeditating() && w.GetPlayerAction() == PEA_Meditation, "seated");
	if(expect)
	{
		bad += FMTestCheck(fire, "FM's campfire exists");
		if(fire)
		{
			fpos = fire.GetWorldPosition();
			pos = w.GetWorldPosition();
			ahead = pos + VecFromHeading(w.GetHeading()) * Vector(0.8, 0.8, 0);
			LogChannel('FMTest', "info campfire at " + VecToString(fpos) + ", Geralt at " + VecToString(pos) + ", on fire " + fire.IsOnFire()
				+ ", tagged " + fire.HasTag('fmed_campfire'));
			bad += FMTestCheck(fire.IsOnFire(), "it burns");
			bad += FMTestCheck(VecDistance2D(fpos, ahead) < 0.2, "0.8 m in front of Geralt (" + VecDistance2D(fpos, ahead) + " m off)");
			bad += FMTestCheck(AbsF(fpos.Z - pos.Z) < 0.5, "on the ground (" + (fpos.Z - pos.Z) + " m)");
			bad += FMTestCheck(theGame.GetEntityByTag('fmed_campfire') == fire, "found by its tag");
			if(w.fmTestFire)
				bad += FMTestCheck(fire == w.fmTestFire, "the same campfire as before (none lit within 3 m of it)");
		}
	}
	else
		bad += FMTestCheck(!fire || fire == w.fmTestFire, "no new campfire");
	FMTestResult("fmtest_s4_fire", bad);
}

exec function fmtest_s4_gone(expectGone : bool)
{
	var w : W3PlayerWitcher;
	var bad : int;

	w = GetWitcherPlayer();
	LogChannel('FMTest', "info after standing: campfire " + (bool)w.fmSpawnedCampFire + ", by tag " + (bool)theGame.GetEntityByTag('fmed_campfire')
		+ ", HasCampfire " + w.GetBehaviorVariable('HasCampfire') + ", state " + w.GetCurrentStateName());
	bad += FMTestCheck(!w.FMIsMeditating(), "standing");
	if(expectGone)
		bad += FMTestCheck(!w.fmSpawnedCampFire && !theGame.GetEntityByTag('fmed_campfire'), "the campfire was removed");
	else
		bad += FMTestCheck(w.fmSpawnedCampFire && w.fmSpawnedCampFire.IsOnFire(), "the campfire was kept and burns");
	FMTestResult("fmtest_s4_gone", bad);
}

exec function fmtest_s4_cleanup()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(w.fmSpawnedCampFire)
		w.fmSpawnedCampFire.Destroy();
	w.fmSpawnedCampFire = NULL;
	LogChannel('FMTest', "info campfire removed by the test");
}
