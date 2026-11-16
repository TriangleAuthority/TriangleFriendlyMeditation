// FM-FIRE: the campfire of FM's meditation, every meditation but the bed's (legacy InternalBeginMeditation,
// SpawnCampFireTimer, InternalEndMeditation, DeSpawnCampFireTimer); decided in FM's Meditate wrapper. With "Spawn
// campfire" on and no FM campfire within 3 m, Geralt sits down with the Igni pose (behaviour variable MeditateWithIgnite) and the fire appears 4.5 s later, 0.8 m in front
// of him; when he stands up he puts it out (HasCampfire) and it goes 1.5 s later, unless "Do not remove campfire" is
// on. 5.x's sit-down clears MeditateWithIgnite just before PlayerStartAction(PEA_Meditation) and HasCampfire just
// before PlayerStopAction(PEA_Meditation), so FM sets them in calling wrappers of these two.
// With Preparations installed, Preparations decides (PREP-FMED, a runtime link: the two blobs share no
// declarations): FM sets the fact fmed_campfire_query and calls CanMeditate(), and Preparations' wrapper answers in
// prep_fmed_campfire_ok (2 yes, 1 no; 0 = no Preparations) with its rules (a fire near, interiors, settlements,
// timber). FM then starts Preparations' timers by name: PrepCampFireResourcesTimer once the fire is made (the
// timber), PrepCampFireErrorMessageTimer when the meditation starts without the fire it refused. The fire is tagged
// 'fmed_campfire', which Preparations counts as a fire.

@addField(W3PlayerWitcher)
var fmSpawnedCampFire : W3Campfire;

@addField(W3PlayerWitcher)
var fmIgnite : bool;	// this sit-down lights a campfire

@addField(W3PlayerWitcher)
var fmPrepPresent : bool;	// Preparations answered this meditation's campfire query

@addField(W3PlayerWitcher)
var fmCampFireRefused : bool;	// Preparations refused this meditation's campfire

// Decided when a meditation starts: light a fire unless in bed; then Preparations decides if installed, else FM's
// own rule (no FM fire within 3 m).
@addMethod(W3PlayerWitcher)
function FMDecideCampFire()
{
	var answer : int;

	fmIgnite = false;
	fmPrepPresent = false;
	fmCampFireRefused = false;
	if(!fmConfig.SpawnCampFire() || FMInBed())
		return;
	FactsSet('fmed_campfire_query', 1);
	CanMeditate();
	answer = FactsQuerySum('prep_fmed_campfire_ok');
	FactsRemove('fmed_campfire_query');
	FactsRemove('prep_fmed_campfire_ok');
	if(answer == 2)
	{
		fmPrepPresent = true;
		fmIgnite = true;
	}
	else if(answer == 1)
	{
		fmPrepPresent = true;
		fmCampFireRefused = true;
	}
	else
		fmIgnite = !fmSpawnedCampFire || VecDistanceSquared2D(fmSpawnedCampFire.GetWorldPosition(), GetWorldPosition()) > 9.f;
}

@wrapMethod(CR4Player)
function PlayerStartAction(playerAction : EPlayerExplorationAction, optional animName : name) : bool
{
	var witcher : W3PlayerWitcher;
	var ret : bool;

	witcher = (W3PlayerWitcher)this;
	if(playerAction == PEA_Meditation && witcher && witcher.FMIsMeditating())
	{
		SetBehaviorVariable('HasCampfire', 0);
		if(witcher.fmIgnite)
			SetBehaviorVariable('MeditateWithIgnite', 1);
	}
	else if(playerAction == PEA_Meditation && witcher)
	{
		// the meditation action outside a meditation (a place of power's channeling): no campfire poses (FM-POP)
		SetBehaviorVariable('MeditateWithIgnite', 0);
		SetBehaviorVariable('HasCampfire', 0);
	}
	ret = wrappedMethod(playerAction, animName);
	if(ret && playerAction == PEA_Meditation && witcher && witcher.FMIsMeditating() && witcher.fmIgnite)
		AddTimer('FMSpawnCampFireTimer', 4.5, false);
	return ret;
}

@wrapMethod(CR4Player)
function PlayerStopAction(playerAction : EPlayerExplorationAction)
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)this;
	if(playerAction == PEA_Meditation && witcher && witcher.FMIsMeditating())
	{
		RemoveTimer('FMSpawnCampFireTimer');
		if(witcher.fmSpawnedCampFire && !witcher.fmConfig.DoNotDespawnCampFire())
		{
			SetBehaviorVariable('HasCampfire', 1);
			AddTimer('FMDeSpawnCampFireTimer', 1.5, false);
		}
	}
	wrappedMethod(playerAction);
}

@addMethod(W3PlayerWitcher)
timer function FMSpawnCampFireTimer(dt : float, id : int)
{
	var template : CEntityTemplate;
	var pos : Vector;
	var z : float;
	var tags : array<name>;

	if(!FMIsMeditating())
		return;
	template = (CEntityTemplate)LoadResource("environment\decorations\light_sources\campfire\campfire_01.w2ent", true);
	pos = GetWorldPosition() + VecFromHeading(GetHeading()) * Vector(0.8, 0.8, 0);
	if(theGame.GetWorld().NavigationComputeZ(pos, pos.Z - 128, pos.Z + 128, z))
		pos.Z = z;
	if(theGame.GetWorld().PhysicsCorrectZ(pos, z))
		pos.Z = z;
	tags.PushBack('fmed_campfire');
	fmSpawnedCampFire = (W3Campfire)theGame.CreateEntity(template, pos, GetWorldRotation(), , , , , tags);
	if(fmSpawnedCampFire)
	{
		fmSpawnedCampFire.ToggleFire(true);
		if(fmPrepPresent)
			AddTimer('PrepCampFireResourcesTimer', 0.1, false);
	}
}

@addMethod(W3PlayerWitcher)
timer function FMDeSpawnCampFireTimer(dt : float, id : int)
{
	if(fmSpawnedCampFire)
	{
		fmSpawnedCampFire.ToggleFire(false);
		fmSpawnedCampFire.Destroy();
	}
	fmSpawnedCampFire = NULL;
	// the put-out is played: clear it, so 5.x's own sit-down (the clock) does not see it
	SetBehaviorVariable('HasCampfire', 0);
}
