/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




abstract state MeditationBase in W3PlayerWitcher extends ExtendedMovable
{
	//---=== modFriendlyMeditation ===---
	private var camOn, camFacePlayer : bool;
	private var camFOV, camPitch, camXOffset, camZOffset, camDist : float;
	
	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState( prevStateName );
		
		camOn = virtual_parent.fMeditationConfig.UseMeditationCam();
		camFacePlayer = virtual_parent.fMeditationConfig.CamFacePlayer();
		camFOV = virtual_parent.fMeditationConfig.CamFOV();
		camPitch = virtual_parent.fMeditationConfig.CamPitch();
		camXOffset = virtual_parent.fMeditationConfig.CamXOffset();
		camZOffset = virtual_parent.fMeditationConfig.CamZOffset();
		camDist = virtual_parent.fMeditationConfig.CamDistance();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		if(nextStateName != 'MeditationWaiting' && nextStateName != 'Meditation')
		{
			if( camOn && camFacePlayer )
				virtual_parent.fmedRequestCameraHeading(); //restore camera heading
		}
		
		super.OnLeaveState( nextStateName );
	}
	
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		var targetRotation : EulerAngles = thePlayer.GetWorldRotation();
		
		if( camOn && !virtual_parent.GetIsPlayerMeditatingInBed() )
		{
			if( camFacePlayer )
			{
				targetRotation.Yaw += 180.f;
				moveData.pivotRotationController.SetDesiredHeading( targetRotation.Yaw );
				moveData.pivotRotationValue.Yaw	= LerpAngleF( 2.0f * dt, moveData.pivotRotationValue.Yaw, targetRotation.Yaw );
			}
			
			if( camPitch )
			{
				targetRotation.Pitch = camPitch;
				moveData.pivotRotationController.SetDesiredPitch( targetRotation.Pitch );
				moveData.pivotRotationValue.Pitch = LerpAngleF( 1.0f * dt, moveData.pivotRotationValue.Pitch, targetRotation.Pitch );
			}
			
			if( camDist )
				moveData.pivotDistanceController.SetDesiredDistance( camDist );
		
			moveData.pivotPositionController.offsetZ = camZOffset;
			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( camXOffset, 0.f, 0.f ), 0.3f, dt );
		
			return true;
		}
	}
	
	private var fovVel : float;
	event OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
	{
		var camera : CCustomCamera = theGame.GetGameCamera();
		
		if( camOn && camFOV && !virtual_parent.GetIsPlayerMeditatingInBed() )
		{
			DampFloatSpring( camera.fov, fovVel, camFOV, 1.0, dt );
		}
	}
	
	public function StopRequested(optional closeUI : bool)
	{
		virtual_parent.ModEndMeditation();
	}
	//---=== modFriendlyMeditation ===---
	
	
	event OnReactToBeingHit( damageAction : W3DamageAction )
	{
		var ret : bool;
		var tox : W3Effect_Toxicity;
		
		ret = virtual_parent.OnReactToBeingHit(damageAction);
		
		
		tox = (W3Effect_Toxicity)damageAction.causer;
		if(!tox)		
			StopRequested(true);
			
		return ret;
	}
}