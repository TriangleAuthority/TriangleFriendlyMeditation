// FM-FIRE: the campfire of FM's hotkey meditation (legacy InternalBeginMeditation, SpawnCampFireTimer,
// InternalEndMeditation, DeSpawnCampFireTimer). With "Spawn campfire" on and no FM campfire within 3 m, Geralt sits
// down with the Igni pose (behaviour variable MeditateWithIgnite) and the fire appears 4.5 s later, 0.8 m in front
// of him; when he stands up he puts it out (HasCampfire) and it goes 1.5 s later, unless "Do not remove campfire" is
// on. 5.x's sit-down clears MeditateWithIgnite just before PlayerStartAction(PEA_Meditation) and HasCampfire just
// before PlayerStopAction(PEA_Meditation), so FM sets them in calling wrappers of these two.
// Preparations' gates (timber, interiors, settlements) and its timers come with its PREP-FMED; the fire is tagged
// 'fmed_campfire' so Preparations can find it by tag.

@addField(W3PlayerWitcher)
var fmSpawnedCampFire : W3Campfire;

@addField(W3PlayerWitcher)
var fmIgnite : bool;	// this sit-down lights a campfire

// Decided when the hotkey starts a meditation: light a fire unless FM's fire is already within 3 m.
@addMethod(W3PlayerWitcher)
function FMDecideCampFire()
{
	fmIgnite = fmConfig.SpawnCampFire()
		&& (!fmSpawnedCampFire || VecDistanceSquared2D(fmSpawnedCampFire.GetWorldPosition(), GetWorldPosition()) > 9.f);
}

@wrapMethod(CR4Player)
function PlayerStartAction(playerAction : EPlayerExplorationAction, optional animName : name) : bool
{
	var witcher : W3PlayerWitcher;
	var ret : bool;

	witcher = (W3PlayerWitcher)this;
	if(playerAction == PEA_Meditation && witcher && witcher.fmHotkeyMode)
	{
		SetBehaviorVariable('HasCampfire', 0);
		if(witcher.fmIgnite)
			SetBehaviorVariable('MeditateWithIgnite', 1);
	}
	ret = wrappedMethod(playerAction, animName);
	if(ret && playerAction == PEA_Meditation && witcher && witcher.fmHotkeyMode && witcher.fmIgnite)
		AddTimer('FMSpawnCampFireTimer', 4.5, false);
	return ret;
}

@wrapMethod(CR4Player)
function PlayerStopAction(playerAction : EPlayerExplorationAction)
{
	var witcher : W3PlayerWitcher;

	witcher = (W3PlayerWitcher)this;
	if(playerAction == PEA_Meditation && witcher && witcher.fmHotkeyMode)
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
		fmSpawnedCampFire.ToggleFire(true);
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
}
