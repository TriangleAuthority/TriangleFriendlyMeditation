// FM-CAM: Friendly Meditation's meditation camera (legacy MeditationBase.OnGameCameraTick/PostTick), for FM's
// hotkey meditation. With "Meditation camera" on, FM's camera replaces 5.x's: it faces Geralt ("Face the player"),
// with the options' pitch, distance, height (Z) and side (X) offsets and field of view; a value of 0 leaves that
// part as the exploration camera has it (legacy's rule). With it off, 5.x's own meditation camera stays.
// Standing up: 5.x's Meditation state turns the camera back behind Geralt while he stands (its leaving branch),
// which does what legacy's 1.5 s camera return did.

@addField(W3PlayerWitcher)
var fmCamOn : bool;

@addField(W3PlayerWitcher)
var fmCamFacePlayer : bool;

@addField(W3PlayerWitcher)
var fmCamFOV : float;

@addField(W3PlayerWitcher)
var fmCamPitch : float;

@addField(W3PlayerWitcher)
var fmCamXOffset : float;

@addField(W3PlayerWitcher)
var fmCamZOffset : float;

@addField(W3PlayerWitcher)
var fmCamDist : float;

@addField(W3PlayerWitcher)
var fmCamFOVVel : float;

// The camera options, read once per meditation (legacy read them on entering the state).
@addMethod(W3PlayerWitcher)
function FMReadCameraOptions()
{
	fmCamOn = fmConfig.UseMeditationCam();
	fmCamFacePlayer = fmConfig.CamFacePlayer();
	fmCamFOV = fmConfig.CamFOV();
	fmCamPitch = fmConfig.CamPitch();
	fmCamXOffset = fmConfig.CamXOffset();
	fmCamZOffset = fmConfig.CamZOffset();
	fmCamDist = fmConfig.CamDistance();
	fmCamFOVVel = 0;
}

// FM's camera runs for this meditation.
@addMethod(W3PlayerWitcher)
function FMCameraActive() : bool
{
	return fmHotkeyMode && fmCamOn;
}

// Legacy's OnGameCameraTick.
@addMethod(W3PlayerWitcher)
function FMCameraTick(out moveData : SCameraMovementData, dt : float)
{
	var targetRotation : EulerAngles;

	targetRotation = GetWorldRotation();
	if(fmCamFacePlayer)
	{
		targetRotation.Yaw += 180.f;
		moveData.pivotRotationController.SetDesiredHeading(targetRotation.Yaw);
		moveData.pivotRotationValue.Yaw = LerpAngleF(2.0f * dt, moveData.pivotRotationValue.Yaw, targetRotation.Yaw);
	}
	if(fmCamPitch != 0)
	{
		targetRotation.Pitch = fmCamPitch;
		moveData.pivotRotationController.SetDesiredPitch(targetRotation.Pitch);
		moveData.pivotRotationValue.Pitch = LerpAngleF(1.0f * dt, moveData.pivotRotationValue.Pitch, targetRotation.Pitch);
	}
	if(fmCamDist != 0)
		moveData.pivotDistanceController.SetDesiredDistance(fmCamDist);
	moveData.pivotPositionController.offsetZ = fmCamZOffset;
	DampVectorSpring(moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector(fmCamXOffset, 0.f, 0.f), 0.3f, dt);
}

// Legacy's OnGameCameraPostTick: the field of view.
@addMethod(W3PlayerWitcher)
function FMCameraPostTick(dt : float)
{
	var camera : CCustomCamera;

	if(fmCamFOV != 0)
	{
		camera = theGame.GetGameCamera();
		DampFloatSpring(camera.fov, fmCamFOVVel, fmCamFOV, 1.0, dt);
	}
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnGameCameraTick(out moveData : SCameraMovementData, dt : float)
{
	if(virtual_parent.FMCameraActive() && !isLeavingState)
	{
		virtual_parent.FMCameraTick(moveData, dt);
		return true;
	}
	return wrappedMethod(moveData, dt);
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function OnGameCameraPostTick(out moveData : SCameraMovementData, dt : float)
{
	var ret : bool;

	ret = wrappedMethod(moveData, dt);
	if(virtual_parent.FMCameraActive() && !isLeavingState)
		virtual_parent.FMCameraPostTick(dt);
	return ret;
}
