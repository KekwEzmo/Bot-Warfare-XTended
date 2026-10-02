/*
	_bot_realism
	Makes bots behave more like people: personality traits, human-like aim,
	reacting to what they hear and backing off when hurt.
	Every feature is toggled at runtime by its own dvar:
		bots_real_traits, bots_real_aim, bots_real_hearing, bots_real_retreat,
		bots_real_counter, bots_real_mood, bots_real_airhide, bots_real_grudge,
		bots_real_hotspots, bots_real_teamintel, bots_real_matchaware, bots_real_slipups
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	Sets up the realism dvars and level state.
*/
init()
{
	if ( getdvar( "bots_real_traits" ) == "" )
	{
		setdvar( "bots_real_traits", true ); // bots get a personality that shapes how they play
	}
	
	if ( getdvar( "bots_real_aim" ) == "" )
	{
		setdvar( "bots_real_aim", true ); // bots overshoot, flinch and aim worse while moving
	}
	
	if ( getdvar( "bots_real_hearing" ) == "" )
	{
		setdvar( "bots_real_hearing", true ); // bots react to gunfire and explosions they hear
	}
	
	if ( getdvar( "bots_real_retreat" ) == "" )
	{
		setdvar( "bots_real_retreat", true ); // bots fall back to cover when badly hurt
	}
	
	if ( getdvar( "bots_real_counter" ) == "" )
	{
		setdvar( "bots_real_counter", true ); // bots change class to counter what keeps killing them
	}
	
	if ( getdvar( "bots_real_mood" ) == "" )
	{
		setdvar( "bots_real_mood", true ); // bots get cocky on a streak and tilted after dying a lot
	}
	
	if ( getdvar( "bots_real_airhide" ) == "" )
	{
		setdvar( "bots_real_airhide", true ); // bots take cover from enemy air killstreaks
	}
	
	if ( getdvar( "bots_real_grudge" ) == "" )
	{
		setdvar( "bots_real_grudge", true ); // bots hunt the player who keeps killing them
	}
	
	if ( getdvar( "bots_real_hotspots" ) == "" )
	{
		setdvar( "bots_real_hotspots", true ); // bots learn where players get kills from, pre-aim, nade and avoid those spots
	}
	
	if ( getdvar( "bots_real_teamintel" ) == "" )
	{
		setdvar( "bots_real_teamintel", true ); // bots tell nearby teammates where enemies are
	}
	
	if ( getdvar( "bots_real_matchaware" ) == "" )
	{
		setdvar( "bots_real_matchaware", true ); // bots play differently when winning, losing or last alive
	}
	
	if ( getdvar( "bots_real_slipups" ) == "" )
	{
		setdvar( "bots_real_slipups", true ); // bots make human mistakes: panic spraying, slow turns when surprised, bad reloads
	}
	
	if ( getdvar( "bots_real_chat" ) == "" )
	{
		setdvar( "bots_real_chat", true ); // bots take time to type, chat in their own style and reply to players
	}
	
	if ( getdvar( "bots_real_voice" ) == "" )
	{
		setdvar( "bots_real_voice", true ); // bots use voice callouts that match what they're doing
	}
	
	if ( getdvar( "bots_real_avenge" ) == "" )
	{
		setdvar( "bots_real_avenge", true ); // bots go after whoever killed a teammate near them
	}
	
	if ( getdvar( "bots_real_adaptive" ) == "" )
	{
		setdvar( "bots_real_adaptive", false ); // enemy bots adjust their skill to keep human players near bots_real_adaptive_kd
	}
	
	if ( getdvar( "bots_real_adaptive_kd" ) == "" )
	{
		setdvar( "bots_real_adaptive_kd", 1.2 ); // the K/D adaptive difficulty aims for
	}
	
	if ( getdvar( "bots_real_banter" ) == "" )
	{
		setdvar( "bots_real_banter", true ); // bots talk to each other and react to special kills
	}
	
	if ( getdvar( "bots_real_parties" ) == "" )
	{
		setdvar( "bots_real_parties", true ); // some bots group up in parties that stick together
	}
	
	if ( getdvar( "bots_real_churn" ) == "" )
	{
		setdvar( "bots_real_churn", true ); // tilted bots sometimes rage quit and someone new joins
	}
	
	if ( getdvar( "bots_real_preaim" ) == "" )
	{
		setdvar( "bots_real_preaim", true ); // bots glance at corners and long sightlines while moving
	}
	
	if ( getdvar( "bots_real_turrets" ) == "" )
	{
		setdvar( "bots_real_turrets", true ); // bots use mounted turrets instead of hopping off
	}
	
	if ( getdvar( "bots_real_rage" ) == "" )
	{
		setdvar( "bots_real_rage", 50 ); // percent of a tilted bot's death messages that are rage
	}
	
	if ( getdvar( "bots_real_bait" ) == "" )
	{
		setdvar( "bots_real_bait", 30 ); // percent chance a bot baits a human it kills
	}
	
	if ( getdvar( "bots_real_recoil" ) == "" )
	{
		setdvar( "bots_real_recoil", true ); // bots' aim climbs while spraying, like recoil (#59)
	}
	
	if ( getdvar( "bots_real_reactive" ) == "" )
	{
		setdvar( "bots_real_reactive", true ); // bots react in chat to the match: streaks, objectives, killstreaks, joins, and chat on their own
	}
	
	if ( getdvar( "bots_real_flame" ) == "" )
	{
		setdvar( "bots_real_flame", 40 ); // percent chance a bot killing a bot starts a flame war
	}
	
	if ( getdvar( "bots_real_mood_streak" ) == "" )
	{
		setdvar( "bots_real_mood_streak", 3 ); // kills or deaths in a row before a bot gets cocky or tilted
	}
	
	if ( getdvar( "bots_real_preset" ) == "" )
	{
		setdvar( "bots_real_preset", "custom" ); // off, casual, competitive, chaos, or custom to set things yourself
	}
	
	level.bots_sounds = List();
	level thread cleanupSounds();
	
	level.bots_hotspots = [];
	level.bots_hotspot_wps = [];
	
	level thread adaptiveDifficultyThink();
	level thread partyThink();
	level thread endOfMatchChurn();
	level thread presetThink();
}

/*
	Personality traits
*/

/*
	Picks a random trait for a new bot.
*/
chooseRandomTrait()
{
	roll = randomint( 100 );
	
	if ( roll < 25 )
	{
		return "rusher";
	}
	
	if ( roll < 60 )
	{
		return "balanced";
	}
	
	if ( roll < 85 )
	{
		return "cautious";
	}
	
	return "support";
}

/*
	Returns the bot's trait, assigning one if the bot doesn't have one yet.
*/
BotGetTrait()
{
	if ( !isdefined( self.pers[ "bots" ][ "trait" ] ) )
	{
		self.pers[ "bots" ][ "trait" ] = chooseRandomTrait();
	}
	
	if ( !getdvarint( "bots_real_traits" ) )
	{
		return "balanced";
	}
	
	return self.pers[ "bots" ][ "trait" ];
}

/*
	Queues a multiplier for a behavior. Personality, mood and match state stack,
	finishBehaviorScaling applies the combined result once.
*/
scaleBehavior( key, multi )
{
	if ( !isdefined( self.bot_real_multi[ key ] ) )
	{
		self.bot_real_multi[ key ] = 1;
	}
	
	self.bot_real_multi[ key ] *= multi;
}

/*
	Applies the stacked multipliers. The combined effect is kept between a quarter and triple
	of the difficulty's value, and camping/crouching are capped so stacked moods never turn a bot into a statue.
*/
finishBehaviorScaling()
{
	keys = getarraykeys( self.bot_real_multi );
	
	for ( i = 0; i < keys.size; i++ )
	{
		key = keys[ i ];
		base = self.pers[ "bots" ][ "behavior" ][ key ];
		value = base * clamp( self.bot_real_multi[ key ], 0.25, 3 );
		
		cap = 100;
		
		if ( key == "camp" )
		{
			cap = 25;
		}
		else if ( key == "crouch" )
		{
			cap = 40;
		}
		
		// never cap below what the difficulty already set
		if ( cap < base )
		{
			cap = base;
		}
		
		self.pers[ "bots" ][ "behavior" ][ key ] = int( clamp( value, 0, cap ) );
	}
	
	self.bot_real_multi = [];
}

/*
	Applies the trait on top of the difficulty's behavior values.
	Called right after the difficulty resets them, so it never compounds.
*/
applyTraitBehavior()
{
	self.bot_real_multi = [];
	
	self applyMoodBehavior();
	self applyMatchBehavior();
	self applyPersonalityBehavior();
	self applyPartyBehavior();
	
	self finishBehaviorScaling();
}

/*
	Personality's share of the behavior scaling.
*/
applyPersonalityBehavior()
{
	if ( !getdvarint( "bots_real_traits" ) )
	{
		return;
	}
	
	switch ( self BotGetTrait() )
	{
		case "rusher":
			self scaleBehavior( "strafe", 1.3 );
			self scaleBehavior( "sprint", 1.5 );
			self scaleBehavior( "camp", 0.2 );
			self scaleBehavior( "follow", 0.5 );
			self scaleBehavior( "crouch", 0.5 );
			self scaleBehavior( "jump", 1.3 );
			break;
			
		case "cautious":
			self scaleBehavior( "strafe", 0.8 );
			self scaleBehavior( "sprint", 0.6 );
			self scaleBehavior( "camp", 2.5 );
			self scaleBehavior( "follow", 0.8 );
			self scaleBehavior( "crouch", 2 );
			self scaleBehavior( "jump", 0.5 );
			self scaleBehavior( "nade", 1.3 );
			break;
			
		case "support":
			self scaleBehavior( "follow", 4 );
			self scaleBehavior( "nade", 1.2 );
			break;
	}
}

/*
	Health percentage at which the bot falls back.
*/
getRetreatHealthPercent()
{
	percent = 35;
	
	switch ( self BotGetTrait() )
	{
		case "rusher":
			percent = 20;
			break;
			
		case "cautious":
			percent = 55;
			break;
	}
	
	switch ( self BotGetMood() )
	{
		case "cocky":
			percent *= 0.6;
			break;
			
		case "tilted":
			percent *= 1.3;
			break;
	}
	
	switch ( self getMatchState() )
	{
		case "desperate":
			percent *= 0.7;
			break;
			
		case "protective":
			percent *= 1.2;
			break;
			
		case "clutch":
			percent *= 1.4;
			break;
	}
	
	// stacking personality, mood and match state must not make a bot flee at full health, or never flee
	return clamp( percent, 10, 60 );
}

/*
	Chance the bot pushes towards a noise it heard.
*/
getInvestigateChance()
{
	chance = 55;
	
	switch ( self BotGetTrait() )
	{
		case "rusher":
			chance = 85;
			break;
			
		case "cautious":
			chance = 25;
			break;
			
		case "support":
			chance = 40;
			break;
	}
	
	switch ( self BotGetMood() )
	{
		case "cocky":
			chance += 15;
			break;
			
		case "tilted":
			chance -= 20;
			break;
	}
	
	switch ( self getMatchState() )
	{
		case "desperate":
			chance += 15;
			break;
			
		case "protective":
			chance -= 10;
			break;
			
		case "clutch":
			// last alive doesn't go chasing noises
			chance = 0;
			break;
	}
	
	chance = int( chance * self getSideQuestFactor() );
	
	return int( clamp( chance, 0, 100 ) );
}

/*
	Human-like aim
*/

/*
	How sloppy the bot is, 1 for the easiest bot down to about 0.14 for the hardest.
*/
getSloppiness()
{
	base = int( clamp( self getEffectiveSkill(), 1, 7 ) );
	return ( 8 - base ) / 7;
}

/*
	Adds movement sway, tracking lag, overshoot and flinch to a target's aim offset.
	Called after the normal aim offset is computed.
*/
applyHumanAim( obj, ent, theTime )
{
	if ( !getdvarint( "bots_real_aim" ) )
	{
		return;
	}
	
	sloppy = self getSloppiness();
	dist = sqrt( obj.dist );
	distScale = clamp( dist / 1000, 0.5, 2 );
	offset = ( 0, 0, 0 );
	
	// our own movement throws the aim around, more so while or right after sprinting
	moveFactor = clamp( length( self getvelocity() ) / 190, 0, 1.5 );
	
	if ( self.bot.issprinting )
	{
		moveFactor += 1;
	}
	else if ( self.bot.sprintendtime != -1 && theTime - self.bot.sprintendtime < 600 )
	{
		moveFactor += 1 - ( theTime - self.bot.sprintendtime ) / 600;
	}
	
	// a target moving across our view is harder to track
	lateral = ( 0, 0, 0 );
	
	if ( isplayer( ent ) )
	{
		tvel = ent getvelocity();
		dir = vectornormalize( ent.origin - self.origin );
		lateral = tvel - dir * vectordot( tvel, dir );
	}
	
	targetFactor = clamp( length( lateral ) / 190, 0, 1.5 );
	
	// sway changes direction a few times a second instead of every frame
	if ( !isdefined( obj.real_sway_time ) || theTime - obj.real_sway_time >= 250 )
	{
		obj.real_sway_time = theTime;
		obj.real_sway = vectornormalize( ( randomfloatrange( -1, 1 ), randomfloatrange( -1, 1 ), randomfloatrange( -1, 1 ) ) );
	}
	
	offset += obj.real_sway * ( moveFactor + targetFactor * 0.75 ) * ( 2 + sloppy * 10 ) * distScale;
	
	// aim trails behind a strafing target
	offset -= lateral * 0.05 * ( 0.3 + sloppy );
	
	// swinging onto a new target overshoots past it, then settles back
	if ( !isdefined( obj.real_overshoot_time ) || ( obj.trace_time <= 50 && theTime - obj.real_overshoot_time > 1000 ) )
	{
		eye = self geteye();
		angles = self getplayerangles();
		
		if ( getConeDot( ent.origin, eye, angles ) < 0.9 )
		{
			lookPoint = eye + anglestoforward( angles ) * dist;
			deg = 2 + sloppy * 6;
			obj.real_overshoot = vectornormalize( ent.origin - lookPoint ) * dist * ( sin( deg ) / cos( deg ) );
			obj.real_overshoot_time = theTime;
		}
	}
	
	if ( isdefined( obj.real_overshoot_time ) && theTime - obj.real_overshoot_time < 500 )
	{
		offset += obj.real_overshoot * ( 1 - ( theTime - obj.real_overshoot_time ) / 500 );
	}
	
	// getting shot knocks the aim off for a moment
	if ( isdefined( self.bot.real_flinch_time ) && theTime - self.bot.real_flinch_time < 350 )
	{
		units = dist * self.bot.real_flinch_deg * 0.01745;
		offset += self.bot.real_flinch_dir * units * ( 1 - ( theTime - self.bot.real_flinch_time ) / 350 );
	}
	
	obj.aim_offset += offset;
}

