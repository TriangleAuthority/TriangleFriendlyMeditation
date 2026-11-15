// FM-POP and FM-QUEN: what 5.x still needs of legacy's two fixes.
// - Places of power: 5.x already keeps a meditation started near a place of power (its StopMeditationAction does
//   nothing while Geralt meditates). Legacy also cleared the campfire behaviour variables before the place of
//   power's channeling starts the meditation action, so it does not play the Igni pose or the put-out after an FM
//   meditation with a campfire: FM's PlayerStartAction wrapper (fmFire.ws) clears them when the meditation action
//   starts outside a meditation.
// - Basic Quen: its shield ends on the Quen entity's own timer, in normal time, while FM's fast-forward runs the
//   Quen buff in accelerated time; when the buff is removed during the fast-forward, the shield goes as well
//   (legacy's W3Effect_BasicQuen.OnEffectRemoved: the entity's Expire timer restarted at 0.1 s).

@wrapMethod(CBaseGameplayEffect)
function OnEffectRemoved()
{
	var witcher : W3PlayerWitcher;
	var quen : W3QuenEntity;

	if((W3Effect_BasicQuen)this)
	{
		witcher = GetWitcherPlayer();
		if(witcher && witcher.fmFastForward)
		{
			quen = (W3QuenEntity)witcher.GetSignEntity(ST_Quen);
			if(quen)
			{
				quen.RemoveTimer('Expire');
				quen.AddTimer('Expire', 0.1, false, , , true, true);
			}
		}
	}
	return wrappedMethod();
}
