// FM-KEYS: Friendly Meditation's hotkeys. Bindings: the player adds the input.settings lines by hand, as in legacy
// (owner, 2026-11-14), and pastes the Key Bindings entries into the game's input.xml (release/*.part.txt): the
// game reads Key Bindings only from input.xml's PCInput group; a second file's PCInput group is ignored.
// Ported so far: ToggleSpawnCampFire (legacy's End key: flips "Spawn campfire" and says so), HoldToMeditate
// (legacy's hold-N, input.settings: IK_N=(Action=HoldToMeditate,State=Duration,IdleTime=0.4)) in its three modes,
// and MeditationFastForward (Space). MeditationStop (the clock's stop key) comes with the clock (slice 5).

@wrapMethod(CPlayerInput)
function Initialize(isFromLoad : bool, optional previousInput : CPlayerInput)
{
	wrappedMethod(isFromLoad, previousInput);
	theInput.RegisterListener(this, 'OnToggleSpawnCampFire', 'ToggleSpawnCampFire');
	theInput.RegisterListener(this, 'OnHoldToMeditate', 'HoldToMeditate');
	theInput.RegisterListener(this, 'OnMeditationFastForward', 'MeditationFastForward');
}

// Legacy's fast-forward key (Space): while seated, press starts the fast-forward, release or a second press ends it.
@addMethod(CPlayerInput)
event OnMeditationFastForward(action : SInputAction)
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if(thePlayer.IsCiri() || !witcher || !witcher.FMIsMeditating())
		return false;
	if(IsPressed(action))
		witcher.FMFastForwardKey(true);
	else if(IsReleased(action))
		witcher.FMFastForwardKey(false);
}

// Set by the hotkey's press, cleared by the next press of 5.x's meditation key: the release of N after a hold
// does not also open 5.x's meditation (legacy's inFriendlyMeditation).
@addField(CPlayerInput)
var fmInFriendlyMeditation : bool;

// Legacy's OnHoldToMeditate: a press starts meditation, or ends it if Geralt meditates; the release ends it, unless
// the hotkey is set to toggle or to "Hold to enter meditation mode".
@addMethod(CPlayerInput)
event OnHoldToMeditate(action : SInputAction)
{
	var witcher : W3PlayerWitcher;
	var cfg : CModFMeditationConfig;
	var asToggle : bool;

	witcher = GetWitcherPlayer();
	cfg = GetFMeditationConfig();
	if(!witcher || !cfg)
		return false;
	asToggle = cfg.HotkeyAsToggle() || cfg.HotkeyManualFastforward();
	if(IsPressed(action))
	{
		fmInFriendlyMeditation = true;
		if(witcher.FMIsMeditating())
			witcher.FMEndMeditation();
		else
			witcher.FMStartHotkeyMeditation();
	}
	if(IsReleased(action) && !asToggle)
		witcher.FMEndMeditation();
}

@wrapMethod(CPlayerInput)
function OnCommPanelMeditation(action : SInputAction)
{
	if(IsPressed(action))
		fmInFriendlyMeditation = false;
	if(fmInFriendlyMeditation && IsReleased(action))
		return false;
	return wrappedMethod(action);
}

@addMethod(CPlayerInput)
event OnToggleSpawnCampFire(action : SInputAction)
{
	var cfg : CModFMeditationConfig;

	cfg = GetFMeditationConfig();
	if(IsPressed(action) && cfg)
	{
		cfg.SetSpawnCampFire(!cfg.SpawnCampFire());
		if(!cfg.BeSilent())
		{
			if(cfg.SpawnCampFire())
				theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("fmedSpawnCampFireOn"));
			else
				theGame.GetGuiManager().ShowNotification(GetLocStringByKeyExt("fmedSpawnCampFireOff"));
		}
	}
}