/*
	Called when the bot takes damage, starts a flinch.
*/
onDamaged( eAttacker, iDamage )
{
	if ( !isdefined( self.bot ) )
	{
		return;
	}
	
	self noteSurprise( eAttacker );
	
	if ( !getdvarint( "bots_real_aim" ) )
	{
		return;
	}
	
	self.bot.real_flinch_time = gettime();
	self.bot.real_flinch_dir = vectornormalize( ( randomfloatrange( -1, 1 ), randomfloatrange( -1, 1 ), randomfloatrange( 0.2, 1 ) ) );
	self.bot.real_flinch_deg = clamp( iDamage / 10, 1, 4 ) * ( 1 + self getSloppiness() );
}

/*
	Hearing
*/

/*
	Registers a sound bots can hear.
*/
addSoundEvent( origin, owner, radius, kind )
{
	if ( !getdvarint( "bots_real_hearing" ) || !isdefined( level.bots_sounds ) )
	{
		return;
	}
	
	snd = spawnstruct();
	snd.origin = origin;
	snd.owner = owner;
	snd.team = undefined;
	snd.radius = radius;
	snd.kind = kind;
	snd.time = gettime();
	
	if ( isdefined( owner ) && isdefined( owner.team ) )
	{
		snd.team = owner.team;
	}
	
	level.bots_sounds ListAdd( snd );
}

/*
	Registers a gunshot, at most twice a second per player so full autos don't flood the list.
*/
addGunshotSound()
{
	if ( isdefined( self.bots_last_sound_time ) && gettime() - self.bots_last_sound_time < 500 )
	{
		return;
	}
	
	self.bots_last_sound_time = gettime();
	
	radius = 2000;
	
	if ( issubstr( self getcurrentweapon(), "_silencer" ) )
	{
		radius = 250;
	}
	
	addSoundEvent( self.origin, self, radius, "gunfire" );
}

/*
	Registers an explosion when this grenade goes off.
*/
watchExplosionSound( owner )
{
	org = self.origin;
	
	while ( isdefined( self ) )
	{
		org = self.origin;
		wait 0.25;
	}
	
	addSoundEvent( org, owner, 2500, "explosion" );
}

/*
	Drops sounds older than a second.
*/
cleanupSounds()
{
	for ( ;; )
	{
		wait 0.5;
		
		theTime = gettime();
		
		for ( i = level.bots_sounds.count - 1; i >= 0; i-- )
		{
			if ( theTime - level.bots_sounds.data[ i ].time > 1000 )
			{
				level.bots_sounds ListRemove( level.bots_sounds.data[ i ] );
			}
		}
	}
}

/*
	Returns the closest enemy sound the bot hasn't reacted to yet.
*/
getHeardSound()
{
	hearMulti = 1;
	
	if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 2 )
	{
		hearMulti = 0.6;
	}
	
	best = undefined;
	bestDist = 2147483647;
	
	for ( i = level.bots_sounds.count - 1; i >= 0; i-- )
	{
		snd = level.bots_sounds.data[ i ];
		
		if ( snd.time <= self.bot_real_heard_time )
		{
			continue;
		}
		
		if ( isdefined( snd.owner ) && snd.owner == self )
		{
			continue;
		}
		
		if ( level.teambased && isdefined( snd.team ) && snd.team == self.team )
		{
			continue;
		}
		
		radius = snd.radius * hearMulti;
		dist = distancesquared( self.origin, snd.origin );
		
		if ( dist > radius * radius || dist > bestDist )
		{
			continue;
		}
		
		best = snd;
		bestDist = dist;
	}
	
	self.bot_real_heard_time = gettime();
	
	return best;
}

/*
	Looks towards a noise for a moment without taking over someone else's aim.
*/
lookTowardSound( origin )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( self HasScriptAimPos() )
	{
		return;
	}
	
	pos = origin + ( 0, 0, 40 );
	self SetScriptAimPos( pos );
	
	self waittill_notify_or_timeout( "new_enemy", 1.5 + randomfloat( 1 ) );
	
	if ( self HasScriptAimPos() && self GetScriptAimPos() == pos )
	{
		self ClearScriptAimPos();
	}
}

/*
	Reacts to one sound: target the source if visible, otherwise look and maybe go check it out.
*/
bot_hearing_react( snd )
{
	self BotNotifyBotEvent( "hear", "start", snd.kind, snd.origin );
	
	owner = snd.owner;
	
	if ( isdefined( owner ) && isplayer( owner ) && isreallyalive( owner ) && distancesquared( self.origin, owner.origin ) < 1500 * 1500 )
	{
		if ( bullettracepassed( self geteye(), owner gettagorigin( "j_spineupper" ), false, owner ) )
		{
			self setAttacker( owner );
			return;
		}
	}
	
	self thread lookTowardSound( snd.origin );
	
	if ( self BotGetTrait() == "cautious" )
	{
		self BotSetStance( "crouch" );
	}
	
	if ( self HasScriptGoal() || self.bot_lock_goal )
	{
		return;
	}
	
	if ( distancesquared( self.origin, snd.origin ) < 200 * 200 )
	{
		return;
	}
	
	if ( randomint( 100 ) >= self getInvestigateChance() )
	{
		return;
	}
	
	// cautious bots listen for a bit before moving
	if ( self BotGetTrait() == "cautious" )
	{
		wait 1.5;
		
		if ( self hasThreat() || self HasScriptGoal() || self.bot_lock_goal )
		{
			return;
		}
	}
	
	self BotNotifyBotEvent( "hear", "go", snd.kind, snd.origin );
	
	self SetScriptGoal( snd.origin, 128 );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "hear", "stop", snd.kind, snd.origin );
}

/*
	Bots listen for gunfire and explosions.
*/
bot_hearing_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self.bot_real_heard_time = gettime();
	
	for ( ;; )
	{
		wait 0.5;
		
		if ( !getdvarint( "bots_real_hearing" ) )
		{
			self.bot_real_heard_time = gettime();
			continue;
		}
		
		if ( self hasThreat() || self isusingremote() || self BotIsFrozen() )
		{
			self.bot_real_heard_time = gettime();
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}
		
		snd = self getHeardSound();
		
		if ( !isdefined( snd ) )
		{
			continue;
		}
		
		self bot_hearing_react( snd );
	}
}

/*
	Self-preservation
*/

/*
	Finds a nearby waypoint that the danger can't see, not closer to the danger than we are.
*/
findCoverFrom( danger )
{
	dangerEye = danger.origin + ( 0, 0, 40 );
	
	if ( isplayer( danger ) )
	{
		dangerEye = danger geteye();
	}
	
	if ( !level.waypoints.size )
	{
		// no waypoints, just back straight away
		away = vectornormalize( ( self.origin[ 0 ] - danger.origin[ 0 ], self.origin[ 1 ] - danger.origin[ 1 ], 0 ) );
		return playerphysicstrace( self.origin + ( 0, 0, 32 ), self.origin + ( 0, 0, 32 ) + away * 300, false, self );
	}
	
	myDangerDist = distancesquared( self.origin, danger.origin );
	candidates = NewHeap( ::closerFirst );
	
	// cheap distance checks first, then the expensive traces on the nearest few
	for ( i = level.waypoints.size - 1; i >= 0; i-- )
	{
		wp = level.waypoints[ i ];
		dist = distancesquared( wp.origin, self.origin );
		
		if ( dist < 150 * 150 || dist > 900 * 900 )
		{
			continue;
		}
		
		if ( distancesquared( wp.origin, danger.origin ) < myDangerDist )
		{
			continue;
		}
		
		candidates HeapInsert( makeCandidate( wp.origin, dist ) );
	}
	
	for ( traces = 0; traces < 15 && candidates.data.size; traces++ )
	{
		c = candidates.data[ 0 ];
		candidates HeapRemove();
		
		if ( !bullettracepassed( dangerEye, c.origin + ( 0, 0, 50 ), false, danger ) )
		{
			return c.origin;
		}
	}
	
	return undefined;
}

/*
	A waypoint candidate for the nearest-first searches.
*/
makeCandidate( origin, dist )
{
	c = spawnstruct();
	c.origin = origin;
	c.dist = dist;
	return c;
}

/*
	Heap comparator, nearest candidate first.
*/
closerFirst( item, item2 )
{
	return item.dist < item2.dist;
}

/*
	Holds at cover until healed, reloading if the mag is low.
*/
holdAtCover()
{
	self BotStopMoving( true );
	
	if ( self BotGetTrait() == "cautious" )
	{
		self BotSetStance( "crouch" );
	}
	
	curWeap = self getcurrentweapon();
	
	if ( curWeap != "none" && !isweaponcliponly( curWeap ) && self getweaponammostock( curWeap ) && self getweaponammoclip( curWeap ) < weaponclipsize( curWeap ) * 0.6 )
	{
		self thread maps\mp\bots\_bot_internal::reload();
	}
	
	for ( i = 0; i < 24; i++ )
	{
		wait 0.25;
		
		if ( !getdvarint( "bots_real_retreat" ) || self.health >= self.maxhealth * 0.9 )
		{
			break;
		}
		
		// something more important came up (objective, bomb, etc)
		if ( self HasScriptGoal() || self.bot_lock_goal || self isPlanting() || self isDefusing() )
		{
			break;
		}
	}
	
	self BotStopMoving( false );
}

/*
	Falls back to cover from the danger, shooting on the way.
*/
bot_retreat( danger )
{
	cover = self findCoverFrom( danger );
	
	if ( !isdefined( cover ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "retreat", "start", danger );
	
	// no bot_lock_goal: having a goal already keeps side activities away, and objective scripts
	// (which only check the lock) are allowed to pull the bot out of a retreat
	// a leftover aim position (camping etc) would stop the bot shooting back while backing off
	self ClearScriptAimPos();
	self SetPriorityObjective();
	self SetScriptGoal( cover, 32 );
	
	ret = self waittill_any_timeout( 5, "goal", "bad_path", "new_goal" );
	
	self ClearPriorityObjective();
	
	if ( ret != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( ret == "goal" )
	{
		self holdAtCover();
	}
	
	self BotNotifyBotEvent( "retreat", "stop", danger );
}

/*
	Watches health and falls back when it gets low mid-fight.
*/
bot_self_preservation_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	nextTime = 0;
	
	for ( ;; )
	{
		wait 0.25;
		
		if ( !getdvarint( "bots_real_retreat" ) || gettime() < nextTime )
		{
			continue;
		}
		
		if ( !isdefined( self.maxhealth ) || self.maxhealth <= 0 )
		{
			continue;
		}
		
		// the threshold never goes above 60%, so skip working it out while healthier than that
		if ( self.health > self.maxhealth * 0.6 )
		{
			continue;
		}
		
		threshold = self getRetreatHealthPercent();
		
		// easy bots are worse at knowing when to back off
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 2 )
		{
			threshold *= 0.6;
		}
		
		if ( self.health > self.maxhealth * threshold / 100 )
		{
			continue;
		}
		
		if ( self isusingremote() || self inLastStand() || self isjuggernaut() || self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() || self.bot_lock_goal || self HasBotJavelinLocation() )
		{
			continue;
		}
		
		danger = self getThreat();
		
		if ( !isdefined( danger ) )
		{
			continue;
		}
		
		self bot_retreat( danger );
		nextTime = gettime() + 8000;
	}
}

/*
	Personality loadouts
*/

/*
	Weapon classes this bot's personality prefers, as a set keyed by statstable class.
*/
getPreferredWeaponClasses()
{
	answer = [];
	
	switch ( self BotGetTrait() )
	{
		case "rusher":
			answer[ "weapon_smg" ] = true;
			answer[ "weapon_shotgun" ] = true;
			break;
			
		case "cautious":
			answer[ "weapon_sniper" ] = true;
			answer[ "weapon_assault" ] = true;
			break;
			
		case "support":
			answer[ "weapon_lmg" ] = true;
			answer[ "weapon_assault" ] = true;
			break;
	}
	
	return answer;
}

/*
	Support bots usually run support streaks, when the server allows it and they have it unlocked.
*/
adjustStreakTypeForTrait( ksType )
{
	if ( self BotGetTrait() != "support" || randomint( 100 ) >= 60 )
	{
		return ksType;
	}
	
	if ( getdvarint( "bots_loadout_allow_op" ) < 1 )
	{
		return ksType;
	}
	
	if ( !self isitemunlocked( "streaktype_support" ) )
	{
		return ksType;
	}
	
	rank = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) );
	
	if ( rank < maps\mp\bots\_bot_script::getUnlockLevel( "streaktype_support" ) )
	{
		return ksType;
	}
	
	return "streaktype_support";
}

/*
	Bot status
*/

