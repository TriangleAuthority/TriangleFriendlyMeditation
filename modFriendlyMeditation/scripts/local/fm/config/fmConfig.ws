// FM-MENU: Friendly Meditation's options. The menu is modFriendlyMeditation/menu/modFMeditationConfig.xml
// (Options > Mods > Friendly Meditation, legacy 2.3's two groups, ids and presets); values live in the game's
// user settings. Legacy shipped its defaults as user.settings lines the player pasted by hand; here every option
// has its default in FMOptionDefault (legacy's "Default" presets, the same values as its user.settings.part.txt),
// written when a save loads into options that were never set, and the reads fall back to it while an option is
// empty (as Preparations' port does).

// Default value of an option ("" if unknown). Add new options here, to FMOptionList and to the menu.
function FMOptionDefault(group : name, option : name) : string
{
	switch(group)
	{
		case 'modFriendlyMeditation' :
			switch(option)
			{
				case 'fmedMaxHoursPerMinute' :		return "60";
				case 'fmedHoursPerMinutePerSecond' :	return "10";
				case 'fmedUseTimescale' :		return "false";
				case 'fmedSpawnCampfire' :		return "false";
				case 'fmedDoNotDespawnCampfire' :	return "false";
				// an OPTIONS list: the virtual variable holds the chosen entry ("Hold to advance time" = 0)
				case 'Virtual_fmedHotkeyBehavior' :	return "0";
				case 'fmedBeSilent' :			return "false";
			}
			break;
		case 'modFriendlyMeditationCamera' :
			switch(option)
			{
				case 'fmedUseMeditationCam' :	return "true";
				case 'fmedCamFacePlayer' :	return "true";
				case 'fmedCamFOV' :		return "40";
				case 'fmedCamDistance' :	return "3.8";
				case 'fmedCamPitch' :		return "-15";
				case 'fmedCamXOffset' :		return "0.5";
				case 'fmedCamZOffset' :		return "0.5";
			}
			break;
	}
	return "";
}

// Every option with a default, for FMApplyDefaultOptions.
function FMOptionList(out groups : array<name>, out options : array<name>)
{
	groups.Clear();
	options.Clear();
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedMaxHoursPerMinute');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedHoursPerMinutePerSecond');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedUseTimescale');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedSpawnCampfire');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedDoNotDespawnCampfire');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('Virtual_fmedHotkeyBehavior');
	groups.PushBack('modFriendlyMeditation');	options.PushBack('fmedBeSilent');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedUseMeditationCam');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamFacePlayer');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamFOV');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamDistance');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamPitch');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamXOffset');
	groups.PushBack('modFriendlyMeditationCamera');	options.PushBack('fmedCamZOffset');
}

function FMOptionUnset(option : name, value : string) : bool
{
	return value == "" || (value == "-1" && StrBeginsWith(NameToString(option), "Virtual_"));
}

// Give every unset option its default, keeping values the player has set.
function FMApplyDefaultOptions()
{
	var cfg : CInGameConfigWrapper;
	var groups, options : array<name>;
	var i : int;
	var changed : bool;

	cfg = theGame.GetInGameConfigWrapper();
	FMOptionList(groups, options);
	for(i = 0; i < options.Size(); i += 1)
	{
		if(FMOptionUnset(options[i], cfg.GetVarValue(groups[i], options[i])))
		{
			cfg.SetVarValue(groups[i], options[i], FMOptionDefault(groups[i], options[i]));
			changed = true;
		}
	}
	if(changed)
		theGame.SaveUserSettings();
}

// An option's value, or its default while it is unset.
function FMGetOption(group : name, option : name) : string
{
	var value : string;

	value = theGame.GetInGameConfigWrapper().GetVarValue(group, option);
	if(FMOptionUnset(option, value))
		value = FMOptionDefault(group, option);
	return value;
}

function FMGetOptionBool(group : name, option : name) : bool
{
	return FMGetOption(group, option) == "true";
}

function FMGetOptionFloat(group : name, option : name) : float
{
	return StringToFloat(FMGetOption(group, option));
}

// Legacy's CModFMeditationConfig: every read goes to the options (no cached fields), so a change in the menu
// applies at once.
class CModFMeditationConfig
{
	public function MaxHPM() : float		{ return FMGetOptionFloat('modFriendlyMeditation', 'fmedMaxHoursPerMinute'); }
	public function HPMPerSecond() : float		{ return FMGetOptionFloat('modFriendlyMeditation', 'fmedHoursPerMinutePerSecond'); }
	public function UseTimescale() : bool		{ return FMGetOptionBool('modFriendlyMeditation', 'fmedUseTimescale'); }
	public function BeSilent() : bool		{ return FMGetOptionBool('modFriendlyMeditation', 'fmedBeSilent'); }
	public function SpawnCampFire() : bool		{ return FMGetOptionBool('modFriendlyMeditation', 'fmedSpawnCampfire'); }
	public function DoNotDespawnCampFire() : bool	{ return FMGetOptionBool('modFriendlyMeditation', 'fmedDoNotDespawnCampfire'); }
	public function HotkeyAsToggle() : bool		{ return StringToInt(FMGetOption('modFriendlyMeditation', 'Virtual_fmedHotkeyBehavior')) == 1; }
	public function HotkeyManualFastforward() : bool	{ return StringToInt(FMGetOption('modFriendlyMeditation', 'Virtual_fmedHotkeyBehavior')) == 2; }
	public function UseMeditationCam() : bool	{ return FMGetOptionBool('modFriendlyMeditationCamera', 'fmedUseMeditationCam'); }
	public function CamFacePlayer() : bool		{ return FMGetOptionBool('modFriendlyMeditationCamera', 'fmedCamFacePlayer'); }
	public function CamFOV() : float		{ return FMGetOptionFloat('modFriendlyMeditationCamera', 'fmedCamFOV'); }
	public function CamPitch() : float		{ return FMGetOptionFloat('modFriendlyMeditationCamera', 'fmedCamPitch'); }
	public function CamXOffset() : float		{ return FMGetOptionFloat('modFriendlyMeditationCamera', 'fmedCamXOffset'); }
	public function CamZOffset() : float		{ return FMGetOptionFloat('modFriendlyMeditationCamera', 'fmedCamZOffset'); }
	public function CamDistance() : float		{ return FMGetOptionFloat('modFriendlyMeditationCamera', 'fmedCamDistance'); }

	public function SetSpawnCampFire(val : bool)
	{
		var value : string;

		if(val)
			value = "true";
		else
			value = "false";
		theGame.GetInGameConfigWrapper().SetVarValue('modFriendlyMeditation', 'fmedSpawnCampfire', value);
		theGame.SaveUserSettings();
	}
}

@addField(W3PlayerWitcher)
var fmConfig : CModFMeditationConfig;

@wrapMethod(W3PlayerWitcher)
function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);
	FMApplyDefaultOptions();
	fmConfig = new CModFMeditationConfig in this;
}

// NULL before Geralt has spawned and while playing Ciri.
function GetFMeditationConfig() : CModFMeditationConfig
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	if(!w)
		return NULL;
	return w.fmConfig;
}
