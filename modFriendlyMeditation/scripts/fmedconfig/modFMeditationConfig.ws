//---=== modFriendlyMeditation ===---
class CModFMeditationConfig
{
	public function MaxHPM() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedMaxHoursPerMinute'));
	}
	
	public function HPMPerSecond() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedHoursPerMinutePerSecond'));
	}
	
	public function UseTimescale() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedUseTimescale');
	}
	
	public function BeSilent() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedBeSilent');
	}
	
	public function SpawnCampFire() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedSpawnCampfire');
	}
	
	public function SetSpawnCampFire(val : bool)
	{
		theGame.GetInGameConfigWrapper().SetVarValue('modFriendlyMeditation', 'fmedSpawnCampfire', val);
		theGame.SaveUserSettings();
	}
	
	public function DoNotDespawnCampFire() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'fmedDoNotDespawnCampfire');
	}
	
	public function HotkeyAsToggle() : bool
	{
		return StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'Virtual_fmedHotkeyBehavior')) == 1;
	}
	
	public function HotkeyManualFastforward() : bool
	{
		return StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditation', 'Virtual_fmedHotkeyBehavior')) == 2;
	}
	
	public function UseMeditationCam() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedUseMeditationCam');
	}
	
	public function CamFacePlayer() : bool
	{
		return (bool)theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamFacePlayer');
	}
	
	public function CamFOV() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamFOV'));
	}
	
	public function CamPitch() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamPitch'));
	}
	
	public function CamXOffset() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamXOffset'));
	}
	
	public function CamZOffset() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamZOffset'));
	}
	
	public function CamDistance() : float
	{
		return StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('modFriendlyMeditationCamera', 'fmedCamDistance'));
	}
	
	public function Init()
	{
	}
}

function GetFMeditationConfig() : CModFMeditationConfig
{
	return GetWitcherPlayer().fMeditationConfig;
}
//---=== modFriendlyMeditation ===---