/*
	Turns a bot event into a readable activity, undefined if the event isn't an activity.
*/
friendlyBotState( msg, a, b )
{
	switch ( msg )
	{
		case "camp":
			return "camping";
			
		case "follow":
			return "following a teammate";
			
		case "follow_threat":
			return "chasing an enemy";
			
		case "hear":
			if ( a == "go" )
			{
				return "checking a noise";
			}
			
			return "heard a noise";
			
		case "retreat":
			return "retreating";
			
		case "heard_target":
			return "hunting footsteps";
			
		case "uav_target":
			return "hunting a radar ping";
			
		case "revenge":
			return "going for revenge";
			
		case "crate_cap":
			return "getting a care package";
			
		case "box_cap":
			return "getting armor";
			
		case "killstreak":
			return "calling in a killstreak";
			
		case "attack_equ":
			return "destroying equipment";
			
		case "attack_vehicle":
			return "shooting a killstreak";
			
		case "turret_attack":
			return "attacking a turret";
			
		case "tube":
		case "nade":
		case "equ":
		case "jav":
			return "using equipment";
			
		case "revive":
			return "reviving";
			
		case "airhide":
			return "hiding from air support";
			
		case "avenge":
			if ( a == "go" )
			{
				return "avenging a teammate";
			}
			
			return undefined;
			
		case "hotspot":
			if ( a == "nade" )
			{
				return "nading a camping spot";
			}
			
			if ( a == "check" )
			{
				return "checking a camping spot";
			}
			
			return undefined;
			
		case "intel":
			if ( a == "go" )
			{
				return "moving up to help a teammate";
			}
			
			return undefined;
			
		case "grudge":
			if ( a == "hunt" && isdefined( b ) && isplayer( b ) )
			{
				return "hunting " + b.name;
			}
			
			return undefined;
			
		case "dom":
		case "hq":
		case "sab":
		case "sd":
		case "cap":
		case "dem":
		case "gtnw":
		case "oneflag":
		case "arena":
		case "vip":
		case "conf":
		case "grnd":
		case "tdef":
			if ( isdefined( b ) && isstring( b ) )
			{
				return "objective (" + msg + " " + b + ")";
			}
			
			return "objective (" + msg + ")";
	}
	
	return undefined;
}

/*
	Tracks what the bot is currently doing from its bot events.
*/
watchBotStatus()
{
	self endon( "disconnect" );
	
	self.bot_real_state = undefined;
	self.bot_real_state_time = 0;
	
	for ( ;; )
	{
		self waittill( "bot_event", msg, a, b );
		
		if ( !isdefined( a ) || !isstring( a ) )
		{
			continue;
		}
		
		if ( a == "stop" || a == "stop_hunt" )
		{
			self.bot_real_state = undefined;
			continue;
		}
		
		if ( a != "start" && a != "go" && a != "call" && a != "camp" && a != "go_ti" && a != "camp_ti" && a != "hunt" && a != "check" && a != "nade" )
		{
			continue;
		}
		
		state = friendlyBotState( msg, a, b );
		
		if ( !isdefined( state ) )
		{
			continue;
		}
		
		self.bot_real_state = state;
		self.bot_real_state_time = gettime();
	}
}

/*
	One line describing the bot: personality, skill and what it's doing.
*/
getBotStatusLine()
{
	trait = "none";
	
	if ( isdefined( self.pers[ "bots" ] ) && isdefined( self.pers[ "bots" ][ "trait" ] ) )
	{
		trait = self.pers[ "bots" ][ "trait" ];
	}
	
	if ( !getdvarint( "bots_real_traits" ) )
	{
		trait += " (off)";
	}
	
	if ( isdefined( self.pers[ "bots" ] ) )
	{
		trait += ", " + self maps\mp\bots\_bot_chat::getChatGen();
	}
	
	mood = self BotGetMood();
	
	if ( mood != "normal" )
	{
		trait += ", " + mood;
	}
	
	matchState = self getMatchState();
	
	if ( matchState != "normal" )
	{
		trait += ", " + matchState;
	}
	
	grudge = self getGrudgeName();
	
	if ( isdefined( grudge ) )
	{
		trait += ", grudge vs " + grudge;
	}
	
	skill = "?";
	
	if ( isdefined( self.pers[ "bots" ] ) && isdefined( self.pers[ "bots" ][ "skill" ] ) )
	{
		skill = self.pers[ "bots" ][ "skill" ][ "base" ] + "";
		effective = self getEffectiveSkill();
		
		if ( effective != self.pers[ "bots" ][ "skill" ][ "base" ] )
		{
			skill += " (playing at " + effective + ")";
		}
	}
	
	state = "roaming";
	
	if ( !isreallyalive( self ) )
	{
		state = "dead";
	}
	else
	{
		// activities without a stop event expire, and nothing carries over from a previous life
		if ( isdefined( self.bot_real_state ) && gettime() - self.bot_real_state_time < 15000 && ( !isdefined( self.lastspawntime ) || self.bot_real_state_time >= self.lastspawntime ) )
		{
			state = self.bot_real_state;
		}
		
		if ( isdefined( self.bot ) && self hasThreat() )
		{
			state = "fighting, " + state;
		}
	}
	
	return trait + ", skill " + skill + ", " + state;
}

/*
	Prints every bot's status to the console only, for the menu's bot status page.
*/
printBotStatusConsole( a, b )
{
	bots = getBotArray();
	
	BotBuiltinPrintConsole( "---- Bot Warfare XTended status (" + bots.size + " bots) ----" );
	
	for ( i = 0; i < bots.size; i++ )
	{
		if ( isdefined( bots[ i ] ) )
		{
			BotBuiltinPrintConsole( bots[ i ].name + ": " + bots[ i ] getBotStatusLine() );
		}
	}
	
	self iprintln( "Printed " + bots.size + " bots to the console (~)" );
}

/*
	Prints every bot's status to the killfeed and the console. Called from the menu on the player.
*/
printBotStatus( a, b )
{
	self endon( "disconnect" );
	
	bots = getBotArray();
	
	if ( !bots.size )
	{
		self iprintln( "No bots in the game." );
		return;
	}
	
	BotBuiltinPrintConsole( "---- Bot Warfare status (" + bots.size + " bots) ----" );
	
	for ( i = 0; i < bots.size; i++ )
	{
		bot = bots[ i ];
		
		if ( !isdefined( bot ) )
		{
			continue;
		}
		
		line = bot.name + ": " + bot getBotStatusLine();
		
		BotBuiltinPrintConsole( line );
		self iprintln( line );
		wait 0.3;
	}
	
	self iprintln( "Full list is in the console (~)." );
}

/*
	Kill tracking, feeds mood, grudges and counter-picking
*/

/*
	Called for every player death, before the game handles it.
*/
onAnyPlayerKilled( eAttacker, sWeapon, sMeansOfDeath, sHitLoc )
{
	attackerIsPlayer = ( isdefined( eAttacker ) && isplayer( eAttacker ) && eAttacker != self );
	
	if ( attackerIsPlayer )
	{
		self recordHotspotKill( eAttacker, sWeapon );
	}
	
	if ( attackerIsPlayer && eAttacker is_bot() && isdefined( eAttacker.pers[ "bots" ] ) )
	{
		eAttacker onBotGotKill( self );
	}
	
	// #114: bonus XP for killing bots
	if ( attackerIsPlayer && !eAttacker is_bot() && self is_bot() && getdvarfloat( "bots_xp_multiplier" ) > 1 )
	{
		extra = int( maps\mp\gametypes\_rank::getscoreinfovalue( "kill" ) * ( getdvarfloat( "bots_xp_multiplier" ) - 1 ) );
		
		if ( extra > 0 )
		{
			eAttacker thread maps\mp\gametypes\_rank::giverankxp( "kill", extra );
		}
	}
	
	if ( attackerIsPlayer )
	{
		self alertAvengers( eAttacker );
		self noteSpecialKill( eAttacker, sWeapon, sMeansOfDeath, sHitLoc );
		level thread maps\mp\bots\_bot_chat::reactToKill( eAttacker, self, sWeapon, sMeansOfDeath );
	}
	
	if ( !self is_bot() || !isdefined( self.pers[ "bots" ] ) )
	{
		return;
	}
	
	self onBotDied();
	self maybeRageQuit();
	
	if ( !attackerIsPlayer || ( level.teambased && isdefined( eAttacker.team ) && eAttacker.team == self.team ) )
	{
		return;
	}
	
	self noteGrudgeDeath( eAttacker );
	self noteCounterDeath( eAttacker, sWeapon, sMeansOfDeath );
}

/*
	Teammates who saw the victim go down may go after the killer. Called on the victim.
*/
alertAvengers( killer )
{
	if ( !getdvarint( "bots_real_avenge" ) || !level.teambased || !isdefined( self.team ) || !isdefined( killer.team ) || killer.team == self.team )
	{
		return;
	}
	
	for ( i = 0; i < level.players.size; i++ )
	{
		mate = level.players[ i ];
		
		if ( mate == self || !isdefined( mate.team ) || mate.team != self.team || !mate is_bot() || !isdefined( mate.bot ) || !isreallyalive( mate ) )
		{
			continue;
		}
		
		dist = distancesquared( mate.origin, self.origin );
		
		if ( dist > 1500 * 1500 )
		{
			continue;
		}
		
		// close enough to hear it, or saw it happen
		if ( dist > 500 * 500 && !bullettracepassed( mate geteye(), self.origin + ( 0, 0, 40 ), false, self ) )
		{
			continue;
		}
		
		mate thread avengeTeammate( killer, killer.origin, self.name );
	}
}

/*
	Goes after the player who just killed a nearby teammate.
*/
avengeTeammate( killer, pos, victimName )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	// a moment to react
	wait randomfloatrange( 0.2, 0.6 );
	
	if ( !isdefined( killer ) || !isplayer( killer ) )
	{
		return;
	}
	
	self.bot_real_avenge = spawnstruct();
	self.bot_real_avenge.killer = killer.name;
	self.bot_real_avenge.victim = victimName;
	self.bot_real_avenge.time = gettime();
	
	// can see them, just take the shot
	if ( isreallyalive( killer ) && bullettracepassed( self geteye(), killer gettagorigin( "j_spineupper" ), false, killer ) )
	{
		self setAttacker( killer );
		return;
	}
	
	if ( self hasThreat() || self HasScriptGoal() || self.bot_lock_goal || self BotIsFrozen() || self isusingremote() || self isPlanting() || self isDefusing() )
	{
		return;
	}
	
	chance = 50;
	
	switch ( self BotGetTrait() )
	{
		case "rusher":
			chance = 70;
			break;
			
		case "support":
			chance = 60;
			break;
			
		case "cautious":
			chance = 25;
			break;
	}
	
	if ( self isPartyMateName( victimName ) )
	{
		chance = 90;
	}
	
	if ( randomint( 100 ) >= chance * self getSideQuestFactor() )
	{
		return;
	}
	
	self BotNotifyBotEvent( "avenge", "go", killer, victimName );
	
	// only where it happened, not where the killer is now
	self SetScriptGoal( pos, 200 );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "avenge", "stop", killer, victimName );
}

/*
	Announces a teammate avenged if the bot just killed their killer.
*/
checkAvenged( victim )
{
	if ( !isdefined( self.bot_real_avenge ) || !isdefined( victim ) || !isplayer( victim ) )
	{
		return;
	}
	
	if ( victim.name != self.bot_real_avenge.killer || timeSince( self.bot_real_avenge.time, 30000 ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "avenge", "done", victim, self.bot_real_avenge.victim );
	self.bot_real_avenge = undefined;
}

/*
	Voice callouts
*/

/*
	Plays a voice callout to the team, at most one per bot every 10 seconds and one per team every 3.
*/
botVoice( alias, text )
{
	self endon( "disconnect" );
	
	if ( !getdvarint( "bots_real_voice" ) || !level.teambased || !isdefined( self.team ) || !isreallyalive( self ) )
	{
		return;
	}
	
	// the random quick messages from the original chat use the same flag
	if ( isdefined( self.talking ) && self.talking )
	{
		return;
	}
	
	if ( !timeSince( self.bot_real_voice_time, 10000 ) )
	{
		return;
	}
	
	if ( !isdefined( level.bots_real_voice_time ) )
	{
		level.bots_real_voice_time = [];
	}
	
	if ( !timeSince( level.bots_real_voice_time[ self.team ], 3000 ) )
	{
		return;
	}
	
	self.bot_real_voice_time = gettime();
	level.bots_real_voice_time[ self.team ] = gettime();
	
	self.talking = true;
	self maps\mp\gametypes\_quickmessages::saveheadicon();
	self maps\mp\gametypes\_quickmessages::doquickmessage( alias, text );
	wait 2;
	self maps\mp\gametypes\_quickmessages::restoreheadicon();
	self.talking = false;
}

/*
	Turns the bot's own events into matching voice callouts.
*/
bot_voice_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		self waittill( "bot_event", msg, a, b );
		
		if ( !isdefined( a ) || !isstring( a ) )
		{
			continue;
		}
		
		roll = randomint( 100 );
		
		switch ( msg )
		{
			case "retreat":
				if ( a == "start" && roll < 40 )
				{
					self thread botVoice( "mp_stm_needreinforcements", "Need reinforcements!" );
				}
				
				break;
				
			case "airhide":
				if ( a == "start" && roll < 30 )
				{
					self thread botVoice( "mp_cmd_fallback", "Fall back!" );
				}
				
				break;
				
			case "dom":
			case "hq":
			case "sab":
			case "sd":
			case "cap":
			case "dem":
			case "gtnw":
			case "oneflag":
			case "arena":
			case "vip":
			case "conf":
			case "grnd":
			case "tdef":
				if ( a == "go" && roll < 25 )
				{
					self thread botVoice( "mp_cmd_followme", "Follow me!" );
				}
				
				break;
		}
	}
}

