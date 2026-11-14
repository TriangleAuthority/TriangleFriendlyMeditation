/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




//---=== modFriendlyMeditation ===---
//reworked
state MeditationWaiting in W3PlayerWitcher extends MeditationBase
{
	private var updatedGameTime : GameTime;
	private var storedHoursPerMinute, hoursPerMinute : float;
	private var startedFastforwardSecs, targetTime : float;
	private var fullHealth, isFromClock : bool;
	private var storedGameTime : GameTime;
	private var refilled, timescaleTriggered : bool;
	private var maxHPM, HPMPerSecond : float;
	
	event OnEnterState( prevStateName : name )
	{	
		super.OnEnterState( prevStateName );
		
		//theGame.witcherLog.AddMessage("Entering MeditationWaiting: " + prevStateName);
		
		if( virtual_parent.GetBehaviorVariable('MeditateAbort') > 0 )
		{
			virtual_parent.ModEndMeditation();
		}
		else
		{
			BlockGameplayActions( true );
			maxHPM = virtual_parent.fMeditationConfig.MaxHPM();
			HPMPerSecond = virtual_parent.fMeditationConfig.HPMPerSecond();
			timescaleTriggered = false;
			refilled = false;
			storedHoursPerMinute = theGame.GetHoursPerMinute();
			startedFastforwardSecs = theGame.GetEngineTimeAsSeconds();
			updatedGameTime = theGame.GetGameTime();
			storedGameTime = theGame.GetGameTime();
			isFromClock = virtual_parent.GetMeditationStartedByClock();
			targetTime = virtual_parent.GetMeditationTargetTime();
			hoursPerMinute = storedHoursPerMinute;
			fullHealth = ( virtual_parent.GetStat( BCS_Vitality ) >= virtual_parent.GetStatMax( BCS_Vitality ) );
			theGame.GetFastForwardSystem().BeginFastForward();
			FactsSet('MeditationWaitStartDay', GameTimeDays(storedGameTime));		
			FactsSet('MeditationWaitStartHour', GameTimeHours(storedGameTime));
			FactsSet('MeditationStarted', 1);
			if( !virtual_parent.fMeditationConfig.BeSilent() )
				theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_fmed_started_fastforward" ), , true );
		}
	}
	
	event OnLeaveState( nextStateName : name )
	{
		//theGame.witcherLog.AddMessage("Exiting MeditationWaiting: " + nextStateName);
		
		theGame.GetFastForwardSystem().AllowFastForwardSelfCompletion();
		theGame.SetHoursPerMinute( storedHoursPerMinute );
		if ( timescaleTriggered )
		{
			theGame.RemoveTimeScale( 'FriendlyMeditation' );
			timescaleTriggered = false;
		}
		FactsSet('MeditationStarted', 0);
		BlockGameplayActions( false );
		virtual_parent.CheckWitcherHouseBuffs(GameTimeToSeconds(theGame.GetGameTime()) - GameTimeToSeconds(storedGameTime));
		if( !virtual_parent.fMeditationConfig.BeSilent() )
			theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "message_fmed_ended_fastforward" ), , true );
		
		super.OnLeaveState( nextStateName );
	}
	
	event OnPlayerTickTimer( deltaTime : float )
	{
		super.OnPlayerTickTimer( deltaTime );
		
		if ( isFromClock && targetTime == GameTimeHours( theGame.GetGameTime() ) )
		{
			virtual_parent.ModEndMeditation();
		}
		else
		{
			MeditationUpdate();
		}
	}
	
	private function MeditationUpdate()
	{
		var realTimeSecs, gameTimeSec : float;
		
		if ( GetDayPart( theGame.GetGameTime() ) != GetDayPart( updatedGameTime ) )
		{
			theGame.VibrateControllerVeryLight();
		}
		if ( !timescaleTriggered )
		{
			gameTimeSec = GameTimeToSeconds( theGame.GetGameTime() - updatedGameTime );
			realTimeSecs = ConvertGameSecondsToRealTimeSeconds( gameTimeSec );
			virtual_parent.UpdateEffectsAccelerated( realTimeSecs, hoursPerMinute / storedHoursPerMinute );
		}
		if ( !fullHealth )
		{
			fullHealth = NotifyOnHealthRegenEnded();
		}
		if ( !refilled )
		{
			refilled = MeditationCheckRefill();
		}
		if ( !timescaleTriggered )
		{
			if ( hoursPerMinute < maxHPM )
			{
				hoursPerMinute = MinF( maxHPM, storedHoursPerMinute + ( theGame.GetEngineTimeAsSeconds() - startedFastforwardSecs ) * HPMPerSecond );
				theGame.SetHoursPerMinute( hoursPerMinute );
			}
			else if ( virtual_parent.fMeditationConfig.UseTimescale() )
			{
				timescaleTriggered = true;
				theGame.GetFastForwardSystem().AllowFastForwardSelfCompletion();
				theGame.SetHoursPerMinute( storedHoursPerMinute );
				startedFastforwardSecs = 0;
				theGame.SetTimeScale( hoursPerMinute / storedHoursPerMinute, 'FriendlyMeditation', 100 );
			}
		}
		updatedGameTime = theGame.GetGameTime();
	}
	
	private function NotifyOnHealthRegenEnded() : bool
	{
		if ( virtual_parent.GetStat( BCS_Vitality ) >= virtual_parent.GetStatMax( BCS_Vitality ) )
		{
			theGame.VibrateControllerLight();
			return true;
		}
		return false;
	}
	
	private function MeditationCheckRefill() : bool
	{
		return virtual_parent.MeditationRefill( GameTimeToSeconds(theGame.GetGameTime()) - GameTimeToSeconds(storedGameTime) );
	}
	
	function BlockGameplayActions( lock : bool )
	{
		var exceptions : array< EInputActionBlock >;
		
		exceptions.PushBack( EIAB_OpenMeditation );
		exceptions.PushBack( EIAB_MeditationWaiting );
	
		if ( lock )
		{
			thePlayer.BlockAllActions( 'MeditationWaiting', true, exceptions );
		}	
		else
		{
			thePlayer.BlockAllActions( 'MeditationWaiting', false);
		}
	}
}
//---=== modFriendlyMeditation ===---
