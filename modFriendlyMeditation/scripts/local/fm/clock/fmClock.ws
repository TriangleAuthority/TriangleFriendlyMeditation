// FM-CLOCK and FM-BED: 5.x's meditation clock leads into FM's real-time meditation (legacy's OnMeditate →
// ModStartMeditation(inBed, true, hour)).
// - Choosing an hour on 5.x's clock calls the Meditation state's MeditationWait(hour): FM does not push 5.x's
//   MeditationWaiting (a fixed-speed time-lapse ending in MeditationRestoring's healing); it starts its own
//   fast-forward, in every hotkey mode (legacy: the clock always fast-forwards). The clock stays open over the
//   world with the hours running (5.x shows the world behind it); its slow motion (time scale 0.1, animations ×10)
//   is lifted for the fast-forward.
// - At the chosen hour, or when the clock is closed early (Escape), the clock closes and Geralt stands up
//   (legacy's ModEndMeditation at the target hour).
// - In the witcher house's bed (FM-BED): no sitting animation, 5.x's bed code already allows meditation; after
//   fast-forward in bed, the house's bonuses (legacy's CheckWitcherHouseBuffs: one game hour, rounded up), since
//   FM never calls MeditationRestoring, which applies them in 5.x.

@addField(W3PlayerWitcher)
var fmClockMode : bool;	// this meditation fast-forwards to an hour chosen on the clock

@addField(W3PlayerWitcher)
var fmTargetHour : int;

@addField(W3PlayerWitcher)
var fmClockPending : bool;	// the hour was chosen while 5.x's sit-down still ran

@addMethod(W3PlayerWitcher)
function FMInBed() : bool
{
	var bed : W3WitcherBed;

	bed = (W3WitcherBed)theGame.GetEntityByTag('witcherBed');
	return bed && bed.GetWasUsed();
}

@addMethod(W3PlayerWitcher)
function FMStartClockFastForward()
{
	// sit down if the clock opened first (as 5.x's MeditationWait does)
	if(GetPlayerAction() != PEA_Meditation && !FMInBed())
	{
		SetBehaviorVariable('MeditateWithIgnite', 0);
		PlayerStartAction(PEA_Meditation);
	}
	// the clock's slow motion is not for the fast-forward
	ResetMeditationAnimSpeed();
	theGame.RemoveTimeScale(theGame.GetTimescaleSource(ETS_Meditation));
	fmSeated = true;
	FMStartFastForward();
}

// The chosen hour has come: close the clock (its closing stands Geralt up).
@addMethod(W3PlayerWitcher)
function FMEndClockMeditation()
{
	var menu : CR4CommonMenu;

	FMEndFastForward();
	menu = theGame.GetGuiManager().GetCommonMenu();
	if(menu)
		menu.CloseMenu();
	else
		FMEndMeditation();
}

// Legacy's CheckWitcherHouseBuffs, at the end of a fast-forward.
@addMethod(W3PlayerWitcher)
function FMCheckWitcherHouseBuffs(gameSecs : float)
{
	if(FMInBed() && CeilF(gameSecs / 3600.0) >= 1)
		ApplyWitcherHouseBuffs();
}

@wrapMethod(W3PlayerWitcherStateMeditation)
function MeditationWait(targetHour : int, optional delay : float)
{
	if(thePlayer.IsCiri())
	{
		wrappedMethod(targetHour, delay);
		return;
	}
	virtual_parent.SetWaitTargetHour(targetHour);
	virtual_parent.fmClockMode = true;
	virtual_parent.fmTargetHour = targetHour;
	if(isEntryFunctionLocked)
		virtual_parent.fmClockPending = true;
	else
		virtual_parent.FMStartClockFastForward();
}

// Closing the clock during FM's clock meditation ends it (5.x's clock leaves that to its own wait loop).
@wrapMethod(CR4MeditationClockMenu)
function OnClosingMenu()
{
	var witcher : W3PlayerWitcher;
	var ret : bool;

	witcher = GetWitcherPlayer();
	ret = wrappedMethod();
	if(witcher && witcher.fmClockMode && witcher.FMIsMeditating())
		witcher.FMEndMeditation();
	return ret;
}

// Every meditation but the bed's lights FM's campfire when it is on (legacy's InternalBeginMeditation): decided
// when the meditation starts.
@wrapMethod(W3PlayerWitcher)
function Meditate() : bool
{
	var deciding, ret : bool;

	deciding = !FMIsMeditating() && GetCurrentStateName() != 'MeditationWaiting';
	if(deciding)
		FMDecideCampFire();
	ret = wrappedMethod();
	if(deciding && !ret)
		fmIgnite = false;
	return ret;
}