/*
	Long fights with an LMG get a "Suppressing fire!".
*/
bot_suppress_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		wait 1;
		
		if ( !getdvarint( "bots_real_voice" ) || !isdefined( self.bot.target ) || !isdefined( self.bot.target.entity ) || !isplayer( self.bot.target.entity ) )
		{
			continue;
		}
		
		if ( self.bot.target.trace_time < 2000 || weaponclass( self getcurrentweapon() ) != "mg" || randomint( 100 ) >= 15 )
		{
			continue;
		}
		
		self thread botVoice( "mp_cmd_suppressfire", "Suppressing fire!" );
	}
}

/*
	Adaptive difficulty
*/

/*
	The skill the bot plays at: its base skill, moved by adaptive difficulty when that's on.
*/
getEffectiveSkill()
{
	base = self.pers[ "bots" ][ "skill" ][ "base" ];
	
	if ( !getdvarint( "bots_real_adaptive" ) || !isdefined( game[ "bots_real_skill_offset" ] ) )
	{
		return base;
	}
	
	key = "ffa";
	
	if ( level.teambased && isdefined( self.team ) )
	{
		key = self.team;
	}
	
	offset = game[ "bots_real_skill_offset" ][ key ];
	
	if ( !isdefined( offset ) )
	{
		return base;
	}
	
	return int( clamp( base + offset, getdvarint( "bots_skill_min" ), getdvarint( "bots_skill_max" ) ) );
}

/*
	Total kills and deaths of the human players (optionally only on one team).
*/
getHumanTotals( team )
{
	totals = spawnstruct();
	totals.kills = 0;
	totals.deaths = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( p is_bot() || !isdefined( p.pers[ "team" ] ) )
		{
			continue;
		}
		
		if ( isdefined( team ) && p.pers[ "team" ] != team )
		{
			continue;
		}
		
		if ( isdefined( p.pers[ "kills" ] ) )
		{
			totals.kills += p.pers[ "kills" ];
		}
		
		if ( isdefined( p.pers[ "deaths" ] ) )
		{
			totals.deaths += p.pers[ "deaths" ];
		}
	}
	
	return totals;
}

/*
	Moves the skill offset for one group of bots one step based on the humans' recent K/D.
*/
adjustSkillOffset( key, humanTeam, target )
{
	totals = getHumanTotals( humanTeam );
	last = level.bots_real_adapt_last[ key ];
	level.bots_real_adapt_last[ key ] = totals;
	
	if ( !isdefined( last ) )
	{
		return;
	}
	
	// only the last 30 seconds count, so it reacts to how things are going now
	kills = totals.kills - last.kills;
	deaths = totals.deaths - last.deaths;
	
	if ( kills < 0 || deaths < 0 || kills + deaths < 4 )
	{
		return;
	}
	
	kd = ( kills * 1.0 ) / max( deaths, 1 );
	offset = game[ "bots_real_skill_offset" ][ key ];
	
	if ( !isdefined( offset ) )
	{
		offset = 0;
	}
	
	if ( kd > target * 1.2 && offset < 3 )
	{
		offset++;
	}
	else if ( kd < target * 0.8 && offset > -3 )
	{
		offset--;
	}
	else
	{
		return;
	}
	
	game[ "bots_real_skill_offset" ][ key ] = offset;
	BotBuiltinPrintConsole( "Bot Warfare XTended: adaptive difficulty for " + key + " bots is now " + offset + " (humans went " + kills + "-" + deaths + ")" );
}

/*
	Every 30 seconds, nudges the bots humans are playing against towards the target K/D.
*/
adaptiveDifficultyThink()
{
	level endon( "game_ended" );
	
	// the offset is kept in game[] so S&D rounds carry it over, the snapshots start fresh each round
	if ( !isdefined( game[ "bots_real_skill_offset" ] ) )
	{
		game[ "bots_real_skill_offset" ] = [];
	}
	
	level.bots_real_adapt_last = [];
	
	for ( ;; )
	{
		wait 30;
		
		if ( !getdvarint( "bots_real_adaptive" ) )
		{
			level.bots_real_adapt_last = [];
			continue;
		}
		
		target = getdvarfloat( "bots_real_adaptive_kd" );
		
		if ( target <= 0 )
		{
			target = 1.2;
		}
		
		if ( level.teambased )
		{
			// each team's bots adapt to the humans on the other team
			adjustSkillOffset( "allies", "axis", target );
			adjustSkillOffset( "axis", "allies", target );
		}
		else
		{
			adjustSkillOffset( "ffa", undefined, target );
		}
	}
}

/*
	Mood
*/

/*
	cocky after 3 kills without dying, tilted after 3 deaths without a kill, otherwise normal
*/
BotGetMood()
{
	if ( !getdvarint( "bots_real_mood" ) || !isdefined( self.pers[ "bots" ][ "real_kills" ] ) )
	{
		return "normal";
	}
	
	if ( self.pers[ "bots" ][ "real_kills" ] >= getMoodStreak() )
	{
		return "cocky";
	}
	
	if ( self.pers[ "bots" ][ "real_deaths" ] >= getMoodStreak() && !self tiltExpired() )
	{
		return "tilted";
	}
	
	return "normal";
}

/*
	Time helper that survives round restarts resetting the clock: true if more than ms have passed since t,
	or if the clock went backwards.
*/
timeSince( t, ms )
{
	if ( !isdefined( t ) )
	{
		return true;
	}
	
	diff = gettime() - t;
	return ( diff < 0 || diff > ms );
}

/*
	Tilt lasts two minutes at most, otherwise a passive tilted bot never gets the kill to snap out of it.
*/
tiltExpired()
{
	if ( !isdefined( self.pers[ "bots" ][ "real_tilt_time" ] ) )
	{
		return false;
	}
	
	return timeSince( self.pers[ "bots" ][ "real_tilt_time" ], 120000 );
}

/*
	Makes sure the kill and death counters exist.
*/
initMoodCounters()
{
	if ( !isdefined( self.pers[ "bots" ][ "real_kills" ] ) )
	{
		self.pers[ "bots" ][ "real_kills" ] = 0;
		self.pers[ "bots" ][ "real_deaths" ] = 0;
	}
}

/*
	The bot got a kill.
*/
onBotGotKill( victim )
{
	self initMoodCounters();
	
	before = self BotGetMood();
	self.pers[ "bots" ][ "real_kills" ]++;
	self.pers[ "bots" ][ "real_deaths" ] = 0;
	self moodChanged( before );
	
	self checkGrudgeRevenge( victim );
	self checkAvenged( victim );
	self maybeSlipReload();
}

/*
	The bot died.
*/
onBotDied()
{
	self initMoodCounters();
	
	// an expired tilt starts counting from scratch
	if ( self.pers[ "bots" ][ "real_deaths" ] >= getMoodStreak() && self tiltExpired() )
	{
		self.pers[ "bots" ][ "real_deaths" ] = 0;
		self.pers[ "bots" ][ "real_tilt_time" ] = undefined;
	}
	
	before = self BotGetMood();
	self.pers[ "bots" ][ "real_deaths" ]++;
	self.pers[ "bots" ][ "real_kills" ] = 0;
	self moodChanged( before );
}

/*
	Announces a mood change and applies it right away.
*/
moodChanged( before )
{
	after = self BotGetMood();
	
	if ( after == before )
	{
		return;
	}
	
	if ( after == "tilted" )
	{
		self.pers[ "bots" ][ "real_tilt_time" ] = gettime();
	}
	
	self BotNotifyBotEvent( "mood", after, before );
}

/*
	Mood scales the behavior on top of difficulty and personality.
*/
applyMoodBehavior()
{
	switch ( self BotGetMood() )
	{
		case "cocky":
			self scaleBehavior( "sprint", 1.3 );
			self scaleBehavior( "strafe", 1.2 );
			self scaleBehavior( "camp", 0.5 );
			self scaleBehavior( "jump", 1.3 );
			break;
			
		case "tilted":
			self scaleBehavior( "camp", 2 );
			self scaleBehavior( "sprint", 0.7 );
			self scaleBehavior( "crouch", 1.5 );
			self scaleBehavior( "follow", 1.5 );
			break;
	}
}

/*
	Grudges
*/

/*
	Name of the player this bot holds a grudge against, if any.
*/
getGrudgeName()
{
	if ( !getdvarint( "bots_real_grudge" ) || !isdefined( self.pers[ "bots" ] ) )
	{
		return undefined;
	}
	
	return self.pers[ "bots" ][ "real_grudge" ];
}

/*
	Counts deaths per killer, the third death to the same player starts a grudge.
*/
noteGrudgeDeath( killer )
{
	if ( !isdefined( self.pers[ "bots" ][ "real_killers" ] ) )
	{
		self.pers[ "bots" ][ "real_killers" ] = [];
	}
	
	name = killer.name;
	
	if ( !isdefined( self.pers[ "bots" ][ "real_killers" ][ name ] ) )
	{
		self.pers[ "bots" ][ "real_killers" ][ name ] = 0;
	}
	
	self.pers[ "bots" ][ "real_killers" ][ name ]++;
	count = self.pers[ "bots" ][ "real_killers" ][ name ];
	
	// remember where they got us from, that's where we'll go looking
	if ( !isdefined( self.pers[ "bots" ][ "real_grudge_pos" ] ) )
	{
		self.pers[ "bots" ][ "real_grudge_pos" ] = [];
	}
	
	self.pers[ "bots" ][ "real_grudge_pos" ][ name ] = killer.origin;
	
	if ( !getdvarint( "bots_real_grudge" ) )
	{
		return;
	}
	
	if ( count < 3 )
	{
		return;
	}
	
	current = self.pers[ "bots" ][ "real_grudge" ];
	
	if ( isdefined( current ) && current == name )
	{
		return;
	}
	
	// only switch grudges if this killer has been worse than the current one
	if ( isdefined( current ) && isdefined( self.pers[ "bots" ][ "real_killers" ][ current ] ) && self.pers[ "bots" ][ "real_killers" ][ current ] >= count )
	{
		return;
	}
	
	self.pers[ "bots" ][ "real_grudge" ] = name;
	self BotNotifyBotEvent( "grudge", "start", killer );
}

/*
	Makes the other player this bot's nemesis right away (after a flame war).
*/
setGrudgeAgainst( other )
{
	if ( !getdvarint( "bots_real_grudge" ) || !isdefined( other ) || !isdefined( self.pers[ "bots" ] ) )
	{
		return;
	}
	
	if ( !isdefined( self.pers[ "bots" ][ "real_grudge_pos" ] ) )
	{
		self.pers[ "bots" ][ "real_grudge_pos" ] = [];
	}
	
	self.pers[ "bots" ][ "real_grudge" ] = other.name;
	self.pers[ "bots" ][ "real_grudge_pos" ][ other.name ] = other.origin;
}

/*
	Settles the grudge when the bot kills its nemesis.
*/
checkGrudgeRevenge( victim )
{
	grudge = self getGrudgeName();
	
	if ( !isdefined( grudge ) || !isdefined( victim ) || !isplayer( victim ) || victim.name != grudge )
	{
		return;
	}
	
	self.pers[ "bots" ][ "real_grudge" ] = undefined;
	self.pers[ "bots" ][ "real_killers" ][ grudge ] = 0;
	self BotNotifyBotEvent( "grudge", "stop", victim );
}

/*
	Returns the living enemy player the bot holds a grudge against, if they're in the game.
*/
getGrudgeTarget()
{
	grudge = self getGrudgeName();
	
	if ( !isdefined( grudge ) )
	{
		return undefined;
	}
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( player.name != grudge )
		{
			continue;
		}
		
		if ( !isreallyalive( player ) || ( level.teambased && player.team == self.team ) )
		{
			return undefined;
		}
		
		return player;
	}
	
	return undefined;
}

/*
	Every so often the bot goes looking for its nemesis.
*/
bot_grudge_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		wait randomintrange( 4, 8 );
		
		if ( !getdvarint( "bots_real_grudge" ) )
		{
			continue;
		}
		
		if ( self hasThreat() || self HasScriptGoal() || self.bot_lock_goal || self isusingremote() || self BotIsFrozen() )
		{
			continue;
		}
		
		target = self getGrudgeTarget();
		
		if ( !isdefined( target ) )
		{
			continue;
		}
		
		// bots don't know where the nemesis is right now, only where they got killed by them
		huntPos = undefined;
		
		if ( isdefined( self.pers[ "bots" ][ "real_grudge_pos" ] ) )
		{
			huntPos = self.pers[ "bots" ][ "real_grudge_pos" ][ target.name ];
		}
		
		if ( !isdefined( huntPos ) || distancesquared( self.origin, huntPos ) < 300 * 300 )
		{
			continue;
		}
		
		chance = 40;
		
		switch ( self BotGetTrait() )
		{
			case "rusher":
				chance = 60;
				break;
				
			case "cautious":
				chance = 20;
				break;
				
			case "support":
				chance = 25;
				break;
		}
		
		if ( randomint( 100 ) >= chance * self getSideQuestFactor() )
		{
			continue;
		}
		
		self BotNotifyBotEvent( "grudge", "hunt", target );
		
		self SetScriptGoal( huntPos, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self BotNotifyBotEvent( "grudge", "stop_hunt", target );
	}
}

/*
	Counter-picking
*/

