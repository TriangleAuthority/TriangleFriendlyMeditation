/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




//---=== modFriendlyMeditation ===---
//reworked
state Meditation in W3PlayerWitcher extends MeditationBase
{
	private var meditationIdle, startedFastforward : bool;
	private var noSaveLock : int;
	
	public function StartFastforward()
	{
		if( meditationIdle && !startedFastforward )
		{
			startedFastforward = true;
			if( virtual_parent.GetCurrentStateName() != 'MeditationWaiting' )
				virtual_parent.PushState( 'MeditationWaiting' );
		}
	}

	public function EndFastforward()
	{
		if( startedFastforward )
		{
			startedFastforward = false;
			if( virtual_parent.GetCurrentStateName() == 'MeditationWaiting' )
				virtual_parent.PopState();
		}
	}

	public function IsMeditationIdle() : bool
	{
		return meditationIdle;
	}
	
	private function SetMeditationIdle()
	{
		meditationIdle = true;
		if ( !GetFMeditationConfig().HotkeyManualFastforward() || virtual_parent.GetMeditationStartedByClock() )
			StartFastforward();
	}

	event OnBehaviorGraphNotification( notificationName : name, stateName : name )
	{
		if ( virtual_parent.GetPlayerAction() == PEA_Meditation )
		{
			if( notificationName == 'OnPlayerActionStartFinished' && !meditationIdle )
			{
				SetMeditationIdle();
			}
		}
		parent.OnBehaviorGraphNotification( notificationName, stateName );
	}
	
	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState( prevStateName );
		
		//theGame.witcherLog.AddMessage("Entering Meditation: " + prevStateName);
		
		if( virtual_parent.GetBehaviorVariable('MeditateAbort') > 0 )
		{
			virtual_parent.ModEndMeditation();
		}
		else if(prevStateName != 'MeditationWaiting')
		{
			virtual_parent.SetBehaviorVariable( 'MeditateWithIgnite', 0 );
			virtual_parent.SetBehaviorVariable( 'HasCampfire', 0 );
			meditationIdle = false;
			BlockGameplayActions( true );
			theGame.CreateNoSaveLock( "Meditation", noSaveLock );
			HideItemsInHands();
			InternalBeginMeditation();
			thePlayer.RemoveTimer( 'MeditationModulesOffTimer' );
			thePlayer.AddTimer( 'MeditationModulesOnTimer', 0.1, false ); //FHUD compatibility
		}
	}

	event OnLeaveState( nextStateName : name )
	{
		//theGame.witcherLog.AddMessage("Exiting Meditation: " + nextStateName);
		
		if(nextStateName != 'MeditationWaiting')
		{
			meditationIdle = false;
			BlockGameplayActions( false );
			theGame.ReleaseNoSaveLock( noSaveLock );
			InternalEndMeditation();
			thePlayer.RemoveTimer( 'MeditationModulesOnTimer' );
			thePlayer.AddTimer( 'MeditationModulesOffTimer', 0.1, false ); //FHUD compatibility
			FactsAdd( 'MeditationWaitFinished', 1, 1 );
		}
		
		super.OnLeaveState( nextStateName );
	}
	
	event OnPlayerTickTimer( deltaTime : float )
	{
		super.OnPlayerTickTimer( deltaTime );
		
		if ( virtual_parent.GetPlayerAction() != PEA_Meditation && virtual_parent.GetPlayerAction() != PEA_GoToSleep )
		{
			virtual_parent.ModEndMeditation();
		}
	}
	
	private function InternalBeginMeditation()
	{
		startedFastforward = false;
		if ( virtual_parent.GetIsPlayerMeditatingInBed() )
		{
			virtual_parent.SetBehaviorVariable( 'MeditateWithIgnite', 0 );
			virtual_parent.SetBehaviorVariable( 'HasCampfire', 0 );
			SetMeditationIdle();
		}
		else
		{
			if ( virtual_parent.fMeditationConfig.SpawnCampFire() )
			{
				if ( virtual_parent.fmedCanSpawnCampfire )
				{
					if ( !virtual_parent.spawnedCampFire || VecDistanceSquared2D(virtual_parent.spawnedCampFire.GetWorldPosition(), thePlayer.GetWorldPosition()) > 9.f )
					{
						virtual_parent.SetBehaviorVariable( 'MeditateWithIgnite', 1 );
						thePlayer.AddTimer( 'SpawnCampFireTimer', 4.5, false );
					}
				}
				else // spawning was turned off by Preparations
				{
					thePlayer.AddTimer( 'CampFireErrorMessageTimer', 0.1, false );
				}
			}
			virtual_parent.SetBehaviorVariable( 'HasCampfire', 0 );
			virtual_parent.PlayerStartAction( PEA_Meditation );
		}
	}
	
	timer function SpawnCampFireTimer(dt : float, id : int)
	{
		var template : CEntityTemplate;
		var pos : Vector;
		var z : float;
		var rot : EulerAngles;
		
		template = (CEntityTemplate)LoadResource( "environment\decorations\light_sources\campfire\campfire_01.w2ent", true);
		pos = thePlayer.GetWorldPosition() + VecFromHeading( thePlayer.GetHeading() ) * Vector(0.8, 0.8, 0);
		if( theGame.GetWorld().NavigationComputeZ( pos, pos.Z - 128, pos.Z + 128, z ) )
		{
			pos.Z = z;
		}
		if( theGame.GetWorld().PhysicsCorrectZ( pos, z ) )
		{
			pos.Z = z;
		}
		rot = thePlayer.GetWorldRotation();
		virtual_parent.spawnedCampFire = (W3Campfire)theGame.CreateEntity(template, pos, rot);
		virtual_parent.spawnedCampFire.ToggleFire( true );
		thePlayer.AddTimer( 'CampFireResourcesTimer', 0.1, false ); //Preparations compatibility
	}
	
	private function InternalEndMeditation()
	{
		var wbed : W3WitcherBed;
		
		thePlayer.RemoveTimer( 'SpawnCampFireTimer' );
		wbed = (W3WitcherBed)theGame.GetEntityByTag( 'witcherBed' );
		if ( wbed.GetWasUsed() )
		{
			GetWitcherPlayer().ManageSleeping();
			wbed.SetWasUsed( false );
		}
		if ( startedFastforward )
		{
			EndFastforward();
		}
		if ( virtual_parent.spawnedCampFire && !GetFMeditationConfig().DoNotDespawnCampFire() )
		{
			virtual_parent.SetBehaviorVariable( 'HasCampfire', 1 );
			thePlayer.AddTimer( 'DeSpawnCampFireTimer', 1.5, false );
		}
		if ( virtual_parent.GetPlayerAction() == PEA_Meditation )
		{
			virtual_parent.PlayerStopAction( PEA_Meditation );
		}
		virtual_parent.SetBehaviorVariable('MeditateAbort', 0);
	}
	
	private function HideItemsInHands()
	{
		if ( virtual_parent.GetCurrentMeleeWeaponType() != PW_None )
		{
			virtual_parent.OnEquipMeleeWeapon( PW_None, true, true );
		}
		if ( virtual_parent.IsHoldingItemInLHand() )
		{
			virtual_parent.HideUsableItem( true );
		}
		if ( virtual_parent.rangedWeapon )
		{
			virtual_parent.OnRangedForceHolster( true, true, false );
		}
	}
	
	function BlockGameplayActions( lock : bool )
	{
		var exceptions : array< EInputActionBlock >;
		
		exceptions.PushBack( EIAB_OpenMeditation );
		exceptions.PushBack( EIAB_MeditationWaiting );
		exceptions.PushBack( EIAB_OpenFastMenu );
		exceptions.PushBack( EIAB_OpenInventory );
		exceptions.PushBack( EIAB_OpenAlchemy );
		exceptions.PushBack( EIAB_OpenCharacterPanel );
		exceptions.PushBack( EIAB_OpenJournal );
		exceptions.PushBack( EIAB_OpenMap );
		exceptions.PushBack( EIAB_OpenGlossary );
		exceptions.PushBack( EIAB_RadialMenu );
	
		if ( lock )
		{
			thePlayer.BlockAllActions( 'Meditation', true, exceptions );
		}	
		else
		{
			thePlayer.BlockAllActions( 'Meditation', false);
		}
	}
}
//---=== modFriendlyMeditation ===---
