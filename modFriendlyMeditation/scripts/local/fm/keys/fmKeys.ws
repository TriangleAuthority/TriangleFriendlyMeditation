// FM-KEYS: Friendly Meditation's hotkeys. Bindings: the player adds the input.settings lines by hand, as in legacy
// (owner, 2026-11-14); the Key Bindings entries come from modFriendlyMeditation/menu/modFMeditationInput.xml.
// Slice 0 ports one action, ToggleSpawnCampFire (legacy's End key): it flips "Spawn campfire" and says so.

@wrapMethod(CPlayerInput)
function Initialize(isFromLoad : bool, optional previousInput : CPlayerInput)
{
	wrappedMethod(isFromLoad, previousInput);
	theInput.RegisterListener(this, 'OnToggleSpawnCampFire', 'ToggleSpawnCampFire');
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