/*
	Works out what killed the bot, for counter-picking. Returns undefined if nothing to counter.
*/
getDeathCategory( eAttacker, sWeapon, sMeansOfDeath )
{
	if ( isdefined( sWeapon ) && iskillstreakweapon( sWeapon ) )
	{
		ground = strtok( "sentry,ims,remote_turret,manned,remote_tank,ugv,nuke,juggernaut,trap", "," );
		
		for ( i = 0; i < ground.size; i++ )
		{
			if ( issubstr( sWeapon, ground[ i ] ) )
			{
				return undefined;
			}
		}
		
		if ( self _hasperk( "specialty_blindeye" ) )
		{
			return undefined;
		}
		
		return "air";
	}
	
	if ( sMeansOfDeath == "MOD_GRENADE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_EXPLOSIVE" )
	{
		if ( self _hasperk( "specialty_detectexplosive" ) )
		{
			return undefined;
		}
		
		return "explosive";
	}
	
	if ( isdefined( sWeapon ) )
	{
		weapClass = getweaponclass( sWeapon );
		
		if ( weapClass == "weapon_sniper" )
		{
			return "sniper";
		}
		
		if ( ( weapClass == "weapon_shotgun" || weapClass == "weapon_smg" || sMeansOfDeath == "MOD_MELEE" ) && distancesquared( eAttacker.origin, self.origin ) < 500 * 500 )
		{
			return "close";
		}
	}
	
	// nothing more specific, but their uav was giving us away
	if ( level.teambased && isdefined( level.activeuavs ) && isdefined( level.otherteam[ self.team ] ) && level.activeuavs[ level.otherteam[ self.team ] ] && !self _hasperk( "specialty_coldblooded" ) )
	{
		return "radar";
	}
	
	return undefined;
}

/*
	Counts what kills the bot and counter-picks once something keeps doing it.
*/
noteCounterDeath( eAttacker, sWeapon, sMeansOfDeath )
{
	if ( !getdvarint( "bots_real_counter" ) )
	{
		return;
	}
	
	category = self getDeathCategory( eAttacker, sWeapon, sMeansOfDeath );
	
	if ( !isdefined( category ) )
	{
		return;
	}
	
	if ( !isdefined( self.pers[ "bots" ][ "real_tally" ] ) )
	{
		self.pers[ "bots" ][ "real_tally" ] = [];
	}
	
	if ( !isdefined( self.pers[ "bots" ][ "real_tally" ][ category ] ) )
	{
		self.pers[ "bots" ][ "real_tally" ][ category ] = 0;
	}
	
	self.pers[ "bots" ][ "real_tally" ][ category ]++;
	
	needed = 3;
	
	if ( category == "air" )
	{
		needed = 2;
	}
	
	if ( self.pers[ "bots" ][ "real_tally" ][ category ] < needed )
	{
		return;
	}
	
	if ( !timeSince( self.pers[ "bots" ][ "real_counter_time" ], 60000 ) )
	{
		return;
	}
	
	if ( self applyCounter( category ) )
	{
		self.pers[ "bots" ][ "real_tally" ][ category ] = 0;
		self.pers[ "bots" ][ "real_counter_time" ] = gettime();
	}
}

/*
	The bot's rank, for unlock checks.
*/
getBotRank()
{
	return self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) );
}

/*
	True if the item is unlocked for this bot.
*/
canUseItem( item )
{
	if ( !self isitemunlocked( item ) )
	{
		return false;
	}
	
	return self getBotRank() >= maps\mp\bots\_bot_script::getUnlockLevel( item );
}

/*
	Finds a usable perk in the given tier whose name contains the text.
*/
findPerk( tier, text )
{
	perks = maps\mp\bots\_bot_script::getPerks( tier );
	
	for ( i = 0; i < perks.size; i++ )
	{
		if ( issubstr( perks[ i ], text ) && self canUseItem( perks[ i ] ) )
		{
			return perks[ i ];
		}
	}
	
	return undefined;
}

/*
	Finds a usable offhand (valid tactical when isTactical, else valid equipment) whose name contains the text.
*/
findOffhand( text, isTactical )
{
	items = maps\mp\bots\_bot_script::getPerks( "equipment" );
	
	for ( i = 0; i < items.size; i++ )
	{
		item = items[ i ];
		
		if ( !issubstr( item, text ) || !self canUseItem( item ) )
		{
			continue;
		}
		
		if ( isTactical && !maps\mp\gametypes\_class::isvalidoffhand( item ) )
		{
			continue;
		}
		
		if ( !isTactical && !maps\mp\gametypes\_class::isvalidequipment( item ) )
		{
			continue;
		}
		
		return item;
	}
	
	return undefined;
}

/*
	Random usable primary of the weapon class.
*/
findPrimaryOfClass( weapClass )
{
	primaries = maps\mp\bots\_bot_script::getPrimaries();
	options = [];
	
	for ( i = 0; i < primaries.size; i++ )
	{
		if ( getweaponclass( primaries[ i ] ) == weapClass && self canUseItem( primaries[ i ] ) )
		{
			options[ options.size ] = primaries[ i ];
		}
	}
	
	return random( options );
}

/*
	First usable secondary from the comma separated list.
*/
findSecondary( list )
{
	names = strtok( list, "," );
	secondaries = maps\mp\bots\_bot_script::getSecondaries();
	
	for ( i = 0; i < names.size; i++ )
	{
		for ( h = 0; h < secondaries.size; h++ )
		{
			if ( secondaries[ h ] == names[ i ] && self canUseItem( names[ i ] ) )
			{
				return names[ i ];
			}
		}
	}
	
	return undefined;
}

/*
	Writes a weapon into a class slot, clearing attachments and cosmetics that may not fit it.
*/
setClassWeapon( whereToSave, slot, index, weapon )
{
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "weapon", weapon );
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "attachment", 0, "none" );
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "attachment", 1, "none" );
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "camo", "none" );
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "reticle", "none" );
	self setplayerdata( whereToSave, slot, "weaponSetups", index, "buff", "specialty_null" );
}

/*
	Changes the tier 2 perk. If that removes Overkill, swaps the second primary for a pistol.
*/
setClassPerk2( whereToSave, slot, perk )
{
	if ( self getplayerdata( whereToSave, slot, "perks", 2 ) == "specialty_twoprimaries" )
	{
		pistol = self findPrimaryOrSecondaryPistol();
		
		if ( !isdefined( pistol ) )
		{
			return false;
		}
		
		self setClassWeapon( whereToSave, slot, 1, pistol );
	}
	
	self setplayerdata( whereToSave, slot, "perks", 2, perk );
	return true;
}

/*
	A usable pistol for the secondary slot.
*/
findPrimaryOrSecondaryPistol()
{
	secondaries = maps\mp\bots\_bot_script::getSecondaries();
	
	for ( i = 0; i < secondaries.size; i++ )
	{
		if ( getweaponclass( secondaries[ i ] ) == "weapon_pistol" && self canUseItem( secondaries[ i ] ) )
		{
			return secondaries[ i ];
		}
	}
	
	return undefined;
}

/*
	Rewrites one of the bot's custom classes to counter the category and switches to it on the next spawn.
	Returns true if anything was changed.
*/
applyCounter( category )
{
	if ( !allowclasschoice() || ( isusingmatchrulesdata() && !level.matchrules_allowcustomclasses ) )
	{
		return false;
	}
	
	// low ranks can't use custom classes
	if ( self getBotRank() + 1 < 4 )
	{
		return false;
	}
	
	whereToSave = "customClasses";
	
	if ( getdvarint( "xblive_privatematch" ) )
	{
		whereToSave = "privateMatchCustomClasses";
	}
	
	slot = randomint( 5 );
	
	if ( isdefined( self.class ) && issubstr( self.class, "custom" ) )
	{
		slot = int( getsubstr( self.class, 6, self.class.size ) ) - 1;
	}
	
	if ( slot < 0 || slot > 4 )
	{
		slot = randomint( 5 );
	}
	
	trait = self BotGetTrait();
	changed = false;
	
	switch ( category )
	{
		case "air":
			perk = self findPerk( "perk1", "blindeye" );
			
			if ( isdefined( perk ) )
			{
				self setplayerdata( whereToSave, slot, "perks", 1, perk );
				changed = true;
			}
			
			launcher = self findSecondary( "stinger,iw5_smaw" );
			
			if ( isdefined( launcher ) && self getplayerdata( whereToSave, slot, "perks", 2 ) != "specialty_twoprimaries" )
			{
				self setClassWeapon( whereToSave, slot, 1, launcher );
				changed = true;
			}
			
			break;
			
		case "explosive":
			perk = self findPerk( "perk3", "detectexplosive" );
			
			if ( isdefined( perk ) )
			{
				self setplayerdata( whereToSave, slot, "perks", 3, perk );
				changed = true;
			}
			
			perk = self findPerk( "perk2", "blastshield" );
			
			if ( isdefined( perk ) && self setClassPerk2( whereToSave, slot, perk ) )
			{
				changed = true;
			}
			
			break;
			
		case "radar":
			perk = self findPerk( "perk2", "coldblooded" );
			
			if ( isdefined( perk ) && self setClassPerk2( whereToSave, slot, perk ) )
			{
				changed = true;
			}
			
			break;
			
		case "sniper":
			weapClass = "weapon_smg";
			
			if ( trait == "cautious" )
			{
				weapClass = "weapon_sniper";
			}
			
			weapon = self findPrimaryOfClass( weapClass );
			
			if ( isdefined( weapon ) )
			{
				self setClassWeapon( whereToSave, slot, 0, weapon );
				changed = true;
			}
			
			smoke = self findOffhand( "smoke", true );
			
			if ( isdefined( smoke ) )
			{
				self setplayerdata( whereToSave, slot, "perks", 6, smoke );
				changed = true;
			}
			
			break;
			
		case "close":
			if ( trait == "cautious" )
			{
				claymore = self findOffhand( "claymore", false );
				
				if ( isdefined( claymore ) )
				{
					self setplayerdata( whereToSave, slot, "perks", 0, claymore );
					changed = true;
				}
				
				break;
			}
			
			weapClass = "weapon_smg";
			
			if ( randomint( 2 ) )
			{
				weapClass = "weapon_shotgun";
			}
			
			weapon = self findPrimaryOfClass( weapClass );
			
			if ( isdefined( weapon ) )
			{
				self setClassWeapon( whereToSave, slot, 0, weapon );
				changed = true;
			}
			
			break;
	}
	
	if ( !changed )
	{
		return false;
	}
	
	// classWatch picks the new class on the next spawn
	self.bot_real_counter_class = "custom" + ( slot + 1 );
	self.bot_change_class = undefined;
	
	self BotNotifyBotEvent( "counter", "pick", category );
	return true;
}

/*
	Returns the counter class once if one is waiting, used by chooseRandomClass.
*/
takeCounterClass()
{
	class = self.bot_real_counter_class;
	self.bot_real_counter_class = undefined;
	return class;
}

/*
	Taking cover from air killstreaks
*/

/*
	True if an enemy air killstreak (not a UAV) is up.
*/
enemyAirIsUp()
{
	targets = getAirTargets();
	
	for ( i = 0; i < targets.size; i++ )
	{
		t = targets[ i ];
		
		if ( !isdefined( t ) || isplayer( t ) )
		{
			continue;
		}
		
		if ( isdefined( t.model ) && issubstr( t.model, "uav" ) )
		{
			continue;
		}
		
		if ( isdefined( t.owner ) && t.owner == self )
		{
			continue;
		}
		
		if ( level.teambased && isdefined( t.team ) && t.team == self.team )
		{
			continue;
		}
		
		return true;
	}
	
	return false;
}

/*
	The game's list of air targets, shared by every bot and refreshed at most twice a second.
*/
getAirTargets()
{
	if ( !isdefined( level.bots_real_air_list ) || timeSince( level.bots_real_air_time, 500 ) )
	{
		level.bots_real_air_list = maps\mp\_stinger::gettargetlist();
		level.bots_real_air_time = gettime();
	}
	
	return level.bots_real_air_list;
}

/*
	True if there's something solid overhead.
*/
hasRoofAt( origin )
{
	return !bullettracepassed( origin + ( 0, 0, 50 ), origin + ( 0, 0, 1000 ), false, undefined );
}

/*
	Nearest waypoint with a roof over it.
*/
findRoofWaypoint()
{
	candidates = NewHeap( ::closerFirst );
	
	for ( i = level.waypoints.size - 1; i >= 0; i-- )
	{
		dist = distancesquared( level.waypoints[ i ].origin, self.origin );
		
		if ( dist <= 1200 * 1200 )
		{
			candidates HeapInsert( makeCandidate( level.waypoints[ i ].origin, dist ) );
		}
	}
	
	for ( traces = 0; traces < 20 && candidates.data.size; traces++ )
	{
		c = candidates.data[ 0 ];
		candidates HeapRemove();
		
		if ( self hasRoofAt( c.origin ) )
		{
			return c.origin;
		}
	}
	
	return undefined;
}

/*
	Bots under the sky with enemy air up move somewhere covered, unless they can shoot it down.
*/
bot_airhide_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		wait 1;
		
		if ( !getdvarint( "bots_real_airhide" ) )
		{
			continue;
		}
		
		if ( self hasThreat() || self HasScriptGoal() || self.bot_lock_goal || self isusingremote() || self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() || self inLastStand() )
		{
			continue;
		}
		
		// bots with a launcher go hunt it instead
		if ( isdefined( self maps\mp\bots\_bot_script::getLockonAmmo() ) )
		{
			continue;
		}
		
		if ( !self enemyAirIsUp() || self hasRoofAt( self.origin ) )
		{
			continue;
		}
		
		chance = 90;
		
		if ( self BotGetTrait() == "rusher" || self BotGetMood() == "cocky" )
		{
			chance = 50;
		}
		
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 2 )
		{
			chance = 40;
		}
		
		if ( randomint( 100 ) >= chance )
		{
			// decided to risk it, don't think about it again for a bit
			wait 10;
			continue;
		}
		
		cover = self findRoofWaypoint();
		
		if ( !isdefined( cover ) )
		{
			wait 5;
			continue;
		}
		
		self BotNotifyBotEvent( "airhide", "start", cover );
		
		// no bot_lock_goal, so objective scripts can still call the bot away
		self SetScriptGoal( cover, 64 );
		
		ret = self waittill_any_timeout( 15, "goal", "bad_path", "new_goal" );
		
		if ( ret == "goal" )
		{
			// wait it out under cover, but not forever, and not if someone gave the bot a new goal
			for ( i = 0; i < 20 && self enemyAirIsUp() && getdvarint( "bots_real_airhide" ); i++ )
			{
				wait 1;
				
				if ( !self HasScriptGoal() || self GetScriptGoal() != cover || self.bot_lock_goal )
				{
					break;
				}
			}
		}
		
		// only clear the goal if it's still ours
		if ( ret != "new_goal" && self HasScriptGoal() && self GetScriptGoal() == cover )
		{
			self ClearScriptGoal();
		}
		
		self BotNotifyBotEvent( "airhide", "stop", cover );
	}
}

