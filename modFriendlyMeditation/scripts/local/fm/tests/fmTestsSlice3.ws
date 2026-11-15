// Slice 3 (test only): FM-CAM. Channel 'FMTest'. Use with slice 2's helpers (manual hotkey mode, so no time passes:
// fmtest_s2_opts(2, false, false), fmtest_s2_press(), fmtest_s2_release()).
//   fmtest_s3_opts(on, face, fov, dist, pitch)   sets the camera options (X and Z offsets stay at their defaults)
//   fmtest_s3_before()                          records the exploration camera
//   fmtest_s3_seated(face, fov)                 a few seconds after sitting: FM's camera (or 5.x's, when off)
//   fmtest_s3_after()                           a few seconds after standing up: behind Geralt, field of view back

@addField(W3PlayerWitcher)
var fmTestFOV : float;

@addField(W3PlayerWitcher)
var fmTestCamHeading : float;

function FMTestLogCamera(label : string)
{
	var cam : CCustomCamera;
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	cam = theGame.GetGameCamera();
	LogChannel('FMTest', "info camera " + label + ": heading " + theCamera.GetCameraHeading() + ", Geralt " + w.GetHeading()
		+ ", fov " + cam.fov + ", distance " + VecDistance(theCamera.GetCameraPosition(), w.GetWorldPosition())
		+ ", height above Geralt " + (theCamera.GetCameraPosition().Z - w.GetWorldPosition().Z) + ", FM camera " + w.FMCameraActive()
		+ ", state " + w.GetCurrentStateName() + ", action " + w.GetPlayerAction());
}

exec function fmtest_s3_opts(on : bool, face : bool, fov : float, dist : float, pitch : float)
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	cfg.SetVarValue('modFriendlyMeditationCamera', 'fmedUseMeditationCam', FMTestBoolString(on));
	cfg.SetVarValue('modFriendlyMeditationCamera', 'fmedCamFacePlayer', FMTestBoolString(face));
	cfg.SetVarValue('modFriendlyMeditationCamera', 'fmedCamFOV', FloatToString(fov));
	cfg.SetVarValue('modFriendlyMeditationCamera', 'fmedCamDistance', FloatToString(dist));
	cfg.SetVarValue('modFriendlyMeditationCamera', 'fmedCamPitch', FloatToString(pitch));
	LogChannel('FMTest', "info camera options: on " + GetFMeditationConfig().UseMeditationCam() + ", face " + GetFMeditationConfig().CamFacePlayer()
		+ ", fov " + GetFMeditationConfig().CamFOV() + ", distance " + GetFMeditationConfig().CamDistance() + ", pitch " + GetFMeditationConfig().CamPitch()
		+ ", x " + GetFMeditationConfig().CamXOffset() + ", z " + GetFMeditationConfig().CamZOffset());
}

exec function fmtest_s3_before()
{
	var w : W3PlayerWitcher;

	w = GetWitcherPlayer();
	w.fmTestFOV = theGame.GetGameCamera().fov;
	w.fmTestCamHeading = theCamera.GetCameraHeading();
	FMTestLogCamera("before");
}

exec function fmtest_s3_seated(face : bool, fov : float)
{
	var w : W3PlayerWitcher;
	var bad : int;
	var behind : float;

	w = GetWitcherPlayer();
	FMTestLogCamera("seated");
	bad += FMTestCheck(w.FMIsMeditating() && w.GetPlayerAction() == PEA_Meditation, "seated");
	behind = AbsF(AngleDistance(theCamera.GetCameraHeading(), w.GetHeading()));
	if(face)
		bad += FMTestCheck(behind > 150, "the camera faces Geralt (" + behind + " degrees from his heading)");
	else
		bad += FMTestCheck(AbsF(AngleDistance(theCamera.GetCameraHeading(), w.fmTestCamHeading)) < 20,
			"the camera keeps its heading (" + theCamera.GetCameraHeading() + ", was " + w.fmTestCamHeading + ")");
	if(fov > 0)
		bad += FMTestCheck(AbsF(theGame.GetGameCamera().fov - fov) < 1, "field of view " + theGame.GetGameCamera().fov + " (option " + fov + ")");
	else
		bad += FMTestCheck(AbsF(theGame.GetGameCamera().fov - w.fmTestFOV) < 1, "field of view unchanged " + theGame.GetGameCamera().fov);
	FMTestResult("fmtest_s3_seated", bad);
}

exec function fmtest_s3_after()
{
	var w : W3PlayerWitcher;
	var bad : int;
	var behind : float;

	w = GetWitcherPlayer();
	FMTestLogCamera("after");
	behind = AbsF(AngleDistance(theCamera.GetCameraHeading(), w.GetHeading()));
	bad += FMTestCheck(!w.FMIsMeditating(), "standing");
	bad += FMTestCheck(behind < 30, "the camera is behind Geralt again (" + behind + " degrees)");
	bad += FMTestCheck(AbsF(theGame.GetGameCamera().fov - w.fmTestFOV) < 1, "field of view back (" + theGame.GetGameCamera().fov + ", was " + w.fmTestFOV + ")");
	FMTestResult("fmtest_s3_after", bad);
}
