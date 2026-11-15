// Slice 0 (test only): FM-MENU, the campfire hotkey, and the blob probes. Channel 'FMTest'.
//   fmtest_menu()          the options menu's groups and every option's value or default
//   fmtest_keys()          ToggleSpawnCampFire: its keys (the input.settings line), its Key Bindings entry (the input.xml
//                          lines pasted), a scripted press flips the option
//   fmtest_state_a()       sits Geralt down (5.x's Meditate), then fmtest_state_b() a moment later:
//   fmtest_state_b()       a field added to a state class, and a timer declared in the state started with AddTimer
//   fmtest_state_c()       the timer's result, then stands Geralt up

function FMTestCheck(ok : bool, msg : string) : int
{
	if(ok)
	{
		LogChannel('FMTest', "  ok   " + msg);
		return 0;
	}
	LogChannel('FMTest', "  FAIL " + msg);
	return 1;
}

function FMTestResult(test : string, bad : int)
{
	if(bad == 0)
		LogChannel('FMTest', "PASS " + test);
	else
		LogChannel('FMTest', "FAIL " + test + ": " + bad + " failed");
}

exec function fmtest_menu()
{
	var wrapper : CInGameConfigWrapper;
	var groups, options : array<name>;
	var i, bad : int;
	var value : string;

	wrapper = theGame.GetInGameConfigWrapper();
	bad += FMTestCheck(GetFMeditationConfig() && true, "the config exists after the load");
	bad += FMTestCheck(wrapper.GetGroupDisplayName('modFriendlyMeditation') != "" && wrapper.GetGroupDisplayName('modFriendlyMeditationCamera') != "",
		"both groups are in the options: '" + wrapper.GetGroupDisplayName('modFriendlyMeditation') + "', '" + wrapper.GetGroupDisplayName('modFriendlyMeditationCamera') + "'");
	bad += FMTestCheck(wrapper.GetGroupPresetsNum('modFriendlyMeditation') == 4 && wrapper.GetGroupPresetsNum('modFriendlyMeditationCamera') == 4, "4 presets each");
	bad += FMTestCheck(GetLocStringByKeyExt("option_fmed_spawnCampfire") == "Spawn campfire", "strings load: '" + GetLocStringByKeyExt("option_fmed_spawnCampfire") + "'");
	FMOptionList(groups, options);
	bad += FMTestCheck(options.Size() == 14, "14 options");
	for(i = 0; i < options.Size(); i += 1)
	{
		value = wrapper.GetVarValue(groups[i], options[i]);
		bad += FMTestCheck(!FMOptionUnset(options[i], value), options[i] + " = '" + value + "' (default '" + FMOptionDefault(groups[i], options[i]) + "')");
	}
	bad += FMTestCheck(GetFMeditationConfig().MaxHPM() > 0 && GetFMeditationConfig().CamFOV() > 0, "reads: max HPM " + GetFMeditationConfig().MaxHPM() + ", FOV " + GetFMeditationConfig().CamFOV());
	FMTestResult("fmtest_menu", bad);
}

exec function fmtest_keys()
{
	var wrapper : CInGameConfigWrapper;
	var keys : array<EInputKey>;
	var action : SInputAction;
	var cfg : CModFMeditationConfig;
	var before : bool;
	var i, n, bad : int;
	var found : bool;
	var list : string;

	wrapper = theGame.GetInGameConfigWrapper();
	theInput.GetPCKeysForAction('ToggleSpawnCampFire', keys);
	for(i = 0; i < keys.Size(); i += 1)
		list += " " + keys[i];
	bad += FMTestCheck(keys.Contains(IK_End), "ToggleSpawnCampFire is bound to End (keys:" + list + ")");

	n = wrapper.GetVarsNumByGroupName('PCInput');
	for(i = 0; i < n; i += 1)
	{
		if(wrapper.GetVarNameByGroupName('PCInput', i) == 'ToggleSpawnCampFire')
			found = true;
	}
	bad += FMTestCheck(found, "Key Bindings (PCInput, " + n + " entries) lists ToggleSpawnCampFire");
	LogChannel('FMTest', "  info its display name: '" + wrapper.GetVarDisplayName('PCInput', 'ToggleSpawnCampFire') + "', text '" + GetLocStringByKeyExt("ToggleSpawnCampFire") + "'");

	cfg = GetFMeditationConfig();
	before = cfg.SpawnCampFire();
	action.aName = 'ToggleSpawnCampFire';
	action.value = 1;
	action.lastFrameValue = 0;
	thePlayer.GetInputHandler().OnToggleSpawnCampFire(action);
	bad += FMTestCheck(cfg.SpawnCampFire() != before, "a press flips 'Spawn campfire' (" + before + " -> " + cfg.SpawnCampFire() + ")");
	thePlayer.GetInputHandler().OnToggleSpawnCampFire(action);
	bad += FMTestCheck(cfg.SpawnCampFire() == before, "a second press flips it back");
	FMTestResult("fmtest_keys", bad);
}

// Logs the option's value: for a real key press (fmtest_campfire before and after pressing End).
exec function fmtest_campfire()
{
	LogChannel('FMTest', "info Spawn campfire = " + GetFMeditationConfig().SpawnCampFire());
}

// ---------------- probe: a field and a timer added to a state class ----------------

@addField(W3PlayerWitcherStateMeditation)
var fmProbeCount : int;

@addMethod(W3PlayerWitcherStateMeditation)
timer function FMProbeTimer(dt : float, id : int)
{
	fmProbeCount += 10;
	LogChannel('FMTest', "info the state's timer ran");
}

exec function fmtest_state_a()
{
	LogChannel('FMTest', "info Meditate() = " + GetWitcherPlayer().Meditate());
}

exec function fmtest_state_b()
{
	var st : W3PlayerWitcherStateMeditation;
	var bad : int;

	LogChannel('FMTest', "info state " + thePlayer.GetCurrentStateName());
	st = (W3PlayerWitcherStateMeditation)thePlayer.GetState('Meditation');
	bad += FMTestCheck(st && true, "the Meditation state object");
	if(st)
	{
		st.fmProbeCount = 1;
		bad += FMTestCheck(st.fmProbeCount == 1, "a field added to the state holds a value");
	}
	thePlayer.AddTimer('FMProbeTimer', 0.1, false);
	FMTestResult("fmtest_state_b", bad);
}

exec function fmtest_state_c()
{
	var st : W3PlayerWitcherStateMeditation;

	st = (W3PlayerWitcherStateMeditation)thePlayer.GetState('Meditation');
	FMTestResult("fmtest_state_c (the state's timer started with AddTimer ran)", FMTestCheck(st && st.fmProbeCount == 11, "count " + st.fmProbeCount));
	GetWitcherPlayer().MeditationForceAbort(true);
}