/*
	Hot spots: where players keep getting kills from
*/

/*
	Records where the killer stood. Three kills from about the same place makes it a hot spot.
	Called on the victim.
*/
recordHotspotKill( killer, sWeapon )
{
	if ( !getdvarint( "bots_real_hotspots" ) || !isdefined( level.bots_hotspots ) )
	{
		return;
	}
	
	// killstreak kills don't say anything about where the player is
	if ( isdefined( sWeapon ) && iskillstreakweapon( sWeapon ) )
	{
		return;
	}
	
	// neither do team kills
	if ( level.teambased && isdefined( killer.team ) && isdefined( self.team ) && killer.team == self.team )
	{
		return;
	}
	
	theTime = gettime();
	team = "ffa";
	
	if ( level.teambased && isdefined( killer.team ) )
	{
		team = killer.team;
	}
	
	changed = pruneHotspots( theTime );
	spot = undefined;
	
	for ( i = 0; i < level.bots_hotspots.size; i++ )
	{
		s = level.bots_hotspots[ i ];
		
		if ( s.team == team && distancesquared( s.origin, killer.origin ) < 200 * 200 )
		{
			spot = s;
			break;
		}
	}
	
	if ( isdefined( spot ) )
	{
		spot.kills++;
		spot.time = theTime;
		spot.name = killer.name;
		spot.origin = spot.origin * 0.7 + killer.origin * 0.3;
	}
	else
	{
		if ( !isdefined( level.bots_hotspot_nextid ) )
		{
			level.bots_hotspot_nextid = 0;
		}
		
		spot = spawnstruct();
		spot.id = level.bots_hotspot_nextid + "";
		level.bots_hotspot_nextid++;
		spot.origin = killer.origin;
		spot.team = team;
		spot.name = killer.name;
		spot.kills = 1;
		spot.time = theTime;
		
		level.bots_hotspots[ level.bots_hotspots.size ] = spot;
		
		// keep the list small, drop the stalest spot
		if ( level.bots_hotspots.size > 32 )
		{
			oldest = 0;
			
			for ( i = 1; i < level.bots_hotspots.size; i++ )
			{
				if ( level.bots_hotspots[ i ].time < level.bots_hotspots[ oldest ].time )
				{
					oldest = i;
				}
			}
			
			if ( level.bots_hotspots[ oldest ].kills >= 3 )
			{
				changed = true;
			}
			
			level.bots_hotspots = array_remove( level.bots_hotspots, level.bots_hotspots[ oldest ] );
		}
	}
	
	if ( spot.kills == 3 )
	{
		changed = true;
		
		if ( self is_bot() )
		{
			self BotNotifyBotEvent( "hotspot", "new", spot );
		}
	}
	
	if ( changed )
	{
		rebuildHotspotWaypoints();
	}
}

/*
	Forgets spots nobody has killed from in 3 minutes. Returns true if a hot spot went away.
*/
pruneHotspots( theTime )
{
	kept = [];
	changed = false;
	
	for ( i = 0; i < level.bots_hotspots.size; i++ )
	{
		s = level.bots_hotspots[ i ];
		
		if ( theTime - s.time > 180000 )
		{
			if ( s.kills >= 3 )
			{
				changed = true;
			}
			
			continue;
		}
		
		kept[ kept.size ] = s;
	}
	
	level.bots_hotspots = kept;
	return changed;
}

/*
	Marks the waypoints near hot spots so pathfinding can steer around them.
	Keyed by the team that should avoid them ("ffa" in free for all).
*/
rebuildHotspotWaypoints()
{
	level.bots_hotspot_wps = [];
	
	for ( i = 0; i < level.bots_hotspots.size; i++ )
	{
		s = level.bots_hotspots[ i ];
		
		if ( s.kills < 3 )
		{
			continue;
		}
		
		key = "ffa";
		
		if ( s.team != "ffa" && isdefined( level.otherteam[ s.team ] ) )
		{
			key = level.otherteam[ s.team ];
		}
		
		if ( !isdefined( level.bots_hotspot_wps[ key ] ) )
		{
			level.bots_hotspot_wps[ key ] = [];
		}
		
		for ( h = 0; h < level.waypoints.size; h++ )
		{
			if ( distancesquared( level.waypoints[ h ].origin, s.origin ) < 300 * 300 )
			{
				level.bots_hotspot_wps[ key ][ h + "" ] = true;
			}
		}
	}
}

/*
	True if the spot is a hot spot used by this bot's enemies.
*/
isHotspotDangerFor( spot )
{
	if ( spot.kills < 3 )
	{
		return false;
	}
	
	if ( level.teambased )
	{
		return spot.team != self.team;
	}
	
	return spot.name != self.name;
}

/*
	Which hot spot set pathfinding should avoid for this bot, undefined to not avoid any.
	Rushers and cocky bots run straight through.
*/
getAvoidKey()
{
	if ( !getdvarint( "bots_real_hotspots" ) )
	{
		return undefined;
	}
	
	if ( self BotGetTrait() == "rusher" || self BotGetMood() == "cocky" )
	{
		return undefined;
	}
	
	if ( level.teambased )
	{
		return self.team;
	}
	
	return "ffa";
}

/*
	Nearest enemy hot spot the bot can see, between 200 and 1500 units away.
*/
getVisibleHotspot()
{
	best = undefined;
	bestDist = 1500 * 1500;
	
	for ( i = 0; i < level.bots_hotspots.size; i++ )
	{
		s = level.bots_hotspots[ i ];
		
		if ( !self isHotspotDangerFor( s ) )
		{
			continue;
		}
		
		dist = distancesquared( self.origin, s.origin );
		
		if ( dist < 200 * 200 || dist > bestDist )
		{
			continue;
		}
		
		best = s;
		bestDist = dist;
	}
	
	if ( !isdefined( best ) || !bullettracepassed( self geteye(), best.origin + ( 0, 0, 50 ), false, self ) )
	{
		return undefined;
	}
	
	return best;
}

/*
	True if a living teammate is within radius of the origin (never in free for all).
*/
teammateNear( origin, radius )
{
	if ( !level.teambased )
	{
		return false;
	}
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( p == self || !isdefined( p.team ) || p.team != self.team || !isreallyalive( p ) )
		{
			continue;
		}
		
		if ( distancesquared( p.origin, origin ) < radius * radius )
		{
			return true;
		}
	}
	
	return false;
}

/*
	Throws a grenade at a hot spot.
*/
preNadeHotspot( spot, nade )
{
	self BotNotifyBotEvent( "hotspot", "nade", spot );
	
	loc = spot.origin + ( 0, 0, 40 );
	dist = distancesquared( self.origin, loc );
	loc += ( 0, 0, dist / 3000 );
	
	self SetScriptAimPos( loc );
	self BotStopMoving( true );
	wait 1;
	
	time = 0.5;
	
	if ( nade == "frag_grenade_mp" )
	{
		time = 2;
	}
	
	self maps\mp\bots\_bot_script::botThrowGrenade( nade, time );
	
	self ClearScriptAimPos();
	self BotStopMoving( false );
}

/*
	Bots check, pre-aim and pre-nade spots players keep killing from.
*/
bot_hotspot_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	checked = [];
	lastNade = 0;
	
	for ( ;; )
	{
		wait 1;
		
		if ( !getdvarint( "bots_real_hotspots" ) || !level.bots_hotspots.size )
		{
			continue;
		}
		
		if ( self hasThreat() || self BotIsFrozen() || self isusingremote() || self inLastStand() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() || self HasScriptAimPos() )
		{
			continue;
		}
		
		spot = self getVisibleHotspot();
		
		if ( !isdefined( spot ) )
		{
			continue;
		}
		
		theTime = gettime();
		
		if ( isdefined( checked[ spot.id ] ) && theTime - checked[ spot.id ] < 8000 )
		{
			continue;
		}
		
		checked[ spot.id ] = theTime;
		
		nadeChance = 30;
		
		switch ( self BotGetTrait() )
		{
			case "cautious":
				nadeChance = 60;
				break;
				
			case "rusher":
				nadeChance = 10;
				break;
		}
		
		if ( self BotGetMood() == "tilted" )
		{
			nadeChance += 20;
		}
		
		dist = distancesquared( self.origin, spot.origin );
		nade = self getValidGrenade();
		
		if ( isdefined( nade ) && theTime - lastNade > 20000 && !self.bot_lock_goal && getdvarint( "bots_play_nade" ) && dist > level.bots_mingrenadedistance && dist < level.bots_maxgrenadedistance && randomint( 100 ) < nadeChance && !self teammateNear( spot.origin, 250 ) )
		{
			lastNade = theTime;
			self preNadeHotspot( spot, nade );
			continue;
		}
		
		// otherwise just check the angle on the way past
		self BotNotifyBotEvent( "hotspot", "check", spot );
		self thread lookTowardSound( spot.origin );
	}
}

/*
	Team intel
*/

/*
	When the bot spots an enemy, nearby bot teammates hear about it.
*/
bot_intel_share_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	lastShare = 0;
	
	for ( ;; )
	{
		self waittill( "new_enemy" );
		
		if ( !getdvarint( "bots_real_teamintel" ) || !level.teambased )
		{
			continue;
		}
		
		threat = self getThreat();
		
		if ( !isdefined( threat ) || !isplayer( threat ) || gettime() - lastShare < 3000 )
		{
			continue;
		}
		
		lastShare = gettime();
		pos = threat.origin;
		told = 0;
		
		for ( i = 0; i < level.players.size; i++ )
		{
			mate = level.players[ i ];
			
			if ( mate == self || !isdefined( mate.team ) || mate.team != self.team || !mate is_bot() || !isdefined( mate.bot ) )
			{
				continue;
			}
			
			if ( !isreallyalive( mate ) || distancesquared( mate.origin, self.origin ) > 1500 * 1500 )
			{
				continue;
			}
			
			mate thread receiveIntel( threat, pos );
			told++;
		}
		
		if ( told && randomint( 100 ) < 25 )
		{
			self BotNotifyBotEvent( "intel", "spotted", threat );
		}
		
		if ( told && randomint( 100 ) < 35 )
		{
			self thread botVoice( "mp_stm_enemyspotted", "Enemy spotted!" );
		}
	}
}

/*
	A teammate called out an enemy: look that way, and maybe move up to help.
*/
receiveIntel( enemy, pos )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	// it takes a moment to hear and react to a callout
	wait randomfloatrange( 0.3, 0.9 );
	
	if ( self hasThreat() || self BotIsFrozen() || self isusingremote() || self isPlanting() || self isDefusing() )
	{
		return;
	}
	
	if ( !self HasScriptAimPos() )
	{
		self thread lookTowardSound( pos );
	}
	
	if ( self HasScriptGoal() || self.bot_lock_goal || distancesquared( self.origin, pos ) < 300 * 300 )
	{
		return;
	}
	
	chance = 35;
	
	switch ( self BotGetTrait() )
	{
		case "support":
			chance = 60;
			break;
			
		case "rusher":
			chance = 50;
			break;
			
		case "cautious":
			chance = 15;
			break;
	}
	
	if ( randomint( 100 ) >= chance * self getSideQuestFactor() )
	{
		return;
	}
	
	self BotNotifyBotEvent( "intel", "go", enemy );
	
	self SetScriptGoal( pos, 256 );
	
	if ( isdefined( enemy ) )
	{
		self thread maps\mp\bots\_bot_script::stop_go_target_on_death( enemy );
	}
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "intel", "stop", enemy );
}

/*
	Match awareness
*/

/*
	Game modes where the objective is what wins.
*/
isObjectiveMode()
{
	switch ( level.gametype )
	{
		case "dom":
		case "koth":
		case "sd":
		case "sab":
		case "ctf":
		case "dd":
		case "oneflag":
		case "gtnw":
		case "tdef":
		case "grnd":
		case "vip":
		case "arena":
			return true;
			
		default:
			return false;
	}
}

/*
	True if the bot is the last one alive on its team in S&D with enemies left.
*/
isClutch()
{
	if ( !level.teambased || !isreallyalive( self ) )
	{
		return false;
	}
	
	mates = 0;
	enemies = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( p == self || !isdefined( p.team ) || !isreallyalive( p ) )
		{
			continue;
		}
		
		if ( p.team == self.team )
		{
			mates++;
		}
		else if ( p.team == level.otherteam[ self.team ] )
		{
			enemies++;
		}
	}
	
	return ( mates == 0 && enemies > 0 );
}

/*
	How many enemies are alive.
*/
countEnemiesAlive()
{
	count = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( p == self || !isdefined( p.team ) || !isreallyalive( p ) )
		{
			continue;
		}
		
		if ( level.teambased && p.team == self.team )
		{
			continue;
		}
		
		count++;
	}
	
	return count;
}

/*
	"clutch" when last alive in S&D, "desperate" when behind in the last 2 minutes,
	"protective" when ahead in the last 2 minutes, otherwise "normal".
*/
getMatchState()
{
	if ( isdefined( self.bot_real_match_state ) && !timeSince( self.bot_real_match_time, 1000 ) )
	{
		return self.bot_real_match_state;
	}
	
	self.bot_real_match_state = self computeMatchState();
	self.bot_real_match_time = gettime();
	return self.bot_real_match_state;
}

/*
	Works out the match state, see getMatchState.
*/
computeMatchState()
{
	if ( !getdvarint( "bots_real_matchaware" ) || !isdefined( self.team ) )
	{
		return "normal";
	}
	
	if ( level.gametype == "sd" )
	{
		if ( self isClutch() )
		{
			return "clutch";
		}
		
		return "normal";
	}
	
	if ( gettimelimit() <= 0 || maps\mp\gametypes\_gamelogic::gettimeremaining() > 120000 )
	{
		return "normal";
	}
	
	if ( level.teambased )
	{
		if ( !isdefined( game[ "teamScores" ] ) || !isdefined( level.otherteam[ self.team ] ) )
		{
			return "normal";
		}
		
		if ( game[ "teamScores" ][ self.team ] > game[ "teamScores" ][ level.otherteam[ self.team ] ] )
		{
			return "protective";
		}
		
		return "desperate";
	}
	
	best = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( p != self && isdefined( p.score ) && p.score > best )
		{
			best = p.score;
		}
	}
	
	if ( isdefined( self.score ) && self.score > best )
	{
		return "protective";
	}
	
	return "desperate";
}

/*
	How much side activities (chasing noises, answering callouts, grudge hunting) should happen.
	1 normally, less in objective modes, even less late in the match, none when last alive.
*/
getSideQuestFactor()
{
	if ( self getMatchState() == "clutch" )
	{
		return 0;
	}
	
	if ( !self isObjectiveMode() || !getdvarint( "bots_play_obj" ) )
	{
		return 1;
	}
	
	if ( self isFocusingObjective() )
	{
		return 0.3;
	}
	
	return 0.6;
}

/*
	True late in objective modes, when the objective matters more than kills.
*/
isFocusingObjective()
{
	if ( !self isObjectiveMode() )
	{
		return false;
	}
	
	state = self getMatchState();
	return ( state == "desperate" || state == "protective" );
}

/*
	Match state scales the behavior on top of difficulty, personality and mood.
*/
applyMatchBehavior()
{
	switch ( self getMatchState() )
	{
		case "desperate":
			self scaleBehavior( "sprint", 1.3 );
			self scaleBehavior( "camp", 0.3 );
			self scaleBehavior( "follow", 0.7 );
			break;
			
		case "protective":
			self scaleBehavior( "camp", 1.5 );
			self scaleBehavior( "sprint", 0.85 );
			break;
			
		case "clutch":
			// careful, but still moving: the objective scripts drive where they go
			self scaleBehavior( "camp", 0.3 );
			self scaleBehavior( "sprint", 0.8 );
			self scaleBehavior( "crouch", 1.3 );
			break;
	}
}

/*
	Announces changes in the match situation.
*/
bot_matchaware_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	last = self getMatchState();
	
	for ( ;; )
	{
		wait 1;
		
		state = self getMatchState();
		
		if ( state == last )
		{
			continue;
		}
		
		last = state;
		self BotNotifyBotEvent( "match", state, self countEnemiesAlive() );
	}
}

/*
	Slip-ups
*/

/*
	Getting shot from behind can catch the bot off guard and slow its turn.
*/
noteSurprise( attacker )
{
	if ( !getdvarint( "bots_real_slipups" ) )
	{
		return;
	}
	
	if ( !isdefined( attacker ) || !isplayer( attacker ) || attacker == self )
	{
		return;
	}
	
	if ( getConeDot( attacker.origin, self.origin, self getplayerangles() ) >= 0 )
	{
		return;
	}
	
	sloppy = self getSloppiness();
	
	if ( randomint( 100 ) >= 30 + 50 * sloppy )
	{
		return;
	}
	
	if ( isdefined( self.bot.real_surprise_until ) && gettime() < self.bot.real_surprise_until )
	{
		return;
	}
	
	self.bot.real_surprise_until = gettime() + int( 400 + 800 * sloppy );
	self BotNotifyBotEvent( "slipup", "surprised", attacker );
}

/*
	Multiplier on how long the bot takes to aim, bigger is slower.
*/
getAimSpeedMultiplier()
{
	if ( !getdvarint( "bots_real_slipups" ) || !isdefined( self.bot.real_surprise_until ) || gettime() >= self.bot.real_surprise_until )
	{
		return 1;
	}
	
	return 1.5 + 2 * self getSloppiness();
}

/*
	True if the bot is panicking: low health with an enemy up close. Some bots keep their cool.
*/
isPanicking( dist )
{
	if ( !getdvarint( "bots_real_slipups" ) || !isdefined( self.maxhealth ) || self.maxhealth <= 0 )
	{
		return false;
	}
	
	if ( self.health >= self.maxhealth * 0.35 || dist >= 400 * 400 )
	{
		return false;
	}
	
	mood = self BotGetMood();
	
	if ( mood == "cocky" )
	{
		return false;
	}
	
	threshold = 10 + 70 * self getSloppiness();
	
	if ( mood == "tilted" )
	{
		threshold += 20;
	}
	
	return ( self.bot.rand < threshold );
}

/*
	Recoil: while a bot sprays, its aim climbs and wanders sideways. Harder bots pull it down better.
	Bots used to fire perfectly still bursts from any gun (#59).
*/
applyRecoil( obj, theTime )
{
	if ( !getdvarint( "bots_real_recoil" ) || !isdefined( self.bot.real_spray_start ) || theTime - self.bot.last_fire_time > 250 )
	{
		return;
	}
	
	// degrees of climb per second of sustained fire
	rate = 0;
	
	switch ( getweaponclass( self getcurrentweapon() ) )
	{
		case "weapon_lmg":
			rate = 6;
			break;
			
		case "weapon_smg":
		case "weapon_machine_pistol":
			rate = 5;
			break;
			
		case "weapon_assault":
			rate = 4.5;
			break;
			
		case "weapon_pistol":
			rate = 3;
			break;
	}
	
	if ( rate <= 0 )
	{
		return;
	}
	
	spray = ( theTime - self.bot.real_spray_start ) / 1000;
	deg = rate * spray * ( 0.25 + 0.75 * self getSloppiness() );
	
	if ( deg > 6 )
	{
		deg = 6;
	}
	
	if ( !isdefined( obj.real_recoil_time ) || timeSince( obj.real_recoil_time, 300 ) )
	{
		obj.real_recoil_time = theTime;
		obj.real_recoil_side = randomfloatrange( -0.4, 0.4 );
	}
	
	units = sqrt( obj.dist ) * deg * 0.01745;
	obj.aim_offset += ( 0, 0, units ) + anglestoright( self getplayerangles() ) * units * obj.real_recoil_side;
}

/*
	A panicking bot sprays wildly.
*/
applySlipupAim( obj, ent, theTime )
{
	if ( !isplayer( ent ) || !self isPanicking( obj.dist ) )
	{
		return;
	}
	
	if ( !isdefined( obj.real_panic_time ) || theTime - obj.real_panic_time >= 150 )
	{
		obj.real_panic_time = theTime;
		obj.real_panic = vectornormalize( ( randomfloatrange( -1, 1 ), randomfloatrange( -1, 1 ), randomfloatrange( -1, 1 ) ) );
	}
	
	obj.aim_offset += obj.real_panic * ( 4 + self getSloppiness() * 12 ) * clamp( sqrt( obj.dist ) / 400, 0.5, 1.5 );
}

/*
	Sometimes reloads straight after a kill, even if another enemy is around.
*/
maybeSlipReload()
{
	if ( !getdvarint( "bots_real_slipups" ) )
	{
		return;
	}
	
	if ( randomint( 100 ) >= 20 + 50 * self getSloppiness() )
	{
		return;
	}
	
	self thread slipReload();
}

/*
	Reloads after a short delay if the mag isn't full.
*/
slipReload()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	wait 0.3;
	
	cur = self getcurrentweapon();
	
	if ( cur == "none" || isweaponcliponly( cur ) || !self getweaponammostock( cur ) )
	{
		return;
	}
	
	if ( self getweaponammoclip( cur ) >= weaponclipsize( cur ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "slipup", "reload" );
	self thread maps\mp\bots\_bot_internal::reload();
}

/*
	Special kills
*/

/*
	Works out whether a kill was special (knife, headshot, long shot, multikill...) and lets the bots involved react.
	Called on the victim.
*/
noteSpecialKill( attacker, sWeapon, sMeansOfDeath, sHitLoc )
{
	if ( !getdvarint( "bots_real_banter" ) )
	{
		return;
	}
	
	// multikills: kills within 3 seconds of each other
	if ( isdefined( attacker.bot_real_multi_time ) && !timeSince( attacker.bot_real_multi_time, 3000 ) )
	{
		attacker.bot_real_multi_count++;
	}
	else
	{
		attacker.bot_real_multi_count = 1;
	}
	
	attacker.bot_real_multi_time = gettime();
	
	type = undefined;
	
	if ( attacker.bot_real_multi_count >= 3 )
	{
		type = "triple";
	}
	else if ( attacker.bot_real_multi_count == 2 )
	{
		type = "double";
	}
	else if ( isdefined( sWeapon ) && sWeapon == "throwingknife_mp" )
	{
		type = "throwingknife";
	}
	else if ( sMeansOfDeath == "MOD_MELEE" )
	{
		type = "knife";
	}
	else if ( isdefined( self.pers[ "cur_kill_streak" ] ) && self.pers[ "cur_kill_streak" ] >= 5 )
	{
		type = "streakend";
	}
	else if ( isdefined( attacker.lastkilledby ) && attacker.lastkilledby == self )
	{
		type = "revenge";
	}
	else if ( sMeansOfDeath == "MOD_HEAD_SHOT" || ( isdefined( sHitLoc ) && sHitLoc == "head" ) )
	{
		type = "headshot";
	}
	else if ( ( sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_PISTOL_BULLET" ) && distancesquared( attacker.origin, self.origin ) > 2000 * 2000 )
	{
		type = "longshot";
	}
	
	if ( !isdefined( type ) )
	{
		return;
	}
	
	if ( attacker is_bot() )
	{
		attacker BotNotifyBotEvent( "specialkill", "brag", type, self );
	}
	
	if ( self is_bot() )
	{
		self BotNotifyBotEvent( "specialkill", "complain", type, attacker );
	}
}

/*
	How many times this player has killed the bot this match.
*/
getTimesKilledBy( player )
{
	if ( !isdefined( player ) || !isplayer( player ) || !isdefined( self.pers[ "bots" ][ "real_killers" ] ) )
	{
		return 0;
	}
	
	count = self.pers[ "bots" ][ "real_killers" ][ player.name ];
	
	if ( !isdefined( count ) )
	{
		return 0;
	}
	
	return count;
}

/*
	Parties
*/

/*
	Bots on the same team sometimes group up in twos and threes, like friends queueing together.
*/
partyThink()
{
	level endon( "game_ended" );
	
	if ( !isdefined( game[ "bots_real_party_next" ] ) )
	{
		game[ "bots_real_party_next" ] = 1;
	}
	
	for ( ;; )
	{
		wait 5;
		
		if ( !getdvarint( "bots_real_parties" ) || !level.teambased )
		{
			continue;
		}
		
		for ( i = 0; i < level.players.size; i++ )
		{
			bot = level.players[ i ];
			
			if ( !bot is_bot() || !isdefined( bot.pers[ "bots" ] ) || !isdefined( bot.team ) || ( bot.team != "allies" && bot.team != "axis" ) )
			{
				continue;
			}
			
			party = bot.pers[ "bots" ][ "party" ];
			
			// moved to the other team (auto balance), the party is gone
			if ( isdefined( party ) && party != 0 && !bot getPartyMates().size && isdefined( bot.pers[ "bots" ][ "party_team" ] ) && bot.pers[ "bots" ][ "party_team" ] != bot.team )
			{
				bot.pers[ "bots" ][ "party" ] = 0;
				continue;
			}
			
			if ( isdefined( party ) )
			{
				continue;
			}
			
			// most bots play solo
			if ( randomint( 100 ) >= 45 )
			{
				bot.pers[ "bots" ][ "party" ] = 0;
				continue;
			}
			
			joined = bot joinOpenParty();
			
			if ( !joined )
			{
				bot.pers[ "bots" ][ "party" ] = game[ "bots_real_party_next" ];
				game[ "bots_real_party_next" ]++;
			}
			
			bot.pers[ "bots" ][ "party_team" ] = bot.team;
		}
	}
}

/*
	Joins a party on the bot's team with room left. Returns true if it joined one.
*/
joinOpenParty()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		other = level.players[ i ];
		
		if ( other == self || !other is_bot() || !isdefined( other.pers[ "bots" ] ) || !isdefined( other.team ) || other.team != self.team )
		{
			continue;
		}
		
		party = other.pers[ "bots" ][ "party" ];
		
		if ( !isdefined( party ) || party == 0 || other getPartyMates().size >= 2 )
		{
			continue;
		}
		
		self.pers[ "bots" ][ "party" ] = party;
		return true;
	}
	
	return false;
}

/*
	The bot's party mates on its team right now.
*/
getPartyMates()
{
	mates = [];
	
	if ( !getdvarint( "bots_real_parties" ) || !isdefined( self.pers[ "bots" ] ) )
	{
		return mates;
	}
	
	party = self.pers[ "bots" ][ "party" ];
	
	if ( !isdefined( party ) || party == 0 || !isdefined( self.team ) )
	{
		return mates;
	}
	
	for ( i = 0; i < level.players.size; i++ )
	{
		other = level.players[ i ];
		
		if ( other == self || !other is_bot() || !isdefined( other.pers[ "bots" ] ) || !isdefined( other.team ) || other.team != self.team )
		{
			continue;
		}
		
		if ( isdefined( other.pers[ "bots" ][ "party" ] ) && other.pers[ "bots" ][ "party" ] == party )
		{
			mates[ mates.size ] = other;
		}
	}
	
	return mates;
}

/*
	True if the other player is in this bot's party.
*/
isPartyMate( other )
{
	mates = self getPartyMates();
	
	for ( i = 0; i < mates.size; i++ )
	{
		if ( mates[ i ] == other )
		{
			return true;
		}
	}
	
	return false;
}

/*
	True if a player with this name is in this bot's party.
*/
isPartyMateName( name )
{
	mates = self getPartyMates();
	
	for ( i = 0; i < mates.size; i++ )
	{
		if ( mates[ i ].name == name )
		{
			return true;
		}
	}
	
	return false;
}

/*
	From a list of players to follow, usually picks a party mate if one is in it.
*/
pickPartyMate( players )
{
	if ( randomint( 100 ) >= 70 )
	{
		return undefined;
	}
	
	for ( i = 0; i < players.size; i++ )
	{
		if ( self isPartyMate( players[ i ] ) )
		{
			return players[ i ];
		}
	}
	
	return undefined;
}

/*
	Party mates stick together.
*/
applyPartyBehavior()
{
	if ( self getPartyMates().size )
	{
		self scaleBehavior( "follow", 2 );
	}
}

/*
	Lobby churn
*/

/*
	A bot that's been tilted for a while sometimes rage quits. Someone new joins a bit later.
*/
maybeRageQuit()
{
	if ( !getdvarint( "bots_real_churn" ) || level.gameended || self BotGetMood() != "tilted" || self.pers[ "bots" ][ "real_deaths" ] < 6 )
	{
		return;
	}
	
	if ( randomint( 100 ) >= 20 || getBotArray().size < 2 )
	{
		return;
	}
	
	// at most one quit every 90 seconds, and not in the last two minutes
	if ( !timeSince( level.bots_real_last_quit, 90000 ) )
	{
		return;
	}
	
	if ( gettimelimit() > 0 && maps\mp\gametypes\_gamelogic::gettimeremaining() < 120000 )
	{
		return;
	}
	
	level.bots_real_last_quit = gettime();
	self thread leaveGame( "quit" );
}

/*
	Says goodbye and leaves. A replacement joins later unless bot filling takes care of it.
*/
leaveGame( kind )
{
	self endon( "disconnect" );
	
	wait 1.5;
	
	self maps\mp\bots\_bot_chat::BotDoChat( 100, maps\mp\bots\_bot_chat::modernLine( self maps\mp\bots\_bot_chat::getBanterPool( kind ) ), undefined, "reply" );
	
	wait 2.5;
	
	if ( kind == "quit" )
	{
		level thread addReplacementBot( randomintrange( 20, 45 ) );
	}
	
	kick( self getentitynumber(), "EXE_DISCONNECTED" );
}

/*
	Adds one bot after the delay, unless bot filling will top the numbers up by itself.
*/
addReplacementBot( delay )
{
	level endon( "game_ended" );
	
	wait delay;
	
	if ( getdvarint( "bots_manage_fill" ) > 0 )
	{
		return;
	}
	
	setdvar( "bots_manage_add", getdvarint( "bots_manage_add" ) + 1 );
}

/*
	At the end of a match a bot sometimes says goodbye and leaves. The count is topped back up for the next map.
*/
endOfMatchChurn()
{
	level waittill( "game_ended" );
	
	if ( !getdvarint( "bots_real_churn" ) || randomint( 100 ) >= 35 )
	{
		return;
	}
	
	wait randomfloatrange( 2, 4 );
	
	bots = getBotArray();
	
	if ( bots.size < 2 )
	{
		return;
	}
	
	// tilted bots are the most likely to call it a night
	leaver = undefined;
	
	for ( i = 0; i < bots.size; i++ )
	{
		if ( bots[ i ] BotGetMood() == "tilted" )
		{
			leaver = bots[ i ];
			break;
		}
	}
	
	if ( !isdefined( leaver ) )
	{
		leaver = random( bots );
	}
	
	leaver thread leaveGame( "gtg" );
	
	// the intermission remembers how many bots to add on the next map, add one back for the leaver
	while ( !level.intermission )
	{
		wait 0.05;
	}
	
	wait 0.5;
	
	if ( getdvarint( "bots_manage_fill" ) <= 0 )
	{
		setdvar( "bots_manage_add", getdvarint( "bots_manage_add" ) + 1 );
	}
}

/*
	Pre-aiming
*/

/*
	Picks a spot worth checking while moving: a visible waypoint off to the side or ahead,
	preferring long sightlines, not the one the bot is walking to.
*/
findPreaimSpot()
{
	travel = self getplayerangles();
	
	if ( isdefined( self.bot.towards_goal ) )
	{
		travel = vectortoangles( self.bot.towards_goal - self.origin );
	}
	
	candidates = [];
	
	// a random sample is plenty for a glance and much cheaper than scanning every waypoint
	for ( n = 0; n < 40; n++ )
	{
		i = randomint( level.waypoints.size );
		
		if ( i == self.bot.next_wp || i == self.bot.second_next_wp )
		{
			continue;
		}
		
		wp = level.waypoints[ i ];
		dist = distancesquared( wp.origin, self.origin );
		
		if ( dist < 250 * 250 || dist > 1500 * 1500 )
		{
			continue;
		}
		
		dot = getConeDot( wp.origin, self.origin, travel );
		
		// corners and side angles, not straight down the path or behind
		if ( dot < 0.2 || dot > 0.95 )
		{
			continue;
		}
		
		candidates[ candidates.size ] = wp.origin;
	}
	
	best = undefined;
	bestDist = 0;
	eye = self geteye();
	
	for ( tries = 0; tries < 6 && candidates.size; tries++ )
	{
		pick = random( candidates );
		candidates = array_remove( candidates, pick );
		
		if ( !bullettracepassed( eye, pick + ( 0, 0, 55 ), false, self ) )
		{
			continue;
		}
		
		dist = distancesquared( pick, self.origin );
		
		if ( dist > bestDist )
		{
			best = pick + ( 0, 0, 55 );
			bestDist = dist;
		}
	}
	
	return best;
}

/*
	While moving without an enemy, bots glance at corners and long sightlines, then look back where they're going.
*/
bot_preaim_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	nextGlance = 0;
	
	for ( ;; )
	{
		wait 0.4;
		
		theTime = gettime();
		
		if ( !getdvarint( "bots_real_preaim" ) || self hasThreat() || self HasScriptAimPos() || self BotIsFrozen() || self isusingremote() || self.bot.issprinting )
		{
			self.bot.real_preaim = undefined;
			continue;
		}
		
		// still glancing
		if ( isdefined( self.bot.real_preaim ) && theTime < self.bot.real_preaim_until )
		{
			continue;
		}
		
		self.bot.real_preaim = undefined;
		
		if ( theTime < nextGlance || lengthsquared( self getvelocity() ) < 400 || !level.waypoints.size )
		{
			continue;
		}
		
		chance = 50;
		
		switch ( self BotGetTrait() )
		{
			case "cautious":
				chance = 70;
				break;
				
			case "rusher":
				chance = 25;
				break;
		}
		
		if ( randomint( 100 ) >= chance )
		{
			nextGlance = theTime + randomintrange( 2000, 3500 );
			continue;
		}
		
		spot = self findPreaimSpot();
		
		if ( !isdefined( spot ) )
		{
			nextGlance = theTime + 1500;
			continue;
		}
		
		self.bot.real_preaim = spot;
		self.bot.real_preaim_until = theTime + randomintrange( 900, 1500 );
		nextGlance = self.bot.real_preaim_until + randomintrange( 1500, 3000 );
	}
}

/*
	Mounted turrets
*/

/*
	Whether a bot on a mounted turret should stay on it. Called by the original "hop off" check.
*/
shouldStayOnTurret()
{
	if ( !getdvarint( "bots_real_turrets" ) )
	{
		return false;
	}
	
	theTime = gettime();
	
	if ( !isdefined( self.bot_real_turret_since ) || timeSince( self.bot_real_turret_since, 60000 ) )
	{
		self.bot_real_turret_since = theTime;
		self.bot_real_turret_threat = theTime;
		self thread turretFireThink();
	}
	
	if ( self hasThreat() )
	{
		self.bot_real_turret_threat = theTime;
	}
	
	// hop off after a while, or when nothing has shown up for a bit
	if ( timeSince( self.bot_real_turret_since, 25000 ) || timeSince( self.bot_real_turret_threat, 8000 ) )
	{
		self.bot_real_turret_since = undefined;
		return false;
	}
	
	return true;
}

/*
	Fires the turret at visible targets, the normal fire logic doesn't know about turrets.
*/
turretFireThink()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	while ( isdefined( self.turret ) && isdefined( self.bot_real_turret_since ) )
	{
		wait 0.1;
		
		if ( isdefined( self.bot.target ) && isdefined( self.bot.target.entity ) && self.bot.target.trace_time > self.pers[ "bots" ][ "skill" ][ "reaction_time" ] && getdvarint( "bots_play_fire" ) )
		{
			self thread maps\mp\bots\_bot_internal::pressFire( 0.1 );
		}
	}
}

/*
	Now and then a bot walks over to a free mounted turret and uses it.
*/
bot_turret_seek_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	turrets = getentarray( "misc_turret", "classname" );
	
	if ( !turrets.size )
	{
		return;
	}
	
	for ( ;; )
	{
		wait randomintrange( 8, 14 );
		
		if ( !getdvarint( "bots_real_turrets" ) || isdefined( self.turret ) )
		{
			continue;
		}
		
		if ( self hasThreat() || self HasScriptGoal() || self.bot_lock_goal || self isusingremote() || self BotIsFrozen() || self inLastStand() )
		{
			continue;
		}
		
		chance = 20;
		
		if ( self BotGetTrait() == "cautious" || self BotGetTrait() == "support" )
		{
			chance = 35;
		}
		
		if ( randomint( 100 ) >= chance * self getSideQuestFactor() )
		{
			continue;
		}
		
		turret = undefined;
		
		for ( i = 0; i < turrets.size; i++ )
		{
			t = turrets[ i ];
			
			if ( !isdefined( t ) || isdefined( t.owner ) || distancesquared( t.origin, self.origin ) > 1000 * 1000 )
			{
				continue;
			}
			
			turret = t;
			break;
		}
		
		if ( !isdefined( turret ) )
		{
			continue;
		}
		
		// stand behind the gun
		spot = turret.origin - anglestoforward( ( 0, turret.angles[ 1 ], 0 ) ) * 40;
		spot = physicstrace( spot + ( 0, 0, 20 ), spot - ( 0, 0, 80 ), false, undefined );
		
		self BotNotifyBotEvent( "turret", "go", turret );
		self SetScriptGoal( spot, 32 );
		
		ret = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if ( ret != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( ret != "goal" || !isdefined( turret ) || isdefined( turret.owner ) )
		{
			continue;
		}
		
		self BotPressUse( 0.3 );
		wait 0.5;
	}
}

/*
	Presets
*/

/*
	Sets every realism toggle at once.
*/
setAllRealism( value )
{
	names = strtok( "traits,aim,hearing,retreat,counter,mood,airhide,grudge,hotspots,teamintel,matchaware,slipups,chat,voice,avenge,banter,parties,churn,preaim,turrets,reactive,recoil", "," );
	
	for ( i = 0; i < names.size; i++ )
	{
		setdvar( "bots_real_" + names[ i ], value );
	}
}

/*
	Applies a named preset: off, casual, competitive or chaos. Returns false for unknown names.
*/
applyPreset( name )
{
	switch ( name )
	{
		case "off":
			setAllRealism( 0 );
			setdvar( "bots_real_adaptive", 0 );
			break;
			
		case "casual":
			setAllRealism( 1 );
			setdvar( "bots_real_adaptive", 1 );
			setdvar( "bots_real_adaptive_kd", 1.5 );
			setdvar( "bots_main_chat", 1.5 );
			setdvar( "bots_real_rage", 50 );
			setdvar( "bots_real_bait", 30 );
			setdvar( "bots_real_flame", 40 );
			setdvar( "bots_real_mood_streak", 3 );
			break;
			
		case "competitive":
			setAllRealism( 1 );
			setdvar( "bots_real_slipups", 0 );
			setdvar( "bots_real_banter", 0 );
			setdvar( "bots_real_churn", 0 );
			setdvar( "bots_real_adaptive", 1 );
			setdvar( "bots_real_adaptive_kd", 1.0 );
			setdvar( "bots_main_chat", 0.5 );
			setdvar( "bots_real_rage", 30 );
			setdvar( "bots_real_bait", 15 );
			setdvar( "bots_real_flame", 0 );
			setdvar( "bots_real_mood_streak", 3 );
			break;
			
		case "chaos":
			setAllRealism( 1 );
			setdvar( "bots_real_adaptive", 0 );
			setdvar( "bots_main_chat", 3 );
			setdvar( "bots_real_rage", 85 );
			setdvar( "bots_real_bait", 60 );
			setdvar( "bots_real_flame", 90 );
			setdvar( "bots_real_mood_streak", 2 );
			break;
			
		default:
			return false;
	}
	
	BotBuiltinPrintConsole( "Bot Warfare XTended: applied the " + name + " preset" );
	return true;
}

/*
	Applies bots_real_preset whenever it changes, and once at map start.
*/
presetThink()
{
	last = getdvar( "bots_real_preset" );
	applyPreset( last );
	
	for ( ;; )
	{
		wait 1;
		
		cur = getdvar( "bots_real_preset" );
		
		if ( cur == last )
		{
			continue;
		}
		
		last = cur;
		applyPreset( cur );
	}
}

/*
	Mood thresholds, 3 kills or deaths in a row by default.
*/
getMoodStreak()
{
	streak = getdvarint( "bots_real_mood_streak" );
	
	if ( streak < 2 )
	{
		streak = 2;
	}
	
	return streak;
}
