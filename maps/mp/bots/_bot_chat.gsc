/*
	_bot_chat
	Author: INeedGames
	Date: 05/09/2022
	Does bot chatter.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	Init
*/
init()
{
	if ( getdvar( "bots_main_chat" ) == "" )
	{
		setdvar( "bots_main_chat", 1.0 );
	}
	
	level thread onBotConnected();
	level thread banterListener();
	level thread reactWatchMatch();
	level thread ambientChat();
	level thread botDialogueThink();
}

/*
	Bot connected
*/
onBotConnected()
{
	for ( ;; )
	{
		level waittill( "bot_connected", bot );
		
		bot thread start_chat_threads();
	}
}

/*
	Does the chatter
*/
BotDoChat( chance, string, isTeam, kind, target )
{
	self endon( "disconnect" );
	
	mod = getdvarfloat( "bots_main_chat" );
	
	if ( mod <= 0.0 )
	{
		return;
	}
	
	if ( !( chance >= 100 || mod >= 100.0 || ( randomint( 100 ) < ( chance * mod * self getChattiness() ) ) ) )
	{
		return;
	}
	
	if ( !self chatAllowed( string ) )
	{
		return;
	}
	
	if ( getdvarint( "bots_real_chat" ) )
	{
		string = self humanizeChat( string, kind );
		
		// people take a moment to type
		wait clamp( 0.4 + string.size * 0.035, 0.4, 3.5 );
	}
	
	if ( isdefined( isTeam ) && isTeam )
	{
		self sayteam( string );
	}
	else
	{
		self sayall( string );
	}
	
	// lets other bots answer (kind says what it was: rage, kill, brag, reply...)
	level notify( "bots_real_said", self, kind, target );
}

/*
	Keeps bots from flooding the chat: one bot message every 1.5 seconds server wide,
	one every 6 seconds per bot, and no line repeated within a minute. Reserves the slot if allowed.
*/
chatAllowed( string )
{
	theTime = gettime();
	
	// a round restart resets the clock, so only trust a wait that is in the near future
	if ( isdefined( level.bots_chat_next ) && level.bots_chat_next - theTime > 0 && level.bots_chat_next - theTime <= 1500 )
	{
		return false;
	}
	
	if ( isdefined( self.bots_chat_next ) && self.bots_chat_next - theTime > 0 && self.bots_chat_next - theTime <= 6000 )
	{
		return false;
	}
	
	if ( !isdefined( level.bots_chat_recent ) )
	{
		level.bots_chat_recent = [];
	}
	
	kept = [];
	
	for ( i = 0; i < level.bots_chat_recent.size; i++ )
	{
		entry = level.bots_chat_recent[ i ];
		age = theTime - entry.time;
		
		if ( age < 0 || age > 60000 )
		{
			continue;
		}
		
		if ( entry.text == string )
		{
			return false;
		}
		
		kept[ kept.size ] = entry;
	}
	
	entry = spawnstruct();
	entry.text = string;
	entry.time = theTime;
	kept[ kept.size ] = entry;
	
	level.bots_chat_recent = kept;
	level.bots_chat_next = theTime + 1500;
	self.bots_chat_next = theTime + 6000;
	
	return true;
}

/*
	True if the one character string is a letter.
*/
isChatLetter( c )
{
	return issubstr( "abcdefghijklmnopqrstuvwxyz", tolower( c ) );
}

/*
	Makes a chat line look typed by this bot: casual bots type in lowercase and skip the full stop,
	sloppy or tilted bots sometimes swap two letters.
*/
humanizeChat( string, kind )
{
	trait = self maps\mp\bots\_bot_realism::BotGetTrait();
	mood = self maps\mp\bots\_bot_realism::BotGetMood();
	
	gen = self getChatGen();
	lowerChance = 40;
	
	switch ( trait )
	{
		case "rusher":
			lowerChance = 100;
			break;
			
		case "support":
			lowerChance = 25;
			break;
			
		case "cautious":
			lowerChance = 0;
			break;
	}
	
	if ( mood == "tilted" )
	{
		lowerChance += 50;
	}
	
	if ( gen == "boomer" )
	{
		lowerChance = 0;
	}
	else if ( gen == "zoomer" || gen == "alpha" )
	{
		lowerChance = 100;
	}
	
	if ( isdefined( kind ) && kind == "flamecaps" )
	{
		lowerChance = 0;
	}
	
	if ( randomint( 100 ) < lowerChance )
	{
		string = tolower( string );
	}
	
	// drop a single trailing full stop sometimes, but leave "..." alone
	if ( string.size > 1 && string[ string.size - 1 ] == "." && string[ string.size - 2 ] != "." && trait != "cautious" && gen != "boomer" && randomint( 100 ) < 60 )
	{
		string = getsubstr( string, 0, string.size - 1 );
	}
	
	typoChance = 3 + self maps\mp\bots\_bot_realism::getSloppiness() * 10;
	
	if ( mood == "tilted" )
	{
		typoChance += 10;
	}
	
	if ( string.size > 4 && randomint( 100 ) < typoChance )
	{
		// swap two neighbouring letters somewhere in the middle
		for ( tries = 0; tries < 5; tries++ )
		{
			i = randomintrange( 1, string.size - 2 );
			
			if ( isChatLetter( string[ i ] ) && isChatLetter( string[ i + 1 ] ) && string[ i ] != string[ i + 1 ] && string[ i - 1 ] != "^" )
			{
				string = getsubstr( string, 0, i ) + string[ i + 1 ] + string[ i ] + getsubstr( string, i + 2, string.size );
				break;
			}
		}
	}
	
	return string;
}

/*
	Threads for bots
*/
start_chat_threads()
{
	self endon( "disconnect" );
	
	self thread start_onnuke_call();
	self thread start_random_chat();
	self thread start_chat_watch();
	self thread start_killed_watch();
	self thread start_death_watch();
	self thread start_endgame_watch();
	
	self thread start_startgame_watch();
}

/*
	Nuke gets called
*/
start_onnuke_call()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		while ( !isdefined( level.nukeincoming ) && !isdefined( level.moabincoming ) )
		{
			wait 0.05 + randomint( 4 );
		}
		
		self thread bot_onnukecall_watch();
		
		wait level.nuketimer + 5;
	}
}

/*
	death
*/
start_death_watch()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill( "death" );
		
		self thread bot_chat_death_watch( self.lastattacker, self.bots_lastks );
		
		self.bots_lastks = 0;
	}
}

/*
	start_endgame_watch
*/
start_endgame_watch()
{
	self endon( "disconnect" );
	
	level waittill ( "game_ended" );
	
	self thread endgame_chat();
}

/*
	Random chatting
*/
start_random_chat()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		wait 1;
		
		if ( randomint( 100 ) < 1 )
		{
			if ( randomint( 100 ) < 1 && isreallyalive( self ) )
			{
				self thread doQuickMessage();
			}
		}
	}
}

/*
	Got a kill
*/
start_killed_watch()
{
	self endon( "disconnect" );
	
	self.bots_lastks = 0;
	
	for ( ;; )
	{
		self waittill( "killed_enemy" );
		
		if ( self.bots_lastks < self.pers[ "cur_kill_streak" ] )
		{
			for ( i = self.bots_lastks + 1; i <= self.pers[ "cur_kill_streak" ]; i++ )
			{
				self thread bot_chat_streak( i );
			}
		}
		
		self.bots_lastks = self.pers[ "cur_kill_streak" ];
		
		self thread bot_chat_killed_watch( self.lastkilledplayer );
	}
}

/*
	Starts things for the bot
*/
start_chat_watch()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		self waittill( "bot_event", msg, a, b, c, d, e, f, g );
		
		switch ( msg )
		{
			case "revive":
				self thread bot_chat_revive_watch( a, b, c, d, e, f, g );
				break;
				
			case "killcam":
				self thread bot_chat_killcam_watch( a, b, c, d, e, f, g );
				break;
				
			case "stuck":
				self thread bot_chat_stuck_watch( a, b, c, d, e, f, g );
				break;
				
			case "tube":
				self thread bot_chat_tube_watch( a, b, c, d, e, f, g );
				break;
				
			case "killstreak":
				self thread bot_chat_killstreak_watch( a, b, c, d, e, f, g );
				break;
				
			case "crate_cap":
				self thread bot_chat_crate_cap_watch( a, b, c, d, e, f, g );
				break;
				
			case "attack_vehicle":
				self thread bot_chat_attack_vehicle_watch( a, b, c, d, e, f, g );
				break;
				
			case "follow_threat":
				self thread bot_chat_follow_threat_watch( a, b, c, d, e, f, g );
				break;
				
			case "camp":
				self thread bot_chat_camp_watch( a, b, c, d, e, f, g );
				break;
				
			case "follow":
				self thread bot_chat_follow_watch( a, b, c, d, e, f, g );
				break;
				
			case "equ":
				self thread bot_chat_equ_watch( a, b, c, d, e, f, g );
				break;
				
			case "nade":
				self thread bot_chat_nade_watch( a, b, c, d, e, f, g );
				break;
				
			case "jav":
				self thread bot_chat_jav_watch( a, b, c, d, e, f, g );
				break;
				
			case "throwback":
				self thread bot_chat_throwback_watch( a, b, c, d, e, f, g );
				break;
				
			case "rage":
				self thread bot_chat_rage_watch( a, b, c, d, e, f, g );
				break;
				
			case "tbag":
				self thread bot_chat_tbag_watch( a, b, c, d, e, f, g );
				break;
				
			case "revenge":
				self thread bot_chat_revenge_watch( a, b, c, d, e, f, g );
				break;
				
			case "heard_target":
				self thread bot_chat_heard_target_watch( a, b, c, d, e, f, g );
				break;
				
			case "hear":
				self thread bot_chat_hear_watch( a, b, c, d, e, f, g );
				break;
				
			case "retreat":
				self thread bot_chat_retreat_watch( a, b, c, d, e, f, g );
				break;
				
			case "avenge":
				self thread bot_chat_avenge_watch( a, b, c, d, e, f, g );
				break;
				
			case "specialkill":
				self thread bot_chat_specialkill_watch( a, b, c, d, e, f, g );
				break;
				
			case "mood":
				self thread bot_chat_mood_watch( a, b, c, d, e, f, g );
				break;
				
			case "grudge":
				self thread bot_chat_grudge_watch( a, b, c, d, e, f, g );
				break;
				
			case "counter":
				self thread bot_chat_counter_watch( a, b, c, d, e, f, g );
				break;
				
			case "airhide":
				self thread bot_chat_airhide_watch( a, b, c, d, e, f, g );
				break;
				
			case "hotspot":
				self thread bot_chat_hotspot_watch( a, b, c, d, e, f, g );
				break;
				
			case "intel":
				self thread bot_chat_intel_watch( a, b, c, d, e, f, g );
				break;
				
			case "match":
				self thread bot_chat_match_watch( a, b, c, d, e, f, g );
				break;
				
			case "slipup":
				self thread bot_chat_slipup_watch( a, b, c, d, e, f, g );
				break;
				
			case "uav_target":
				self thread bot_chat_uav_target_watch( a, b, c, d, e, f, g );
				break;
				
			case "attack_equ":
				self thread bot_chat_attack_equ_watch( a, b, c, d, e, f, g );
				break;
				
			case "turret_attack":
				self thread bot_chat_turret_attack_watch( a, b, c, d, e, f, g );
				break;
				
			case "dom":
				self thread bot_chat_dom_watch( a, b, c, d, e, f, g );
				break;
				
			case "hq":
				self thread bot_chat_hq_watch( a, b, c, d, e, f, g );
				break;
				
			case "sab":
				self thread bot_chat_sab_watch( a, b, c, d, e, f, g );
				break;
				
			case "sd":
				self thread bot_chat_sd_watch( a, b, c, d, e, f, g );
				break;
				
			case "cap":
				self thread bot_chat_cap_watch( a, b, c, d, e, f, g );
				break;
				
			case "dem":
				self thread bot_chat_dem_watch( a, b, c, d, e, f, g );
				break;
				
			case "gtnw":
				self thread bot_chat_gtnw_watch( a, b, c, d, e, f, g );
				break;
				
			case "oneflag":
				self thread bot_chat_oneflag_watch( a, b, c, d, e, f, g );
				break;
				
			case "arena":
				self thread bot_chat_arena_watch( a, b, c, d, e, f, g );
				break;
				
			case "vip":
				self thread bot_chat_vip_watch( a, b, c, d, e, f, g );
				break;
				
			case "conf":
				self thread bot_chat_conf_watch( a, b, c, d, e, f, g );
				break;
				
			case "grnd":
				self thread bot_chat_grnd_watch( a, b, c, d, e, f, g );
				break;
				
			case "tdef":
				self thread bot_chat_tdef_watch( a, b, c, d, e, f, g );
				break;
				
			case "box_cap":
				self thread bot_chat_box_cap_watch( a, b, c, d, e, f, g );
				break;
				
			case "connection":
				self thread bot_chat_connection_player_watch( a, b, c, d, e, f, g );
				break;
				
			case "chat":
				self thread bot_chat_chat_player_watch( a, b, c, d, e, f, g );
				break;
		}
	}
}

/*
	When another player chats
*/
bot_chat_chat_player_watch( chatstr, message, player, is_hidden, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !getdvarint( "bots_real_chat" ) || !isdefined( message ) || !isdefined( player ) || !isplayer( player ) || player == self || player is_bot() )
	{
		return;
	}
	
	if ( isdefined( is_hidden ) && is_hidden )
	{
		return;
	}
	
	msg = tolower( message );
	mentioned = issubstr( msg, tolower( self.name ) );
	talking = self inConvoWith( player );
	justKilled = ( isdefined( self.bot_real_lastvictim ) && self.bot_real_lastvictim == player && !maps\mp\bots\_bot_realism::timeSince( self.bot_real_lastvictim_time, 15000 ) );
	
	// trash talk aimed at this bot gets flamed back, harder each time
	if ( getdvarint( "bots_real_banter" ) && getdvarint( "bots_real_flame" ) > 0 && isInsult( msg ) && ( mentioned || talking || justKilled ) )
	{
		self thread flameBackAt( player );
		return;
	}
	
	// in the middle of a topic: carry it on, whatever they said
	if ( self topicActive( player ) )
	{
		line = self topicReply( msg, player );
		
		if ( isdefined( line ) )
		{
			self startConvo( player );
			player.bot_real_talking_to = self;
			player.bot_real_talking_time = gettime();
			
			wait randomfloatrange( 0.8, 2.2 );
			self BotDoChat( 100, line, undefined, "reply" );
		}
		
		return;
	}
	
	// someone else is already talking with this player
	if ( !mentioned && !talking && isdefined( player.bot_real_talking_to ) && player.bot_real_talking_to != self && !maps\mp\bots\_bot_realism::timeSince( player.bot_real_talking_time, 25000 ) )
	{
		return;
	}
	
	topic = getTopicForMessage( msg );
	reply = undefined;
	
	if ( !isdefined( topic ) )
	{
		reply = self getChatReply( msg, player.name );
		
		if ( !isdefined( reply ) )
		{
			if ( !mentioned && !talking )
			{
				return;
			}
			
			// in a conversation the bot answers anything
			if ( isQuestion( msg ) )
			{
				reply = fillLine( self getReactPool( "question" ), player.name );
			}
			else
			{
				reply = fillLine( self getReactPool( "convo" ), player.name );
			}
			
			if ( !isdefined( reply ) )
			{
				reply = "?";
			}
		}
	}
	
	// one bot answers each message, unless the player is talking to a bot
	if ( !mentioned && !talking )
	{
		if ( isdefined( level.bots_chat_reply_time ) && !maps\mp\bots\_bot_realism::timeSince( level.bots_chat_reply_time, 4000 ) )
		{
			return;
		}
		
		if ( randomint( 100 ) >= 65 )
		{
			return;
		}
	}
	
	level.bots_chat_reply_time = gettime();
	self startConvo( player );
	player.bot_real_talking_to = self;
	player.bot_real_talking_time = gettime();
	
	// the message started a topic: the bot takes it up and keeps it going
	if ( isdefined( topic ) )
	{
		self startTopic( topic, player );
		reply = self topicReply( msg, player );
		
		if ( !isdefined( reply ) )
		{
			return;
		}
	}
	
	wait randomfloatrange( 0.5, 2 );
	self BotDoChat( 100, reply, undefined, "reply" );
	
	if ( !mentioned && !isdefined( topic ) )
	{
		level thread chimeIn( self );
	}
}

/*
	True if the message reads like a question.
*/
isQuestion( msg )
{
	if ( msg.size && msg[ msg.size - 1 ] == "?" )
	{
		return true;
	}
	
	starts = strtok( "who ,what ,why ,how ,where ,when ,anyone ,does ,is ,are ,can ", "," );
	
	for ( i = 0; i < starts.size; i++ )
	{
		if ( isStrStart( msg, starts[ i ] ) )
		{
			return true;
		}
	}
	
	return false;
}

/*
	Topics bots have a reply for, beyond the basics. undefined if none.
*/
getChatTopic( msg )
{
	if ( msg == "ty" || isStrStart( msg, "ty " ) || issubstr( msg, "thanks" ) || issubstr( msg, "thx" ) || issubstr( msg, "tysm" ) )
	{
		return "thanks";
	}
	
	if ( issubstr( msg, "sorry" ) || issubstr( msg, "my bad" ) || msg == "mb" || isStrStart( msg, "mb " ) )
	{
		return "sorry";
	}
	
	if ( msg == "wp" || isStrStart( msg, "wp " ) || issubstr( msg, "well played" ) || issubstr( msg, "nice game" ) || issubstr( msg, "good game" ) )
	{
		return "nicegame";
	}
	
	if ( issubstr( msg, "1v1" ) )
	{
		return "oneonone";
	}
	
	if ( issubstr( msg, "report" ) )
	{
		return "report";
	}
	
	if ( issubstr( msg, "help" ) )
	{
		return "help";
	}
	
	// whole words only, "flag" and "camping" shouldn't count
	if ( isStrStart( msg, "lag" ) || issubstr( msg, " lag" ) || isStrStart( msg, "ping" ) || issubstr( msg, " ping" ) )
	{
		return "lag";
	}
	
	if ( issubstr( msg, "camp" ) )
	{
		return "camper";
	}
	
	if ( issubstr( msg, "wtf" ) || issubstr( msg, "omg" ) || issubstr( msg, "what the" ) )
	{
		return "wtf";
	}
	
	if ( msg == "rip" || isStrStart( msg, "rip " ) || msg == "f" )
	{
		return "rip";
	}
	
	return undefined;
}

/*
	A fitting reply to something a player typed, undefined if nothing fits.
*/
getChatReply( msg, name )
{
	pool = undefined;
	
	topic = getChatTopic( msg );
	
	if ( isdefined( topic ) )
	{
		return fillLine( self getReactPool( topic ), name );
	}
	
	if ( issubstr( msg, "glhf" ) || issubstr( msg, "gl hf" ) || issubstr( msg, "good luck" ) )
	{
		pool = "glhf|you too|gl|glhf " + name;
	}
	else if ( issubstr( msg, "gg" ) )
	{
		switch ( self getChatGen() )
		{
			case "zoomer":
				pool = "gg|ggs|W gg|gg " + name;
				break;
				
			case "alpha":
				pool = "gg sigma|gg +1000 aura|gg " + name;
				break;
				
			case "boomer":
				pool = "Good game!|Good game, well played.|Good game, " + name + ".";
				break;
				
			default:
				pool = "gg|gg wp|ggs|gg " + name;
				break;
		}
	}
	else if ( msg == "hi" || isStrStart( msg, "hi " ) || issubstr( msg, "hello" ) || isStrStart( msg, "hey" ) || msg == "yo" || isStrStart( msg, "yo " ) || msg == "sup" || isStrStart( msg, "sup " ) )
	{
		switch ( self getChatGen() )
		{
			case "zoomer":
				pool = "yo|sup|yo " + name;
				break;
				
			case "alpha":
				pool = "sup sigma|yo " + name + "|hi skibidi";
				break;
				
			case "boomer":
				pool = "Hello there!|Hi, " + name + ".|Good evening, " + name + ".";
				break;
				
			default:
				pool = "hey|hi|hey " + name + "|hello|hi " + name;
				break;
		}
	}
	else if ( issubstr( msg, "nice shot" ) || msg == "ns" || isStrStart( msg, "ns " ) || issubstr( msg, "good shot" ) || issubstr( msg, "nice one" ) )
	{
		pool = "ty|thanks|appreciate it|ty " + name;
	}
	else if ( issubstr( msg, "bot" ) )
	{
		pool = "who are you calling a bot|i'm not a bot|bots don't type this fast|that's what a bot would say";
	}
	else if ( issubstr( msg, "hack" ) || issubstr( msg, "cheat" ) || issubstr( msg, "aimbot" ) || issubstr( msg, "walls" ) )
	{
		pool = "not hacking, just lucky|report me then|just paying attention|it's called practice";
	}
	else if ( issubstr( msg, "noob" ) || issubstr( msg, "trash" ) || issubstr( msg, "bad" ) || issubstr( msg, "ez" ) )
	{
		if ( randomint( 2 ) )
		{
			return modernLine( self getModernPool( "bait" ), name );
		}
		
		pool = "bold words|says you|we'll see|talk is cheap|ok " + name;
	}
	else if ( issubstr( msg, "lol" ) || issubstr( msg, "lmao" ) || issubstr( msg, "haha" ) )
	{
		pool = "lol|haha";
	}
	
	if ( !isdefined( pool ) )
	{
		// an unanswered question anyone can take a stab at
		if ( isQuestion( msg ) )
		{
			return fillLine( self getReactPool( "question" ), name );
		}
		
		return undefined;
	}
	
	return random( strtok( pool, "|" ) );
}

/*
	When a player connected
*/
bot_chat_connection_player_watch( conn, player, playername, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !getdvarint( "bots_real_reactive" ) || !isdefined( playername ) )
	{
		return;
	}
	
	if ( !isdefined( level.bots_real_humans ) )
	{
		level.bots_real_humans = [];
		level.bots_real_greeted = [];
	}
	
	switch ( conn )
	{
		case "connected":
			if ( !isdefined( player ) || player is_bot() )
			{
				return;
			}
			
			level.bots_real_humans[ playername ] = true;
			
			// one bot says hi, once they've loaded in
			if ( !maps\mp\bots\_bot_realism::timeSince( level.bots_real_greeted[ playername ], 30000 ) || randomint( 100 ) >= 40 * self getChattiness() )
			{
				return;
			}
			
			level.bots_real_greeted[ playername ] = gettime();
			wait randomfloatrange( 8, 14 );
			
			if ( isdefined( player ) )
			{
				self BotDoChat( 100, fillLine( self getReactPool( "greet" ), playername ), undefined, "reply" );
			}
			
			break;
			
		case "disconnected":
			if ( !isdefined( level.bots_real_humans[ playername ] ) || isdefined( level.bots_real_greeted[ "bye_" + playername ] ) )
			{
				return;
			}
			
			if ( randomint( 100 ) >= 35 * self getChattiness() )
			{
				return;
			}
			
			level.bots_real_greeted[ "bye_" + playername ] = true;
			wait randomfloatrange( 1, 3 );
			self BotDoChat( 100, fillLine( self getReactPool( "bye" ), playername ), undefined, "reply" );
			break;
	}
}

/*
	start_startgame_watch
*/
start_startgame_watch()
{
	self endon( "disconnect" );
	
	wait( randomint( 5 ) + randomint( 5 ) );
	
	if ( randomint( 100 ) < 40 )
	{
		self BotDoChat( 7, modernLine( self getModernPool( "start" ) ) );
		return;
	}
	
	switch ( level.gametype )
	{
		case "war":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "tdm, let's go" );
					break;
					
				case 1:
					self BotDoChat( 7, "let's get em, wipe the floor with them" );
					break;
					
				case 2:
					self BotDoChat( 7, "alright, let's do this" );
					break;
			}
			
			break;
			
		case "dom":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "dom, nice. someone grab B early" );
					break;
					
				case 1:
					self BotDoChat( 7, "cap the flags and hold them" );
					break;
					
				case 2:
					self BotDoChat( 7, "alright, let's do this" );
					break;
			}
			
			break;
			
		case "sd":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "no respawns, don't be reckless" );
					break;
					
				case 1:
					self BotDoChat( 7, "let's get em, wipe the floor with them" );
					break;
					
				case 2:
					self BotDoChat( 7, "alright, let's do this" );
					break;
			}
			
			break;
			
		case "dd":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "Try not to get spawn killed." );
					break;
					
				case 1:
					self BotDoChat( 7, "OK we need a plan. Nah lets just kill." );
					break;
					
				case 2:
					self BotDoChat( 7, "alright, let's do this" );
					break;
			}
			
			break;
			
		case "sab":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "sabotage, haven't played this in ages" );
					break;
					
				case 1:
					self BotDoChat( 7, "Who plays sab these days." );
					break;
					
				case 2:
					self BotDoChat( 7, "someone grab the bomb" );
					break;
			}
			
			break;
			
		case "ctf":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "ctf, somebody stay on defense" );
					break;
					
				case 1:
					self BotDoChat( 7, "i'm going for their flag" );
					break;
					
				case 2:
					self BotDoChat( 7, "NO IM CAPPING IT" );
					break;
			}
			
			break;
			
		case "dm":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, "ffa, every man for himself" );
					break;
					
				case 1:
					self BotDoChat( 7, "IM GOING TO KILL U ALL" );
					break;
					
				case 2:
					self BotDoChat( 7, "lol sweet. time to camp." );
					break;
			}
			
			break;
			
		case "koth":
			self BotDoChat( 7, "headquarters, let's go" );
			break;
			
		case "gtnw":
			self BotDoChat( 7, "gtnw? haven't seen this in years" );
			break;
	}
}

/*
	Does quick cod4 style message
*/
doQuickMessage()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	if ( !isdefined( self.talking ) || !self.talking )
	{
		self.talking = true;
		soundalias = "";
		saytext = "";
		wait 2;
		self.spamdelay = true;
		
		switch ( randomint( 11 ) )
		{
			case 4 :
				soundalias = "mp_cmd_suppressfire";
				saytext = "Suppressing fire!";
				break;
				
			case 5 :
				soundalias = "mp_cmd_followme";
				saytext = "Follow Me!";
				break;
				
			case 6 :
				soundalias = "mp_stm_enemyspotted";
				saytext = "Enemy spotted!";
				break;
				
			case 7 :
				soundalias = "mp_cmd_fallback";
				saytext = "Fall back!";
				break;
				
			case 8 :
				soundalias = "mp_stm_needreinforcements";
				saytext = "Need reinforcements!";
				break;
		}
		
		if ( soundalias != "" && saytext != "" )
		{
			self maps\mp\gametypes\_quickmessages::saveheadicon();
			self maps\mp\gametypes\_quickmessages::doquickmessage( soundalias, saytext );
			wait 2;
			self maps\mp\gametypes\_quickmessages::restoreheadicon();
		}
		else
		{
			if ( randomint( 100 ) < 1 )
			{
				self BotDoChat( 1, maps\mp\bots\_bot_utility::keyCodeToString( 2 ) + maps\mp\bots\_bot_utility::keyCodeToString( 17 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 3 ) + maps\mp\bots\_bot_utility::keyCodeToString( 8 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 8 ) + maps\mp\bots\_bot_utility::keyCodeToString( 13 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 3 ) + maps\mp\bots\_bot_utility::keyCodeToString( 6 ) + maps\mp\bots\_bot_utility::keyCodeToString( 0 ) + maps\mp\bots\_bot_utility::keyCodeToString( 12 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 18 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 5 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 17 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 1 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 18 ) + maps\mp\bots\_bot_utility::keyCodeToString( 26 ) );
			}
		}
		
		self.spamdelay = undefined;
		wait randomint( 5 );
		self.talking = false;
	}
}

/*
	endgame_chat
*/
endgame_chat()
{
	self endon( "disconnect" );
	
	wait ( randomint( 6 ) + randomint( 6 ) );
	b = -1;
	w = 999999999;
	winner = undefined;
	loser = undefined;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( player.pers[ "score" ] > b )
		{
			winner = player;
			b = player.pers[ "score" ];
		}
		
		if ( player.pers[ "score" ] < w )
		{
			loser = player;
			w = player.pers[ "score" ];
		}
	}
	
	if ( isdefined( winner ) && winner != self && !winner is_bot() && getdvarint( "bots_real_banter" ) && randomint( 100 ) < 20 )
	{
		self BotDoChat( 30, modernLine( self getBanterPool( "mvp" ), winner.name ) );
		return;
	}
	
	if ( randomint( 100 ) < 40 )
	{
		won = ( isdefined( winner ) && self == winner );
		
		if ( level.teambased )
		{
			won = ( self.pers[ "team" ] == maps\mp\gametypes\_gamescore::getwinningteam() );
		}
		
		// only mention the top player if it's someone else
		topName = undefined;
		
		if ( isdefined( winner ) && winner != self )
		{
			topName = winner.name;
		}
		
		if ( won )
		{
			self BotDoChat( 20, modernLine( self getModernPool( "won" ), topName ) );
		}
		else
		{
			self BotDoChat( 20, modernLine( self getModernPool( "lost" ), topName ) );
		}
		
		return;
	}
	
	if ( level.teambased )
	{
		winningteam = maps\mp\gametypes\_gamescore::getwinningteam();
		
		if ( self.pers[ "team" ] == winningteam )
		{
			switch ( randomint( 21 ) )
			{
				case 0:
					self BotDoChat( 20, "Haha what a game" );
					break;
					
				case 1:
					self BotDoChat( 20, "that was a good one" );
					break;
					
				case 3:
					self BotDoChat( 20, "That was fun" );
					break;
					
				case 4:
					self BotDoChat( 20, "Lol my team always wins!" );
					break;
					
				case 5:
					self BotDoChat( 20, "Haha if i am on " + winningteam + " my team always wins!" );
					break;
					
				case 2:
					self BotDoChat( 20, "gg" );
					break;
					
				case 6:
					self BotDoChat( 20, "gg, great team" );
					break;
					
				case 7:
					self BotDoChat( 20, "My team " + self.pers[ "team" ] + " always wins!!" );
					break;
					
				case 8:
					self BotDoChat( 20, "what a match" );
					break;
					
				case 9:
					self BotDoChat( 20, "ez" );
					break;
					
				case 10:
					self BotDoChat( 20, "Nice game!! Good job team!" );
					break;
					
				case 11:
					self BotDoChat( 20, "gg wp team" );
					break;
					
				case 12:
					self BotDoChat( 20, "campers lose, as usual" );
					break;
					
				case 13:
					self BotDoChat( 20, "owned." );
					break;
					
				case 14:
					self BotDoChat( 20, "we won!" );
					break;
					
				case 16:
					self BotDoChat( 20, "they never stood a chance" );
					break;
					
				case 15:
					self BotDoChat( 20, "WE WON" );
					break;
					
				case 17:
					if ( self == winner )
					{
						self BotDoChat( 20, "you're welcome team" );
					}
					else if ( self == loser )
					{
						self BotDoChat( 20, "got carried but a win is a win" );
					}
					else if ( self != loser && randomint( 2 ) == 1 )
					{
						self BotDoChat( 20, "rough game for " + loser.name );
					}
					else if ( self != winner )
					{
						self BotDoChat( 20, "wow " + winner.name + " did very well!" );
					}
					
					break;
					
				case 18:
					if ( self == winner )
					{
						self BotDoChat( 20, "i'm on form today" );
					}
					else if ( self == loser )
					{
						self BotDoChat( 20, "the team carried me" );
					}
					else if ( self != loser && randomint( 2 ) == 1 )
					{
						self BotDoChat( 20, "better luck next time " + loser.name );
					}
					else if ( self != winner )
					{
						self BotDoChat( 20, "i think " + winner.name + " is a hacker" );
					}
					
					break;
					
				case 19:
					self BotDoChat( 20, "we won lol sweet" );
					break;
					
				case 20:
					self BotDoChat( 20, "we won" );
					break;
			}
		}
		else
		{
			if ( winningteam != "none" )
			{
				switch ( randomint( 21 ) )
				{
					case 0:
						self BotDoChat( 20, "Hackers win" );
						break;
						
					case 1:
						self BotDoChat( 20, "lol we got destroyed" );
						break;
						
					case 3:
						self BotDoChat( 20, "That wasn't fun" );
						break;
						
					case 4:
						self BotDoChat( 20, "Wow my team SUCKS!" );
						break;
						
					case 5:
						self BotDoChat( 20, "My team " + self.pers[ "team" ] + " always loses!!" );
						break;
						
					case 2:
						self BotDoChat( 20, "gg" );
						break;
						
					case 6:
						self BotDoChat( 20, "bg" );
						break;
						
					case 7:
						self BotDoChat( 20, "vbg" );
						break;
						
					case 8:
						self BotDoChat( 20, "what a match" );
						break;
						
					case 9:
						self BotDoChat( 20, "Good game" );
						break;
						
					case 10:
						self BotDoChat( 20, "Bad game" );
						break;
						
					case 11:
						self BotDoChat( 20, "very bad game" );
						break;
						
					case 12:
						self BotDoChat( 20, "campers win" );
						break;
						
					case 13:
						self BotDoChat( 20, "campers everywhere" );
						break;
						
					case 14:
						if ( self == winner )
						{
							self BotDoChat( 20, "top of the board and we still lost" );
						}
						else if ( self == loser )
						{
							self BotDoChat( 20, "yeah that loss is on me" );
						}
						else if ( self != loser && randomint( 2 ) == 1 )
						{
							self BotDoChat( 20, loser.name + " should just leave" );
						}
						else if ( self != winner )
						{
							self BotDoChat( 20, "ok " + winner.name + " is definitely cheating" );
						}
						
						break;
						
					case 15:
						if ( self == winner )
						{
							self BotDoChat( 20, "my teammates are garbage" );
						}
						else if ( self == loser )
						{
							self BotDoChat( 20, "lol im garbage" );
						}
						else if ( self != loser && randomint( 2 ) == 1 )
						{
							self BotDoChat( 20, loser.name + " sux" );
						}
						else if ( self != winner )
						{
							self BotDoChat( 20, winner.name + " is a noob!" );
						}
						
						break;
						
					case 16:
						self BotDoChat( 20, "we lost but i still had fun" );
						break;
						
					case 17:
						self BotDoChat( 20, "damn tryhards" );
						break;
						
					case 18:
						self BotDoChat( 20, "that wasn't fair" );
						break;
						
					case 19:
						self BotDoChat( 20, "lost did we?" );
						break;
						
					case 20:
						self BotDoChat( 20, "unreal" );
						break;
				}
			}
			else
			{
				switch ( randomint( 8 ) )
				{
					case 0:
						self BotDoChat( 20, "gg" );
						break;
						
					case 1:
						self BotDoChat( 20, "bg" );
						break;
						
					case 2:
						self BotDoChat( 20, "vbg" );
						break;
						
					case 3:
						self BotDoChat( 20, "vgg" );
						break;
						
					case 4:
						self BotDoChat( 20, "gg no rm" );
						break;
						
					case 5:
						self BotDoChat( 20, "ggggggggg" );
						break;
						
					case 6:
						self BotDoChat( 20, "good game" );
						break;
						
					case 7:
						self BotDoChat( 20, "gee gee" );
						break;
				}
			}
		}
	}
	else
	{
		switch ( randomint( 20 ) )
		{
			case 0:
				if ( self == winner )
				{
					self BotDoChat( 20, "get good, all of you" );
				}
				else if ( self == loser )
				{
					self BotDoChat( 20, "don't look at my score" );
				}
				else if ( self != loser && randomint( 2 ) == 1 )
				{
					self BotDoChat( 20, "gg, unlucky " + loser.name );
				}
				else if ( self != winner )
				{
					self BotDoChat( 20, "This game sucked, " + winner.name + " is such a hacker!!" );
				}
				
				break;
				
			case 1:
				if ( self == winner )
				{
					self BotDoChat( 20, "good round for me" );
				}
				else if ( self == loser )
				{
					self BotDoChat( 20, "gg, nice score " + winner.name );
				}
				else if ( self != loser && randomint( 2 ) == 1 )
				{
					self BotDoChat( 20, "rough one " + loser.name );
				}
				else if ( self != winner )
				{
					self BotDoChat( 20, "Nice Score " + winner.name + ", how did you get to be so good?" );
				}
				
				break;
				
			case 2:
				if ( self == winner )
				{
					self BotDoChat( 20, "good round for me" );
				}
				else if ( self == loser )
				{
					self BotDoChat( 20, "nice wallhacks " + winner.name );
				}
				else if ( self != loser && randomint( 2 ) == 1 )
				{
					self BotDoChat( 20, "at least i beat " + loser.name );
				}
				else if ( self != winner )
				{
					self BotDoChat( 20, "lolwtf " + winner.name );
				}
				
				break;
				
			case 3:
				self BotDoChat( 20, "gee gee" );
				break;
				
			case 4:
				self BotDoChat( 20, "what a match" );
				break;
				
			case 5:
				self BotDoChat( 20, "Nice Game!" );
				break;
				
			case 6:
				self BotDoChat( 20, "good game" );
				break;
				
			case 7:
				self BotDoChat( 20, "gg, cya all" );
				break;
				
			case 8:
				self BotDoChat( 20, "bg" );
				break;
				
			case 9:
				self BotDoChat( 20, "GG" );
				break;
				
			case 10:
				self BotDoChat( 20, "gg" );
				break;
				
			case 11:
				self BotDoChat( 20, "vbg" );
				break;
				
			case 12:
				self BotDoChat( 20, "gga" );
				break;
				
			case 13:
				self BotDoChat( 20, "BG" );
				break;
				
			case 14:
				self BotDoChat( 20, "stupid map" );
				break;
				
			case 15:
				self BotDoChat( 20, "ffa sux" );
				break;
				
			case 16:
				self BotDoChat( 20, "had fun" );
				break;
				
			case 17:
				self BotDoChat( 20, "this lobby is full of bots lol" );
				break;
				
			case 18:
				self BotDoChat( 20, "thanks for the free kills" );
				break;
				
			case 19:
				self BotDoChat( 20, "damn campers" );
				break;
		}
	}
}

/*
	bot_onnukecall_watch
*/
bot_onnukecall_watch()
{
	self endon( "disconnect" );
	
	switch ( randomint( 4 ) )
	{
		case 0:
			if ( level.nukeinfo.player != self )
			{
				self BotDoChat( 30, "Wow who got a nuke?" );
			}
			else
			{
				self BotDoChat( 30, "NUKE" );
			}
			
			break;
			
		case 1:
			if ( level.nukeinfo.player != self )
			{
				self BotDoChat( 30, "lol " + level.nukeinfo.player.name + " is a hacker" );
			}
			else
			{
				self BotDoChat( 30, "im the best!" );
			}
			
			break;
			
		case 2:
			self BotDoChat( 30, "a nuke? well played" );
			break;
			
		case 3:
			if ( level.nukeinfo.team != self.team )
			{
				self BotDoChat( 30, "our team just got nuked..." );
			}
			else
			{
				self BotDoChat( 30, "man my team is good lol" );
			}
			
			break;
	}
}

/*
	Got streak
*/
bot_chat_streak( streakCount )
{
	self endon( "disconnect" );
	
	if ( streakCount == 25 )
	{
		if ( self.pers[ "lastEarnedStreak" ] == "nuke" )
		{
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 100, "I GOT A NUKE!!" );
					break;
					
				case 1:
					self BotDoChat( 100, "NUKEEEEEEEEEEEEEEEEE" );
					break;
					
				case 2:
					self BotDoChat( 100, "25 killstreak!!!" );
					break;
					
				case 3:
					self BotDoChat( 100, "NUKE INBOUND" );
					break;
					
				case 4:
					self BotDoChat( 100, "you're all getting nuked" );
					break;
			}
		}
	}
}

/*
	Say killed stuff
*/
bot_chat_killed_watch( victim )
{
	self endon( "disconnect" );
	
	if ( !isdefined( victim ) || !isdefined( victim.name ) )
	{
		return;
	}
	
	self.bot_real_lastvictim = victim;
	self.bot_real_lastvictim_time = gettime();
	
	if ( self maybeStartFlameWar( victim ) )
	{
		return;
	}
	
	message = "";
	
	switch ( randomint( 42 ) )
	{
		case 0:
			message = ( "Haha take that " + victim.name );
			break;
			
		case 1:
			message = ( "got you" );
			break;
			
		case 2:
			message = ( "outplayed, " + victim.name );
			break;
			
		case 3:
			message = ( "Better luck next time " + victim.name );
			break;
			
		case 4:
			message = ( victim.name + " Is that all you got?" );
			break;
			
		case 5:
			message = ( "LOL " + victim.name + ", l2play" );
			break;
			
		case 6:
			message = ( ":)" );
			break;
			
		case 7:
			message = ( "Im unstoppable!" );
			break;
			
		case 8:
			message = ( "Wow " + victim.name + " that was a close one!" );
			break;
			
		case 9:
			message = ( "Haha thank you, thank you very much." );
			break;
			
		case 10:
			message = ( "haha" );
			break;
			
		case 11:
			message = ( "too slow " + victim.name );
			break;
			
		case 12:
			message = ( "Wow that was a lucky shot!" );
			break;
			
		case 13:
			message = ( "clean" );
			break;
			
		case 14:
			message = ( "Don't even think that i am hacking cause that was pure skill!" );
			break;
			
		case 15:
			message = ( "no chance " + victim.name );
			break;
			
		case 16:
			message = ( "Wow that was an easy kill." );
			break;
			
		case 17:
			message = ( "noob down" );
			break;
			
		case 18:
			message = ( "Lol u suck " + victim.name );
			break;
			
		case 19:
			message = ( "PWND!" );
			break;
			
		case 20:
			message = ( "sit down " + victim.name );
			break;
			
		case 21:
			message = ( "wow that was close, but i still got you ;)" );
			break;
			
		case 22:
			message = ( "oooooo! i got u good!" );
			break;
			
		case 23:
			message = ( "thanks for the streak lol" );
			break;
			
		case 24:
			message = ( "lol sweet got a kill" );
			break;
			
		case 25:
			message = ( "easy one" );
			break;
			
		case 26:
			message = ( "lolwtf that was a funny death" );
			break;
			
		case 27:
			message = ( "i bet " + victim.name + " is using the arrow keys to move." );
			break;
			
		case 28:
			message = ( "lol its noobs like " + victim.name + " that ruin teams" );
			break;
			
		case 29:
			message = ( "lolwat was that " + victim.name + "?" );
			break;
			
		case 30:
			message = ( "haha thanks " + victim.name + ", im at a " + self.pers[ "cur_kill_streak" ] + " streak." );
			break;
			
		case 31:
			message = ( "lol " + victim.name + " is at a " + victim.pers[ "cur_death_streak" ] + " deathstreak" );
			break;
			
		case 32:
			message = ( "got him" );
			break;
			
		case 33:
			message = ( "oooh get merked " + victim.name );
			break;
			
		case 34:
			message = ( "i love " + getMapName( getdvar( "mapname" ) ) + "!" );
			break;
			
		case 35:
			message = ( getMapName( getdvar( "mapname" ) ) + " is my favorite map!" );
			break;
			
		case 36:
			message = ( "get rekt" );
			break;
			
		case 37:
			message = ( "lol i rekt " + victim.name );
			break;
			
		case 38:
			message = ( "lol ur mum can play better than u!" );
			break;
			
		case 39:
			message = ( victim.name + " just got rekt" );
			break;
			
		case 40:
			if ( isdefined( victim.attackerdata ) && isdefined( victim.attackerdata[ self.guid ] ) && isdefined( victim.attackerdata[ self.guid ].weapon ) )
			{
				message = ( "Man, I sure love my " + getbaseweaponname( victim.attackerdata[ self.guid ].weapon ) + "!" );
			}
			
			break;
			
		case 41:
			message = ( "next time " + victim.name );
			break;
	}
	
	chance = 10;
	kind = "kill";
	baitChance = 0;
	
	// humans get baited, cocky bots bait more
	if ( isplayer( victim ) && !victim is_bot() )
	{
		baitChance = getdvarint( "bots_real_bait" );
	}
	
	if ( self maps\mp\bots\_bot_realism::BotGetMood() == "cocky" )
	{
		baitChance += 25;
	}
	
	if ( randomint( 100 ) < baitChance )
	{
		message = modernLine( self getModernPool( "bait" ), victim.name );
		chance = 15;
		kind = "bait";
	}
	else if ( randomint( 100 ) < 40 )
	{
		message = modernLine( self getModernPool( "kill" ), victim.name );
	}
	
	wait ( randomint( 3 ) + 1 );
	self BotDoChat( chance, message, undefined, kind, victim );
}

/*
	Does death chat
*/
bot_chat_death_watch( killer, last_ks )
{
	self endon( "disconnect" );
	
	if ( !isdefined( killer ) || !isdefined( killer.name ) )
	{
		return;
	}
	
	message = "";
	
	switch ( randomint( 68 ) )
	{
		case 0:
			message = "damn, " + killer.name + " got me";
			break;
			
		case 1:
			message = ( "Hax ! Hax ! Hax !" );
			break;
			
		case 2:
			message = ( "nice shot " + killer.name );
			break;
			
		case 3:
			message = ( "How the?? How did you do that " + killer.name + "?" );
			break;
			
		case 4:
			if ( last_ks > 0 )
			{
				message = ( "Nooooooooo my killstreaks!! :( I had a " + last_ks + " killstreak!!" );
			}
			else
			{
				message = ( "man im getting spawn killed, i have a " + self.pers[ "cur_death_streak" ] + " deathstreak!" );
			}
			
			break;
			
		case 5:
			message = ( "Stop spawn KILLING!!!" );
			break;
			
		case 6:
			message = ( "Haha Well done " + killer.name );
			break;
			
		case 7:
			message = ( "Agggghhhh " + killer.name + " you are such a noob!!!!" );
			break;
			
		case 8:
			message = ( "n1 " + killer.name );
			break;
			
		case 9:
			message = ( "my ping is killing me" );
			break;
			
		case 10:
			message = ( "omg wow that was LEGENDARY, well done " + killer.name );
			break;
			
		case 11:
			message = ( "not my day" );
			break;
			
		case 12:
			message = ( "Aaaaaaaagh!!!" );
			break;
			
		case 13:
			message = ( "what the hell " + killer.name );
			break;
			
		case 14:
			message = ( killer.name + " you Wallhacker!" );
			break;
			
		case 15:
			message = ( "This is so frustrating!" );
			break;
			
		case 16:
			message = ( "i can't believe that just happened" );
			break;
			
		case 17:
			message = ( killer.name + " you noob" );
			break;
			
		case 18:
			message = ( "LOL, " + killer.name + " how did you kill me?" );
			break;
			
		case 19:
			message = ( "laaaaaaaaaaaaaaaaaaaag" );
			break;
			
		case 20:
			message = ( "i hate this map!" );
			break;
			
		case 21:
			message = ( killer.name + " is tanking everything" );
			break;
			
		case 22:
			message = ( "my internet is trash tonight" );
			break;
			
		case 23:
			message = ( "i'll be back" );
			break;
			
		case 24:
			message = ( "LoL that was random" );
			break;
			
		case 25:
			message = ( "ooohh that was so close " + killer.name + " and you know it !! " );
			break;
			
		case 26:
			message = ( "rofl" );
			break;
			
		case 27:
			message = ( "AAAAHHHHH! WTF! IM GOING TO KILL YOU " + killer.name );
			break;
			
		case 28:
			message = ( "AHH! IM DEAD BECAUSE " + level.players[ randomint( level.players.size ) ].name + " is a noob!" );
			break;
			
		case 29:
			message = ( level.players[ randomint( level.players.size ) ].name + ", please don't talk." );
			break;
			
		case 30:
			message = ( "Wow " + level.players[ randomint( level.players.size ) ].name + " is a blocker noob!" );
			break;
			
		case 31:
			message = ( "Next time GET OUT OF MY WAY " + level.players[ randomint( level.players.size ) ].name + "!!" );
			break;
			
		case 32:
			message = ( "Wow, I'm dead because " + killer.name + " is a tryhard..." );
			break;
			
		case 33:
			message = ( "Try harder " + killer.name + " please!" );
			break;
			
		case 34:
			message = ( "I bet " + killer.name + "'s fingers are about to break." );
			break;
			
		case 35:
			message = ( "WOW, USE A REAL GUN " + killer.name + "!" );
			break;
			
		case 36:
			message = ( "k wtf. " + killer.name + " is hacking" );
			break;
			
		case 37:
			message = ( "nice wallhacks " + killer.name );
			break;
			
		case 38:
			message = ( "wh " + killer.name );
			break;
			
		case 39:
			message = ( "cheater!" );
			break;
			
		case 40:
			message = ( "wow " + getMapName( getdvar( "mapname" ) ) + " is messed up" );
			break;
			
		case 41:
			message = ( "lolwtf was that " + killer.name + "?" );
			break;
			
		case 42:
			message = ( "admin pls ban " + killer.name );
			break;
			
		case 43:
			message = ( "WTF IS WITH THESE SPAWNS??" );
			break;
			
		case 44:
			message = ( "im getting owned lol..." );
			break;
			
		case 45:
			message = ( "someone kill " + killer.name + ", they are on a streak of " + killer.pers[ "cur_kill_streak" ] + "!" );
			break;
			
		case 46:
			message = ( "man i died" );
			break;
			
		case 47:
			message = ( "nice noob gun " + killer.name );
			break;
			
		case 48:
			message = ( "stop camping " + killer.name + "!" );
			break;
			
		case 49:
			message = ( "k THERE IS NOTHING I CAN DO ABOUT DYING!!" );
			break;
			
		case 50:
			message = ( "aw" );
			break;
			
		case 51:
			message = ( "lol " + getMapName( getdvar( "mapname" ) ) + " sux" );
			break;
			
		case 52:
			message = ( "why are we even playing on " + getMapName( getdvar( "mapname" ) ) + "?" );
			break;
			
		case 53:
			message = ( getMapName( getdvar( "mapname" ) ) + " is such an unfair map!!" );
			break;
			
		case 54:
			message = ( "what were they thinking when making " + getMapName( getdvar( "mapname" ) ) + "?!" );
			break;
			
		case 55:
			message = ( killer.name + " totally just destroyed me!" );
			break;
			
		case 56:
			message = ( "can i be admen plz? so i can ban " + killer.name );
			break;
			
		case 57:
			message = ( "wow " + killer.name + " is such a no life!!" );
			break;
			
		case 58:
			message = ( "man i got rekt by " + killer.name );
			break;
			
		case 59:
			message = ( "admen pls ben " + killer.name );
			break;
			
		case 60:
			if ( isdefined( self.attackerdata ) && isdefined( self.attackerdata[ killer.guid ] ) && isdefined( self.attackerdata[ killer.guid ].weapon ) )
			{
				message = "Wow! Nice " + getbaseweaponname( self.attackerdata[ killer.guid ].weapon ) + " you got there, " + killer.name + "!";
			}
			
			break;
			
		case 61:
			message = ( "you are so banned " + killer.name );
			break;
			
		case 62:
			message = ( "recorded reported and deported! " + killer.name );
			break;
			
		case 63:
			message = ( "hack name " + killer.name + "?" );
			break;
			
		case 64:
			message = ( "dude can you send me that hack " + killer.name + "?" );
			break;
			
		case 65:
			message = ( "nice aimbot " + killer.name + "!!1" );
			break;
			
		case 66:
			message = ( "you are benned " + killer.name + "!!" );
			break;
			
		case 67:
			message = ( "ok that was funny " + killer.name );
			break;
	}
	
	chance = 12;
	kind = undefined;
	
	if ( self maps\mp\bots\_bot_realism::BotGetMood() == "tilted" && randomint( 100 ) < getdvarint( "bots_real_rage" ) )
	{
		message = modernLine( self getModernPool( "rage" ), killer.name );
		chance = 25;
		kind = "rage";
	}
	else if ( self maps\mp\bots\_bot_realism::getTimesKilledBy( killer ) == 2 && getdvarint( "bots_real_banter" ) && randomint( 100 ) < 60 )
	{
		// the same player got us twice
		message = modernLine( self getBanterPool( "again" ), killer.name );
		chance = 25;
	}
	else if ( randomint( 100 ) < 40 )
	{
		message = modernLine( self getModernPool( "death" ), killer.name );
	}
	
	wait ( randomint( 3 ) + 1 );
	self BotDoChat( chance, message, undefined, kind, killer );
}

/*
	Revive
*/
bot_chat_revive_watch( state, revive, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i am going to revive " + revive.name );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i am reviving " + revive.name );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i revived " + revive.name );
					break;
			}
			
			break;
	}
}

/*
	Heard a noise (realism)
*/
bot_chat_hear_watch( state, kind, origin, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( state != "go" )
	{
		return;
	}
	
	if ( kind == "explosion" )
	{
		switch ( randomint( 2 ) )
		{
			case 0:
				self BotDoChat( 8, "explosion over there, checking it out", true );
				break;
				
			case 1:
				self BotDoChat( 8, "heard a nade go off, moving up", true );
				break;
		}
	}
	else
	{
		switch ( randomint( 3 ) )
		{
			case 0:
				self BotDoChat( 8, "shots fired near me", true );
				break;
				
			case 1:
				self BotDoChat( 8, "i hear gunfire, going to look", true );
				break;
				
			case 2:
				self BotDoChat( 8, "someone is shooting over here", true );
				break;
		}
	}
}

/*
	Falling back when hurt (realism)
*/
bot_chat_retreat_watch( state, danger, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 4 ) )
			{
				case 0:
					self BotDoChat( 12, "im hit, falling back!", true );
					break;
					
				case 1:
					self BotDoChat( 12, "need backup, low health", true );
					break;
					
				case 2:
					if ( isdefined( danger ) && isplayer( danger ) )
					{
						self BotDoChat( 12, danger.name + " almost got me, pulling back", true );
					}
					
					break;
					
				case 3:
					self BotDoChat( 12, "cover me!", true );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 5, "ok im good, going back in", true );
					break;
					
				case 1:
					self BotDoChat( 5, "healed up", true );
					break;
			}
			
			break;
	}
}

/*
	Mood changed (realism)
*/
bot_chat_mood_watch( mood, before, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	// half the time it's said in the bot's own era voice
	if ( randomint( 2 ) )
	{
		if ( mood == "tilted" )
		{
			self BotDoChat( 15, modernLine( self getModernPool( "rage" ) ), undefined, "rage" );
			return;
		}
		
		if ( mood == "cocky" )
		{
			self BotDoChat( 15, modernLine( self getModernPool( "bait" ) ), undefined, "bait" );
			return;
		}
	}
	
	switch ( mood )
	{
		case "cocky":
			switch ( randomint( 4 ) )
			{
				case 0:
					self BotDoChat( 15, "too easy" );
					break;
					
				case 1:
					self BotDoChat( 15, "im on fire right now" );
					break;
					
				case 2:
					self BotDoChat( 15, "who wants some next?" );
					break;
					
				case 3:
					self BotDoChat( 15, "you guys are making this easy" );
					break;
			}
			
			break;
			
		case "tilted":
			switch ( randomint( 4 ) )
			{
				case 0:
					self BotDoChat( 15, "this game is so rigged" );
					break;
					
				case 1:
					self BotDoChat( 15, "how do i keep dying" );
					break;
					
				case 2:
					self BotDoChat( 15, "ok im playing it slow now" );
					break;
					
				case 3:
					self BotDoChat( 15, "these spawns are ridiculous" );
					break;
			}
			
			break;
	}
}

/*
	Grudges (realism)
*/
bot_chat_grudge_watch( state, player, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !isdefined( player ) || !isplayer( player ) )
	{
		return;
	}
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 40, player.name + " you're mine" );
					break;
					
				case 1:
					self BotDoChat( 40, "ok " + player.name + ", this is personal now" );
					break;
					
				case 2:
					self BotDoChat( 40, "i'm coming for you " + player.name );
					break;
			}
			
			break;
			
		case "hunt":
			self BotDoChat( 10, "anyone seen " + player.name + "?", true );
			break;
			
		case "stop":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 50, "finally got you " + player.name );
					break;
					
				case 1:
					self BotDoChat( 50, "that's for earlier " + player.name );
					break;
					
				case 2:
					self BotDoChat( 50, "we're even now " + player.name );
					break;
			}
			
			break;
	}
}

/*
	Counter-picked a class (realism)
*/
bot_chat_counter_watch( state, category, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( category )
	{
		case "air":
			self BotDoChat( 20, "enough of the air support, grabbing a launcher", true );
			break;
			
		case "explosive":
			self BotDoChat( 20, "so many explosives, switching to sitrep", true );
			break;
			
		case "radar":
			self BotDoChat( 20, "their uav keeps finding me, going assassin", true );
			break;
			
		case "sniper":
			self BotDoChat( 20, "these snipers are annoying, changing class", true );
			break;
			
		case "close":
			self BotDoChat( 20, "they keep rushing me, changing class", true );
			break;
	}
}

/*
	Hiding from air support (realism)
*/
bot_chat_airhide_watch( state, b, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( state == "start" )
	{
		switch ( randomint( 2 ) )
		{
			case 0:
				self BotDoChat( 10, "enemy air support, get inside!", true );
				break;
				
			case 1:
				self BotDoChat( 10, "taking cover from that chopper", true );
				break;
		}
	}
}

/*
	Hot spots (realism)
*/
bot_chat_hotspot_watch( state, spot, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "new":
			if ( isdefined( spot ) && isdefined( spot.name ) )
			{
				switch ( randomint( 2 ) )
				{
					case 0:
						self BotDoChat( 30, "careful, " + spot.name + " is camping the same spot", true );
						break;
						
					case 1:
						self BotDoChat( 30, spot.name + " keeps killing us from the same place", true );
						break;
				}
			}
			
			break;
			
		case "nade":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 20, "nade out on that camping spot!", true );
					break;
					
				case 1:
					self BotDoChat( 20, "let's see if he's still sitting there", true );
					break;
			}
			
			break;
	}
}

/*
	Team intel (realism)
*/
bot_chat_intel_watch( state, enemy, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "spotted":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 20, "contact!", true );
					break;
					
				case 1:
					self BotDoChat( 20, "enemy spotted by me", true );
					break;
					
				case 2:
					if ( isdefined( enemy ) && isplayer( enemy ) )
					{
						self BotDoChat( 20, "got eyes on " + enemy.name, true );
					}
					
					break;
			}
			
			break;
			
		case "go":
			self BotDoChat( 10, "on my way", true );
			break;
	}
}

/*
	Match situation (realism)
*/
bot_chat_match_watch( state, enemies, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "clutch":
			if ( isdefined( enemies ) && enemies > 1 )
			{
				self BotDoChat( 60, "1v" + enemies + ", wish me luck" );
			}
			else
			{
				self BotDoChat( 60, "1v1, let's go" );
			}
			
			break;
			
		case "desperate":
			if ( level.teambased )
			{
				self BotDoChat( 15, "we need to push, we're losing!", true );
			}
			
			break;
			
		case "protective":
			if ( level.teambased )
			{
				self BotDoChat( 15, "we're ahead, play it safe", true );
			}
			
			break;
	}
}

/*
	Slip-ups (realism)
*/
bot_chat_slipup_watch( state, attacker, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( state == "surprised" )
	{
		switch ( randomint( 2 ) )
		{
			case 0:
				self BotDoChat( 8, "where did he come from?!" );
				break;
				
			case 1:
				self BotDoChat( 8, "who is behind me?!" );
				break;
		}
	}
}

/*
	Picks a line from a | separated pool and puts the name in for %n.
*/
modernLine( pool, name )
{
	lines = strtok( pool, "|" );
	
	// without a name, only use lines that don't need one
	if ( !isdefined( name ) )
	{
		nameless = [];
		
		for ( i = 0; i < lines.size; i++ )
		{
			if ( !issubstr( lines[ i ], "%n" ) )
			{
				nameless[ nameless.size ] = lines[ i ];
			}
		}
		
		lines = nameless;
		name = "";
	}
	
	line = random( lines );
	
	out = "";
	
	for ( i = 0; i < line.size; i++ )
	{
		if ( line[ i ] == "%" && i + 1 < line.size && line[ i + 1 ] == "n" )
		{
			out += name;
			i++;
			continue;
		}
		
		out += line[ i ];
	}
	
	return out;
}

/*
	The bot's chat generation: millennial, zoomer, alpha or boomer. Shapes its newer lines and typing style.
*/
getChatGen()
{
	if ( !isdefined( self.pers[ "bots" ][ "chatgen" ] ) )
	{
		roll = randomint( 100 );
		gen = "boomer";
		
		if ( roll < 30 )
		{
			gen = "millennial";
		}
		else if ( roll < 60 )
		{
			gen = "zoomer";
		}
		else if ( roll < 75 )
		{
			gen = "alpha";
		}
		
		self.pers[ "bots" ][ "chatgen" ] = gen;
	}
	
	return self.pers[ "bots" ][ "chatgen" ];
}

/*
	Newer chat lines for this bot's generation, | separated, %n becomes the other player's name.
	kind is kill, death, rage (tilted), bait (taunting), won, lost or start.
*/
getModernPool( kind )
{
	switch ( self getChatGen() )
	{
		case "millennial":
			switch ( kind )
			{
				case "kill":
					return "rekt|get rekt %n|owned|l2p %n|noob down|pwned|headshot!|that was epic|nice try|too slow|should've stayed in cover %n|unlucky %n|better luck next time %n|almost had me %n|one down|boom, headshot|epic win|git gud %n|ez mode|you just got served %n";
					
				case "death":
					return "lol what|epic fail|fml|ugh, lag|nice shot %n|ok %n is good|didn't see %n there|my aim is off tonight|that was cheap %n|facepalm|le sigh|this is fine|well played %n|the hit detection in this game|lag is real tonight|wtf was that|my controller is dying|i blame my isp|that was so cheap|noob tube, really %n?";
					
				case "rage":
					return "RAGE QUIT|this game is so broken|*throws controller*|unplugging my router brb|wtf wtf wtf|i swear this game hates me|alt f4 incoming|this is literally impossible|who designed these spawns|i'm done, i'm so done|my monitor is about to go out the window|FFFFFFFUUUUUUU";
					
				case "bait":
					return "u mad bro?|problem?|trolololo|cool story bro|i'm not even mad, that's amazing|y u no aim %n|all your base are belong to us|come at me bro|haters gonna hate %n|deal with it %n|%n, do you even lift?|go home %n, you're drunk|such skill, much wow|keep trying %n";
					
				case "won":
					return "gg|gg wp|epic win|#winning|owned|nice work team|good game everyone|gg, %n played well|that was awesome|that was fun";
					
				case "lost":
					return "gg|epic fail|fml|tough one|we'll get them next time|rematch?|%n played really well, gg|that one hurt|not our game";
					
				case "start":
					return "glhf|leeroy jenkins!|game on|let's do this|good luck everyone|stick together|no camping please|who's getting the uav";
			}
			
			break;
			
		case "zoomer":
			switch ( kind )
			{
				case "kill":
					return "diff|you're cooked %n|caught lacking|sit down %n|light work|no shot you peeked that|cooked|bro thought|%n is not him|packed up %n|ratio %n|that was clean ngl|W|it's giving free kill|%n fell off|bro really thought he was him|skill issue %n|touch grass %n|ez|%n got humbled";
					
				case "death":
					return "bro what|nah that's crazy|hitreg is cooked|who let %n cook|%n is cracked fr|i'm so washed|lag fr|bro is sweating in a pub|ok %n is him|not me whiffing that|L|that's actually insane %n|it's the ping bro|%n is lowkey goated|i'm throwing so hard rn|why is %n tryharding|bro i was lagging i swear|the servers are cooked|%n got that aimbot fr|i'm cooked";
					
				case "rage":
					return "i'm actually crashing out|this game is so rigged it's not even funny|uninstalling rn|bro i'm tweaking|nah i'm done fr|i'm about to throw my phone|this lobby is actually unplayable|who made these spawns bro|i'm literally shaking rn|i'm so tilted it's crazy|i can't with this game|bro i can't even";
					
				case "bait":
					return "skill issue|touch grass %n|ratio|you fell off %n|cope|stay mad %n|L + ratio + you fell off|cry about it %n|%n is playing on a smart fridge|imagine dying to me|%n is so mid|who asked %n|bro is washed|get better %n";
					
				case "won":
					return "W|dub|we cooked|team diff|gg ez|run it back?|W team|never in doubt|%n was goated|light work";
					
				case "lost":
					return "L|we got cooked|team diff tbh|we're so washed|they were sweating|run it back|gg go next|%n was cracked ngl|that was rough fr";
					
				case "start":
					return "glhf|lock in|let's cook|we ball|lock in team|don't throw this one|who's got uav";
			}
			
			break;
			
		case "alpha":
			switch ( kind )
			{
				case "kill":
					return "skibidi %n|that's -1000 aura %n|mogged|%n is so ohio|sigma move|fanum taxed %n|no rizz %n|+1000 aura|that was so sigma|you got mogged %n|%n is an npc|caught in 4k %n|%n got skibidi'd|that's so sigma of me|%n has zero aura|gg %n, go back to ohio|mewing while i did that|aura farming|%n got fanum taxed|sigma grindset";
					
				case "death":
					return "that's so ohio|-1000 aura for me|%n has crazy aura|%n mogged me|i'm not the sigma today|%n fanum taxed me|that's lowkey sus|my aura is gone|not very sigma of me|%n is so sigma|bro i was mewing|%n got that rizz|that was so skibidi|why is %n so sigma|i'm in ohio rn|%n is aura farming|i got mogged so hard|that's cap|no way %n|this is not sigma";
					
				case "rage":
					return "this game is so ohio|i'm telling my mom|that's not fair i'm reporting|i'm going back to roblox|this is so unfair skibidi|i'm crying fr|my mom said i can stay up and i'm losing|this game has no rizz|ohio ahh lobby|i'm gonna fanum tax your kills|not fair not fair not fair|i'm quitting and going to fortnite";
					
				case "bait":
					return "%n is an npc|%n has negative aura|go back to ohio %n|%n has no rizz|%n is a beta|L %n|%n is not sigma|%n got fanum taxed lol|that's -1000 aura for you %n|%n is so skibidi|imagine being %n|you're an npc|zero aura behavior|%n caught in 4k";
					
				case "won":
					return "sigma win|+1000 aura team|we're so sigma|skibidi win|we mogged them|%n has the most aura|gg sigmas";
					
				case "lost":
					return "-1000 aura|we're so ohio|that was so ohio|they mogged us|%n had crazy aura|no rizz this game|skibidi loss";
					
				case "start":
					return "let's get that aura|sigma mode on|skibidi time|no ohio plays please|time to mog";
			}
			
			break;
			
		case "boomer":
			switch ( kind )
			{
				case "kill":
					return "Got you, young man.|Better luck next time, %n.|Back in my day we aimed with iron sights.|Nice try, sport.|That's how it's done.|Gotcha!|You kids need to slow down.|Stay in school, %n.|I've been playing since before you were born.|That one's for the old timers.|Old man strength!|Not bad for a grandpa.|Don't worry, %n, you'll get it someday.|Experience beats reflexes.|I still got it!|Was that a camper? Got him.|Slow and steady, %n.|That's what we call patience.|Respect your elders, %n.|Take that, whippersnapper!";
					
				case "death":
					return "Who turned off the lights?|Where did that come from?|Nice shot, %n. Very nice.|I need my glasses for this.|These kids and their fancy guns.|How do I reload again?|Well, I'll be.|Good shot, young man.|In my day we had to walk to the respawn.|Fiddlesticks!|My hands aren't what they used to be.|Is this thing lagging or is it me?|Which button is jump?|Somebody call my grandson.|Oh, for crying out loud.|I was just adjusting my chair.|Hold on, my glasses fell off.|That's not very sportsmanlike, %n.|My reflexes aren't what they were.|Good grief.";
					
				case "rage":
					return "THIS GAME IS RIGGED.|I'm calling the manager.|In my day games were fair.|Somebody fix this computer.|I'm writing a strongly worded letter.|WHO IS IN CHARGE HERE?|I want to speak to the admin.|This is why I prefer checkers.|I'M TURNING THIS COMPUTER OFF.|Unbelievable. Absolutely unbelievable.|I pay for this internet!|That's it, I'm going to watch the news.";
					
				case "bait":
					return "Does your mother know you're up this late, %n?|Shouldn't you be doing homework, %n?|Kids these days.|I have socks older than you, %n.|Go outside and play, %n.|Is that the best your generation can do?|I've seen better aim at the bingo hall.|Back in my day we called that a warm-up.|Tell your parents I said hello, %n.|Bedtime, %n.|I've seen snails move faster, %n.|Get off my lawn, %n.|My cat plays better than you, %n.|Is this what they teach in school now?";
					
				case "won":
					return "Good game, everyone. Well played.|Nice teamwork, folks.|Good game. Now go do your homework.|Well done, team!|That's teamwork. Good job.|Thank you for the help, %n.|We did it, folks!";
					
				case "lost":
					return "Good game, everyone.|Well, we'll get them next time.|Good effort, team.|That %n is quite the player.|Back in my day we won those.|Time for my nap.|Good game. I'm going to bed.";
					
				case "start":
					return "Good luck, everyone. Have fun.|Hello, everyone!|Let's play nice now.|Remember to have fun, kids.|Who's ready?|Is this thing on?";
			}
			
			break;
	}
	
	return "gg";
}

/*
	Banter lines in the bot's era voice, | separated, %n becomes the other player's name.
	kind is console, comeback, jab, confused, cheer, again, mvp, quit or gtg.
*/
getBanterPool( kind )
{
	switch ( self getChatGen() )
	{
		case "millennial":
			switch ( kind )
			{
				case "console":
					return "shake it off|it happens, don't worry|we've all been there %n|deep breaths %n";
					
				case "comeback":
					return "lucky shot|enjoy it while it lasts %n|i'll get you next time %n|that was cheap %n";
					
				case "jab":
					return "ok boomer|ok grandpa|someone help grandpa find the fire button";
					
				case "confused":
					return "what?|i don't speak kid|was that english?";
					
				case "cheer":
					return "nice one %n|beast mode %n|%n is on fire|sick %n";
					
				case "again":
					return "you again %n?|%n again...|ok %n, that's twice now";
					
				case "mvp":
					return "gg %n, you were a beast|%n carried the whole lobby|%n is on another level";
					
				case "quit":
					return "rage quit, bye|i'm out|alt f4, peace";
					
				case "gtg":
					return "gg all, gotta go|that's it for me tonight, gg|gg, bed time";
			}
			
			break;
			
		case "zoomer":
			switch ( kind )
			{
				case "console":
					return "you're good bro|it's fine %n, lock in|shake it off fr|we move %n";
					
				case "comeback":
					return "you got lucky ngl|that was a fluke %n|run it back %n|enjoy it %n";
					
				case "jab":
					return "ok boomer|ok grandpa|who let grandpa on the computer|grandpa is actually cooked";
					
				case "confused":
					return "what|huh|nobody asked grandpa";
					
				case "cheer":
					return "W %n|%n is him|%n cooking|%n went crazy";
					
				case "again":
					return "%n again bro|%n is farming me|not %n again";
					
				case "mvp":
					return "%n was him this game|%n diffed the whole lobby|gg %n you were cracked";
					
				case "quit":
					return "i'm done, bye|uninstalling fr|nah i'm out";
					
				case "gtg":
					return "gg gotta dip|i'm out, gg|gg ima head out";
			}
			
			break;
			
		case "alpha":
			switch ( kind )
			{
				case "console":
					return "you still have aura %n|it's ok, don't be ohio|stay sigma %n|you'll get your aura back";
					
				case "comeback":
					return "that was so ohio of you %n|lucky aura|you won't be sigma for long %n|%n used aura hacks";
					
				case "jab":
					return "ok boomer|grandpa is so ohio|%n has old man aura|grandpa has no rizz";
					
				case "confused":
					return "what|that's so boomer|ok boomer";
					
				case "cheer":
					return "%n is so sigma|+1000 aura %n|%n mogged him|%n has crazy aura";
					
				case "again":
					return "%n again?? so ohio|%n is aura farming off me|not %n again";
					
				case "mvp":
					return "%n had infinite aura|%n is the ultimate sigma|%n mogged everyone";
					
				case "quit":
					return "i'm telling my mom, bye|going back to roblox|bye this game is ohio";
					
				case "gtg":
					return "my mom says i have to go to bed|gg, dinner time|gg sigmas, bye";
			}
			
			break;
			
		case "boomer":
			switch ( kind )
			{
				case "console":
					return "Chin up, sport.|Don't let it get to you, %n.|Deep breaths, young man.|It's just a game, %n.";
					
				case "comeback":
					return "Beginner's luck.|I'll get you next time, %n.|Don't get cocky, young man.|Enjoy it while it lasts.";
					
				case "jab":
					return "Back in my day we respected our elders.";
					
				case "confused":
					return "What in the world is a skibidi?|Speak English, young man.|What does that even mean, %n?|Kids today and their words.";
					
				case "cheer":
					return "Nice shooting, %n!|Well done, %n.|Attaboy, %n!|Now that's how it's done, %n.";
					
				case "again":
					return "Not you again, %n.|%n, we meet again.|You again, young man?";
					
				case "mvp":
					return "Very impressive, %n.|That %n fellow plays quite well.|Well played, %n. Very well played.";
					
				case "quit":
					return "That's it, I'm done.|I'm turning this thing off.|I've had enough of this.";
					
				case "gtg":
					return "Goodnight, everyone.|Good game, folks. Time for bed.|I'm going to bed. Good game.";
			}
			
			break;
	}
	
	return "gg";
}

/*
	Lines for special kills. state is brag (the killer) or complain (the victim).
*/
getSpecialKillPool( state, type )
{
	if ( state == "brag" )
	{
		switch ( type )
		{
			case "knife":
				return "knifed|shh, knife|stabbed %n|nothing personal %n|should've brought a knife %n";
				
			case "throwingknife":
				return "throwing knife!!|yeah i threw that|did you see that knife?|knife to the face %n";
				
			case "headshot":
				return "headshot|right between the eyes|boom, headshot|clean headshot %n";
				
			case "longshot":
				return "from across the map|long range special|did you see the distance on that|from way over here %n";
				
			case "double":
				return "double kill!|two for one|double!";
				
			case "triple":
				return "triple kill!!|three at once|triple!";
				
			case "streakend":
				return "ended your streak %n|streak's over %n|there goes your streak %n";
				
			case "revenge":
				return "revenge|payback %n|told you i'd be back %n|we're even %n";
		}
	}
	else
	{
		switch ( type )
		{
			case "knife":
				return "knifed?? really|lunge is so broken|did he just stab me|%n and that knife...";
				
			case "throwingknife":
				return "a throwing knife? are you serious|how did that knife hit|%n threw a knife at me lol";
				
			case "headshot":
				return "one tapped|nice headshot %n|right in the head...";
				
			case "longshot":
				return "from where??|across the whole map?|%n is sniping from another zip code";
				
			case "double":
				return "got caught in that one";
				
			case "triple":
				return "wow, %n got all of us";
				
			case "streakend":
				return "there goes my streak|noooo my streak|%n ended my streak...";
				
			case "revenge":
				return "ok ok, we're even %n|fair enough %n";
		}
	}
	
	return undefined;
}

/*
	Other bots sometimes answer what a bot just said. Answers never get answered, so it can't spiral.
*/
banterListener()
{
	for ( ;; )
	{
		level waittill( "bots_real_said", speaker, kind, target );
		
		if ( !getdvarint( "bots_real_banter" ) || !isdefined( speaker ) || ( isdefined( kind ) && ( kind == "reply" || kind == "flame" || kind == "flamecaps" ) ) )
		{
			continue;
		}
		
		level thread banterRespond( speaker, kind, target );
	}
}

/*
	A random bot that isn't the speaker. team: "same", "other" or undefined for anyone.
	gens: comma separated chat generations to pick from, undefined for any.
*/
pickBanterBot( speaker, team, gens )
{
	candidates = [];
	
	for ( i = 0; i < level.players.size; i++ )
	{
		bot = level.players[ i ];
		
		if ( bot == speaker || !bot is_bot() || !isdefined( bot.pers[ "bots" ] ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( isdefined( team ) && level.teambased )
		{
			if ( team == "same" && bot.team != speaker.team )
			{
				continue;
			}
			
			if ( team == "other" && bot.team == speaker.team )
			{
				continue;
			}
		}
		
		if ( isdefined( gens ) && !issubstr( gens, bot getChatGen() ) )
		{
			continue;
		}
		
		candidates[ candidates.size ] = bot;
	}
	
	return random( candidates );
}

/*
	Decides whether anyone answers, who, and with what.
*/
banterRespond( speaker, kind, target )
{
	responder = undefined;
	pool = undefined;
	name = speaker.name;
	
	if ( !isdefined( kind ) )
	{
		kind = "";
	}
	
	roll = randomint( 100 );
	
	switch ( kind )
	{
		case "rage":
			// a teammate calms them down, or an enemy rubs it in
			if ( roll < 40 )
			{
				responder = pickBanterBot( speaker, "same" );
				
				if ( isdefined( responder ) )
				{
					pool = responder getBanterPool( "console" );
				}
			}
			else if ( roll < 70 )
			{
				responder = pickBanterBot( speaker, "other" );
				
				if ( isdefined( responder ) && getdvarint( "bots_real_flame" ) > 0 && flameWarAvailable() && randomint( 100 ) < getdvarint( "bots_real_flame" ) )
				{
					responder thread flameWar( speaker );
					return;
				}
				
				if ( isdefined( responder ) )
				{
					pool = responder getModernPool( "bait" );
				}
			}
			
			break;
			
		case "kill":
			// the bot that got killed fires back
			if ( isdefined( target ) && isplayer( target ) && target is_bot() && isdefined( target.pers[ "bots" ] ) && roll < 30 )
			{
				responder = target;
				pool = responder getBanterPool( "comeback" );
			}
			
			break;
			
		case "brag":
			// party mates cheer first, other teammates sometimes
			mates = speaker maps\mp\bots\_bot_realism::getPartyMates();
			
			if ( mates.size && roll < 60 )
			{
				responder = random( mates );
			}
			else if ( roll < 15 )
			{
				responder = pickBanterBot( speaker, "same" );
			}
			
			if ( isdefined( responder ) )
			{
				pool = responder getBanterPool( "cheer" );
			}
			
			break;
	}
	
	// the generations poke fun at each other
	if ( !isdefined( responder ) )
	{
		gen = speaker getChatGen();
		
		if ( gen == "boomer" && roll < 15 )
		{
			responder = pickBanterBot( speaker, undefined, "zoomer,alpha" );
			
			if ( isdefined( responder ) )
			{
				pool = responder getBanterPool( "jab" );
			}
		}
		else if ( ( gen == "zoomer" || gen == "alpha" ) && roll < 10 )
		{
			responder = pickBanterBot( speaker, undefined, "boomer" );
			
			if ( isdefined( responder ) )
			{
				pool = responder getBanterPool( "confused" );
			}
		}
	}
	
	if ( !isdefined( responder ) || !isdefined( pool ) )
	{
		return;
	}
	
	wait randomfloatrange( 1.5, 3 );
	
	if ( !isdefined( responder ) || !isdefined( speaker ) )
	{
		return;
	}
	
	responder BotDoChat( 100, modernLine( pool, name ), undefined, "reply" );
}

/*
	Flame war lines in the bot's era voice. kind is flame, meltdown (all caps), pile (bystanders) or bail (ending it).
*/
getFlamePool( kind )
{
	switch ( self getChatGen() )
	{
		case "millennial":
			switch ( kind )
			{
				case "flame":
					return "%n you're so bad it's actually impressive|%n uninstall|%n i've seen stormtroopers aim better|cry more %n|%n mad cuz bad|%n is the reason shampoo has instructions|keyboard warrior %n|%n you peaked in 2009|sit down %n, adults are talking|%n reported for being bad|%n your k/d is a cry for help|%n go back to hello kitty island";
					
				case "meltdown":
					return "1V1 ME ON RUST NO SCOPES %n|I WILL FIND YOU %n|%n MEET ME ON RUST|UR SO BAD %n|OMG SHUT UP %n|I'M SCREENSHOTTING THIS %n|%n BLOCKED REPORTED DELETED|THIS IS WHY I QUIT HALO";
					
				case "pile":
					return "lol|ooooh|get rekt %n|grab the popcorn|this is better than the match|someone clip this|%n just got roasted";
					
				case "bail":
					return "whatever, muted|k|not reading all that|cool story, blocked";
			}
			
			break;
			
		case "zoomer":
			switch ( kind )
			{
				case "flame":
					return "%n you're actually so mid|%n is the npc of this lobby|ratio + %n fell off + nobody asked|%n plays with a steering wheel|%n is so washed it's crazy|%n stay mad|bro %n is down astronomical|%n your aim is on airplane mode|%n got negative game sense|not %n yapping|%n is literally a bot|%n go touch grass fr";
					
				case "meltdown":
					return "1V1 ME RN %n|%n BRO IS YAPPING|NAH %n IS ACTUALLY TWEAKING|I'M CLIPPING THIS %n|%n YOU'RE COOKED FR FR|ON GOD %n IS WASHED|BRO I'M CRASHING OUT ON %n|%n SAY THAT AGAIN";
					
				case "pile":
					return "chat is this real|bro got cooked|%n is getting violated|lmaooo|not the flame war|this is cinema|%n is not recovering from this";
					
				case "bail":
					return "ok and?|muted lol|cope + muted|not reading allat";
			}
			
			break;
			
		case "alpha":
			switch ( kind )
			{
				case "flame":
					return "%n is so ohio it's crazy|%n has -10000 aura|%n is a skibidi toilet|%n got zero rizz and zero aim|%n is the biggest npc|%n got fanum taxed by the whole lobby|%n is not sigma, %n is beta|%n smells like ohio|%n's aura is in debt|mogged, %n. mogged.|%n plays like a roblox noob|%n go back to toca boca";
					
				case "meltdown":
					return "%n I'M TELLING MY MOM|%n IS SO OHIO|MY DAD WORKS AT ACTIVISION %n|%n -1 MILLION AURA|SKIBIDI %n SKIBIDI|%n I'M GONNA FANUM TAX YOUR HOUSE|%n YOU'RE ADOPTED|%n I HAVE 1000 ROBUX AND YOU HAVE NOTHING";
					
				case "pile":
					return "this is so ohio|%n lost all their aura|chat is this skibidi|sigma fight|W drama|%n got mogged in chat too";
					
				case "bail":
					return "blocked|i'm telling my mom (again)|ok bye npc|you're not even sigma, bye";
			}
			
			break;
			
		case "boomer":
			switch ( kind )
			{
				case "flame":
					return "Listen here, %n, I've been gaming since Pong.|%n, your parents must be so proud.|In my day we'd call you a bum, %n.|%n couldn't hit the broad side of a barn.|Go to your room, %n.|%n, I've got grandchildren better than you.|Mind your manners, %n.|%n, you're grounded.|I'm calling your mother, %n.|Pathetic, %n. Absolutely pathetic.|%n, you play like you're wearing oven mitts.|%n, this is why nobody sends you birthday cards.";
					
				case "meltdown":
					return "THAT'S IT, %n. OUTSIDE. NOW.|I'LL HAVE YOU KNOW I SERVED, %n.|%n, I'M WRITING TO YOUR CONGRESSMAN.|I WANT TO SPEAK TO %n'S MANAGER.|YOU KIDS GET OFF MY SERVER.|%n, I WILL TURN THIS CAR AROUND.|DON'T MAKE ME COME OVER THERE, %n.|BACK IN MY DAY WE SETTLED THIS WITH FISTICUFFS, %n.";
					
				case "pile":
					return "Boys, boys, settle down.|Now, now, play nice.|Is this what they call a flame war?|Somebody call a moderator.|In my day we shook hands.|Language, gentlemen.";
					
				case "bail":
					return "I'm done talking to you.|Goodnight.|I don't have to take this.|I'm going to bed.";
			}
			
			break;
	}
	
	return "lol";
}

/*
	Starts a flame war with another bot if the dice say so. Returns true if one started.
*/
maybeStartFlameWar( other )
{
	if ( !getdvarint( "bots_real_banter" ) || !isdefined( other ) || !isplayer( other ) || !other is_bot() || !isdefined( other.pers[ "bots" ] ) )
	{
		return false;
	}
	
	chance = getdvarint( "bots_real_flame" );
	
	if ( chance <= 0 )
	{
		return false;
	}
	
	if ( self maps\mp\bots\_bot_realism::BotGetMood() == "cocky" )
	{
		chance += 20;
	}
	
	// bad blood makes it personal
	myGrudge = self maps\mp\bots\_bot_realism::getGrudgeName();
	theirGrudge = other maps\mp\bots\_bot_realism::getGrudgeName();
	
	if ( ( isdefined( myGrudge ) && myGrudge == other.name ) || ( isdefined( theirGrudge ) && theirGrudge == self.name ) )
	{
		chance += 30;
	}
	
	if ( randomint( 100 ) >= chance || !flameWarAvailable() )
	{
		return false;
	}
	
	self thread flameWar( other );
	return true;
}

/*
	One flame war at a time, with a short breather in between.
*/
flameWarAvailable()
{
	// a war whose bot disconnected mid-way never clears the flag, so a minute counts as over
	if ( isdefined( level.bots_flamewar ) && level.bots_flamewar && !maps\mp\bots\_bot_realism::timeSince( level.bots_flamewar_start, 60000 ) )
	{
		return false;
	}
	
	return maps\mp\bots\_bot_realism::timeSince( level.bots_flamewar_time, 15000 );
}

/*
	Two bots go back and forth: taunt, flame, all caps meltdown, sometimes someone bails.
	Bystanders pile on. Afterwards they hold a grudge against each other.
*/
flameWar( other )
{
	if ( !flameWarAvailable() )
	{
		return;
	}
	
	level.bots_flamewar = true;
	level.bots_flamewar_start = gettime();
	
	speaker = self;
	target = other;
	length = randomintrange( 3, 7 );
	
	// really heated lobbies go longer
	if ( getdvarint( "bots_real_flame" ) >= 70 )
	{
		length = randomintrange( 5, 10 );
	}
	
	for ( i = 0; i < length; i++ )
	{
		if ( !isdefined( speaker ) || !isdefined( target ) || level.gameended )
		{
			break;
		}
		
		kind = "flame";
		
		if ( i == 0 )
		{
			pool = speaker getModernPool( "bait" );
		}
		else if ( i == length - 1 && i > 2 && randomint( 100 ) < 40 )
		{
			pool = speaker getFlamePool( "bail" );
		}
		else if ( i >= length / 2 )
		{
			pool = speaker getFlamePool( "meltdown" );
			kind = "flamecaps";
		}
		else
		{
			pool = speaker getFlamePool( "flame" );
		}
		
		speaker BotDoChat( 100, modernLine( pool, target.name ), undefined, kind );
		
		// the crowd gets involved
		if ( randomint( 100 ) < 30 )
		{
			level thread flameBystander( speaker, target );
		}
		
		wait randomfloatrange( 3.2, 4.5 );
		
		temp = speaker;
		speaker = target;
		target = temp;
	}
	
	// it carries over into the game: they go hunting each other
	if ( isdefined( self ) && isdefined( other ) )
	{
		self maps\mp\bots\_bot_realism::setGrudgeAgainst( other );
		other maps\mp\bots\_bot_realism::setGrudgeAgainst( self );
	}
	
	level.bots_flamewar = false;
	level.bots_flamewar_time = gettime();
}

/*
	A bot watching the flame war chimes in about the one on the receiving end.
*/
flameBystander( speaker, target )
{
	bystander = undefined;
	
	for ( tries = 0; tries < 4 && !isdefined( bystander ); tries++ )
	{
		pick = pickBanterBot( speaker );
		
		if ( isdefined( pick ) && isdefined( target ) && pick != target )
		{
			bystander = pick;
		}
	}
	
	if ( !isdefined( bystander ) )
	{
		return;
	}
	
	wait randomfloatrange( 1.8, 2.6 );
	
	if ( !isdefined( bystander ) || !isdefined( target ) )
	{
		return;
	}
	
	bystander BotDoChat( 100, modernLine( bystander getFlamePool( "pile" ), target.name ), undefined, "flame" );
}

/*
	Lines for reacting to the match and to players, | separated.
	%n is a player's name, %w a weapon, %f a flag letter.
*/
getReactPool( kind )
{
	gen = self getChatGen();
	
	switch ( kind )
	{
		case "greet":
			switch ( gen )
			{
				case "millennial":
					return "hey %n|welcome %n|sup %n|yo %n, welcome to the lobby";
					
				case "zoomer":
					return "yo %n|%n pulled up|w %n|hey %n";
					
				case "alpha":
					return "hi %n|%n joined the sigma lobby|welcome %n, don't be ohio|yo %n";
					
				case "boomer":
					return "Welcome, %n!|Hello there, %n.|Good evening, %n. Grab a seat.|Ah, a new face. Hello, %n.";
			}
			
			break;
			
		case "bye":
			switch ( gen )
			{
				case "millennial":
					return "bye %n|cya %n|rage quit?|%n left lol";
					
				case "zoomer":
					return "%n dipped|bro left|%n rage quit fr|cya %n";
					
				case "alpha":
					return "%n left, so ohio|bye %n|%n got scared|-1000 aura for leaving %n";
					
				case "boomer":
					return "Goodbye, %n.|Drive safe, %n.|And there goes %n.|Was it something I said?";
			}
			
			break;
			
		case "convo":
			switch ( gen )
			{
				case "millennial":
					return "lol true|yeah|for real|haha|agreed|no way|lol same|that's what i'm saying";
					
				case "zoomer":
					return "fr|real|no cap|bet|true|facts|lowkey yeah|ong";
					
				case "alpha":
					return "fr fr|no cap|sigma|bet|real|facts|that's so true";
					
				case "boomer":
					return "Indeed.|I see.|Is that so?|Quite right.|Hmm.|Fair enough.|You don't say.";
			}
			
			break;
			
		case "question":
			switch ( gen )
			{
				case "millennial":
					return "idk|no idea|maybe?|good question|ask google lol|ask someone else lol";
					
				case "zoomer":
					return "idk bro|no clue|maybe|who knows|idk fr";
					
				case "alpha":
					return "idk|ask skibidi|no clue fr|maybe, idk";
					
				case "boomer":
					return "I couldn't tell you, %n.|Beats me.|Ask my grandson.|I'm not sure, young man.";
			}
			
			break;
			
		case "ambient":
			switch ( gen )
			{
				case "millennial":
					return "anyone else lagging?|this map brings back memories|who's got the uav|i miss mw2 lobbies|this lobby is actually fun|brb getting a drink|gg so far";
					
				case "zoomer":
					return "this lobby is goated|who's actually cracked here|ngl this map is mid|my fps is dying|chat is this game fun|lowkey having fun";
					
				case "alpha":
					return "who's the sigma of this lobby|this map is so ohio|i'm aura farming rn|who wants to 1v1|my mom said 10 more minutes";
					
				case "boomer":
					return "Does anyone know how to turn off the music?|My grandson set this up for me.|Lovely weather on this map.|Is this the one with the helicopters?|Back in my day games came on cartridges.";
			}
			
			break;
			
		case "askhuman":
			switch ( gen )
			{
				case "millennial":
					return "%n how are you so good|%n what's your k/d|%n carry me pls|%n are you even trying lol|%n what class are you running?";
					
				case "zoomer":
					return "%n you're actually cracked|%n what's your sens|%n carry me fr|%n are you a pro or what|%n why are you so sweaty";
					
				case "alpha":
					return "%n are you sigma?|%n what's your aura level|%n are you on roblox too|%n carry me pls";
					
				case "boomer":
					return "%n, how do you do it?|%n, do your parents know you're this good?|%n, any tips for an old timer?|%n, are you one of those streamers?";
			}
			
			break;
			
		case "streak_enemy":
			switch ( gen )
			{
				case "millennial":
					return "someone stop %n|%n is on a rampage|%n is on a streak, focus him|how is %n still alive";
					
				case "zoomer":
					return "%n is cooking us|somebody kill %n pls|%n is actually him|we're getting farmed by %n";
					
				case "alpha":
					return "%n has infinite aura|%n is too sigma|stop %n pls|%n is aura farming us";
					
				case "boomer":
					return "Somebody stop that %n!|That %n is on a tear.|Where is %n getting all these kills?|Can't anyone get %n?";
			}
			
			break;
			
		case "streak_team":
			switch ( gen )
			{
				case "millennial":
					return "go %n!|%n is carrying|nice streak %n|beast mode %n";
					
				case "zoomer":
					return "W %n|%n is him|%n carrying fr|%n diff";
					
				case "alpha":
					return "%n is so sigma|+1000 aura %n|%n is mogging them|%n carry us";
					
				case "boomer":
					return "Well done, %n!|Keep it up, %n.|That's the spirit, %n!|Atta boy, %n!";
			}
			
			break;
			
		case "tease":
			switch ( gen )
			{
				case "millennial":
					return "%n is having a rough day|%n maybe try a different class|free kills from %n|%n is our favourite player";
					
				case "zoomer":
					return "%n is getting farmed|%n is down bad|%n's k/d is crying|%n please log off";
					
				case "alpha":
					return "%n has no aura left|%n is so ohio rn|%n needs a sigma class|%n is an npc today";
					
				case "boomer":
					return "Hang in there, %n. Or don't.|%n, maybe try checkers.|Rough night, %n?|Practice makes perfect, %n.";
			}
			
			break;
			
		case "console":
			switch ( gen )
			{
				case "millennial":
					return "you got this %n|unlucky %n, keep going|shake it off %n|they're just camping %n";
					
				case "zoomer":
					return "you're good %n|lock in %n you got this|it's fine %n|next life %n";
					
				case "alpha":
					return "you still have aura %n|stay sigma %n|you got this %n|comeback arc %n";
					
				case "boomer":
					return "Chin up, %n.|Keep at it, %n.|Don't give up, %n.|We've all been there, %n.";
			}
			
			break;
			
		case "firstblood":
			switch ( gen )
			{
				case "millennial":
					return "first blood %n|and %n gets first blood|first blood!";
					
				case "zoomer":
					return "%n got first blood|first blood W|%n opened it up";
					
				case "alpha":
					return "%n got first blood, sigma|first blood aura|%n started it";
					
				case "boomer":
					return "First blood goes to %n.|And we're off!|Well, that didn't take long.";
			}
			
			break;
			
		case "multikill":
			switch ( gen )
			{
				case "millennial":
					return "did %n just get a triple?|%n wtf|%n is insane";
					
				case "zoomer":
					return "%n just wiped them|nah %n is crazy|%n is actually him";
					
				case "alpha":
					return "%n mogged three people|%n has crazy aura|%n is the sigma";
					
				case "boomer":
					return "Goodness, %n!|Did you see that, %n?|My word, %n.";
			}
			
			break;
			
		case "uav_enemy":
			return "they have a uav up|enemy uav, watch out|their uav is up, stay quiet|uav up, someone shoot it";
			
		case "uav_team":
			return "nice uav %n|thanks for the uav %n|uav up|good uav";
			
		case "air_enemy":
			return "%n's air support is up, get inside|who called that in?|%n has air support up|air support incoming, find cover";
			
		case "air_team":
			return "nice streak %n|thanks for the support %n|%n's got air support up|let's go %n";
			
		case "flag_ours":
			return "we got %f|%f is ours|took %f|%f captured|we got a flag";
			
		case "flag_lost":
			return "they took %f|we lost %f|%f is gone, someone retake it|they have %f|they took one of our flags";
			
		case "bomb_att":
			return "bomb's planted, defend it|bomb down, hold it|planted, cover the bomb";
			
		case "bomb_def":
			return "bomb's down, defuse it|they planted, go go go|someone defuse!";
			
		case "defused_def":
			return "defused!|nice defuse|phew, defused";
			
		case "defused_att":
			return "they defused it|no way they defused that|ugh, defused";
			
		case "ctf_lost":
			return "they have our flag|%n has our flag, stop him|flag's gone, get it back";
			
		case "ctf_took":
			return "we have their flag|%n has their flag, cover him|flag taken, escort %n";
			
		case "hq_ours":
			return "hq is ours|we got the hq|hold the hq";
			
		case "hq_lost":
			return "they have the hq|they took the hq|get the hq back";
			
		case "lead_gained":
			return "we're ahead now|we took the lead|keep it up, we're winning";
			
		case "lead_lost":
			return "they took the lead|we're behind, pick it up|come on, they're winning now";
			
		case "minute_left":
			return "one minute left|last minute, let's go|a minute left, push";
			
		case "thanks":
			return "np|no problem|anytime|you're welcome";
			
		case "sorry":
			return "all good|np|it happens|no worries";
			
		case "wtf":
			return "ikr|lol what|right?|same reaction";
			
		case "lag":
			return "same|lag is real today|it's the servers|my ping is crying too";
			
		case "camper":
			return "says the camper|i'm not camping, i'm holding an angle|camping is a strategy|who's camping?";
			
		case "oneonone":
			return "bet|anytime|1v1 me on rust|you'd lose";
			
		case "report":
			return "for what lol|go ahead|report me for being good?";
			
		case "help":
			return "on my way|where?|coming";
			
		case "nicegame":
			return "thanks|you too|appreciate it|wp";
			
		case "rip":
			return "rip|f|rip lol";
			
		case "weapon_shotgun":
			return "shotguns in this game are broken|nice %w %n, real skillful|%n and that %w...|of course it's a shotgun";
			
		case "weapon_sniper":
			return "quickscoped by %n|%n with the sniper again|nice shot %n|%n is sniping all game";
			
		case "weapon_launcher":
			return "a %w? really %n|noob tube!!|explosives, of course|%n just blew me up";
			
		case "weapon_riot":
			return "killed by a riot shield. great.|%n and that shield...|riot shield? seriously?";
			
		case "weapon_lmg":
			return "%n is spraying with the %w|that %w is so broken|lmg spam from %n again";
			
		case "weapon_smg":
			return "that %w is so broken|%n's %w shreds|smgs in this game man";
			
		case "weapon_pistol":
			return "a pistol?? come on %n|killed by a %w lol";
			
		case "weapon_assault":
			return "nice %w %n|%n's %w is cracked|that %w hits hard";
			
		case "brag_weapon":
			return "my %w never misses|this %w is so good|love this %w|%w on top";
	}
	
	return undefined;
}

/*
	How talkative this bot is: quiet bots chat less, yappers chat more.
*/
getChattiness()
{
	if ( !isdefined( self.pers[ "bots" ] ) )
	{
		return 1;
	}
	
	if ( !isdefined( self.pers[ "bots" ][ "chattiness" ] ) )
	{
		roll = randomint( 100 );
		chatty = 1;
		
		if ( roll < 25 )
		{
			chatty = 0.4;
		}
		else if ( roll >= 75 )
		{
			chatty = 2;
		}
		
		self.pers[ "bots" ][ "chattiness" ] = chatty;
	}
	
	return self.pers[ "bots" ][ "chattiness" ];
}

/*
	Picks a line from a | separated pool and fills in %n (name), %w (weapon) and %f (flag).
	Lines needing something that isn't given are skipped. Returns undefined if nothing fits.
*/
fillLine( pool, name, weap, flagName )
{
	if ( !isdefined( pool ) )
	{
		return undefined;
	}
	
	all = strtok( pool, "|" );
	lines = [];
	
	for ( i = 0; i < all.size; i++ )
	{
		if ( !isdefined( name ) && issubstr( all[ i ], "%n" ) )
		{
			continue;
		}
		
		if ( !isdefined( weap ) && issubstr( all[ i ], "%w" ) )
		{
			continue;
		}
		
		if ( !isdefined( flagName ) && issubstr( all[ i ], "%f" ) )
		{
			continue;
		}
		
		lines[ lines.size ] = all[ i ];
	}
	
	if ( !lines.size )
	{
		return undefined;
	}
	
	line = random( lines );
	out = "";
	
	for ( i = 0; i < line.size; i++ )
	{
		if ( line[ i ] == "%" && i + 1 < line.size )
		{
			if ( line[ i + 1 ] == "n" )
			{
				out += name;
				i++;
				continue;
			}
			
			if ( line[ i + 1 ] == "w" )
			{
				out += weap;
				i++;
				continue;
			}
			
			if ( line[ i + 1 ] == "f" )
			{
				out += flagName;
				i++;
				continue;
			}
		}
		
		out += line[ i ];
	}
	
	return out;
}

/*
	A random bot, optionally only on one team and never the excluded player.
*/
pickChatBot( team, exclude )
{
	candidates = [];
	
	for ( i = 0; i < level.players.size; i++ )
	{
		bot = level.players[ i ];
		
		if ( !bot is_bot() || !isdefined( bot.pers[ "bots" ] ) || !isdefined( bot.team ) )
		{
			continue;
		}
		
		if ( isdefined( exclude ) && bot == exclude )
		{
			continue;
		}
		
		if ( isdefined( team ) && level.teambased && bot.team != team )
		{
			continue;
		}
		
		candidates[ candidates.size ] = bot;
	}
	
	return random( candidates );
}

/*
	Gets a bot (from a team if given) to react with a line from the pool, chance scaled by how talkative it is.
*/
reactSay( kind, team, name, weap, flagName, chance, isTeam, exclude )
{
	if ( !getdvarint( "bots_real_reactive" ) || getdvarfloat( "bots_main_chat" ) <= 0 )
	{
		return;
	}
	
	bot = pickChatBot( team, exclude );
	
	if ( !isdefined( bot ) )
	{
		return;
	}
	
	if ( randomint( 100 ) >= chance * bot getChattiness() * getdvarfloat( "bots_main_chat" ) )
	{
		return;
	}
	
	line = fillLine( bot getReactPool( kind ), name, weap, flagName );
	
	if ( !isdefined( line ) )
	{
		return;
	}
	
	bot thread reactSpeak( line, isTeam );
}

/*
	Says a line after a human-like pause.
*/
reactSpeak( line, isTeam )
{
	self endon( "disconnect" );
	
	wait randomfloatrange( 0.8, 2.2 );
	self BotDoChat( 100, line, isTeam, "reply" );
}

/*
	The other team, undefined in free for all.
*/
otherTeamOf( team )
{
	if ( !level.teambased || !isdefined( team ) || !isdefined( level.otherteam[ team ] ) )
	{
		return undefined;
	}
	
	return level.otherteam[ team ];
}

/*
	Short weapon name for chat, like "acr" for iw5_acr_mp_reflex.
*/
chatWeaponName( weapon )
{
	if ( !isdefined( weapon ) || weapon == "none" || weapon == "" )
	{
		return undefined;
	}
	
	if ( issubstr( weapon, "alt_" ) )
	{
		return "noob tube";
	}
	
	name = getbaseweaponname( weapon );
	
	if ( isStrStart( name, "iw5_" ) )
	{
		name = getsubstr( name, 4, name.size );
	}
	
	return name;
}

/*
	Which weapon complaint fits the weapon that did the killing.
*/
getWeaponTalkKind( weapon, sMeansOfDeath )
{
	if ( !isdefined( weapon ) )
	{
		return undefined;
	}
	
	if ( issubstr( weapon, "alt_" ) || sMeansOfDeath == "MOD_PROJECTILE" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH" )
	{
		return "weapon_launcher";
	}
	
	switch ( getweaponclass( weapon ) )
	{
		case "weapon_shotgun":
			return "weapon_shotgun";
			
		case "weapon_sniper":
			return "weapon_sniper";
			
		case "weapon_projectile":
			return "weapon_launcher";
			
		case "weapon_riot":
			return "weapon_riot";
			
		case "weapon_lmg":
			return "weapon_lmg";
			
		case "weapon_smg":
			return "weapon_smg";
			
		case "weapon_pistol":
		case "weapon_machine_pistol":
			return "weapon_pistol";
			
		case "weapon_assault":
			return "weapon_assault";
	}
	
	return undefined;
}

/*
	Reacts to a kill: first blood, kill streaks, death streaks, multikills, weapon talk.
*/
reactToKill( attacker, victim, sWeapon, sMeansOfDeath )
{
	if ( !getdvarint( "bots_real_reactive" ) )
	{
		return;
	}
	
	// let the game update the streak counters first
	wait 0.25;
	
	if ( !isdefined( attacker ) || !isplayer( attacker ) || !isdefined( victim ) || attacker == victim )
	{
		return;
	}
	
	attackerHuman = !attacker is_bot();
	victimHuman = ( isplayer( victim ) && !victim is_bot() );
	
	if ( !isdefined( level.bots_real_firstblood ) )
	{
		level.bots_real_firstblood = true;
		level thread reactSay( "firstblood", undefined, attacker.name, undefined, undefined, 60, false, attacker );
		return;
	}
	
	// kill streaks: enemies panic, teammates hype
	streak = attacker.pers[ "cur_kill_streak" ];
	
	if ( isdefined( streak ) && streak >= 5 && streak % 5 == 0 )
	{
		chance = 35;
		
		if ( attackerHuman )
		{
			chance = 75;
		}
		
		level thread reactSay( "streak_enemy", otherTeamOf( attacker.team ), attacker.name, undefined, undefined, chance, false, attacker );
		
		if ( level.teambased )
		{
			level thread reactSay( "streak_team", attacker.team, attacker.name, undefined, undefined, chance / 2, true, attacker );
		}
		
		return;
	}
	
	// a human getting farmed: enemies tease, teammates encourage
	deaths = victim.pers[ "cur_death_streak" ];
	
	if ( victimHuman && isdefined( deaths ) && deaths >= 4 && ( deaths - 4 ) % 3 == 0 )
	{
		level thread reactSay( "tease", otherTeamOf( victim.team ), victim.name, undefined, undefined, 45, false, victim );
		
		if ( level.teambased )
		{
			level thread reactSay( "console", victim.team, victim.name, undefined, undefined, 50, true, victim );
		}
		
		return;
	}
	
	// a human multikill turns heads
	if ( attackerHuman && isdefined( attacker.bot_real_multi_count ) && attacker.bot_real_multi_count >= 3 )
	{
		level thread reactSay( "multikill", undefined, attacker.name, undefined, undefined, 70, false, attacker );
		return;
	}
	
	// weapon talk: a bot killed by a human complains about the gun, a bot killing a human brags about its own
	if ( attackerHuman && !victimHuman && victim is_bot() && isdefined( victim.pers[ "bots" ] ) )
	{
		kind = getWeaponTalkKind( sWeapon, sMeansOfDeath );
		
		if ( isdefined( kind ) && randomint( 100 ) < 25 * victim getChattiness() * getdvarfloat( "bots_main_chat" ) )
		{
			line = fillLine( victim getReactPool( kind ), attacker.name, chatWeaponName( sWeapon ) );
			
			if ( isdefined( line ) )
			{
				victim thread reactSpeak( line, false );
			}
		}
	}
	else if ( !attackerHuman && victimHuman && isdefined( attacker.pers[ "bots" ] ) )
	{
		if ( randomint( 100 ) < 10 * attacker getChattiness() * getdvarfloat( "bots_main_chat" ) )
		{
			line = fillLine( attacker getReactPool( "brag_weapon" ), undefined, chatWeaponName( sWeapon ) );
			
			if ( isdefined( line ) )
			{
				attacker thread reactSpeak( line, false );
			}
		}
	}
}

/*
	Upper case letter of a domination flag, undefined if unknown.
*/
getFlagLetter( flag )
{
	if ( !isdefined( flag.useobj ) )
	{
		return undefined;
	}
	
	label = flag.useobj maps\mp\gametypes\_gameobjects::getlabel();
	
	if ( !isdefined( label ) || label.size < 2 )
	{
		return undefined;
	}
	
	switch ( label[ 1 ] )
	{
		case "a":
			return "A";
			
		case "b":
			return "B";
			
		case "c":
			return "C";
			
		case "d":
			return "D";
			
		case "e":
			return "E";
	}
	
	return undefined;
}

/*
	Watches the match for things bots talk about: killstreaks being called, objectives, the lead, the clock.
*/
reactWatchMatch()
{
	level endon( "game_ended" );
	
	gameflagwait( "prematch_done" );
	
	seen = [];
	flagTeams = [];
	ctfCarriers = [];
	lastPlanted = false;
	lastDefused = false;
	lastHq = undefined;
	lastLeader = undefined;
	lastLeadTime = undefined;
	saidMinute = false;
	
	for ( ;; )
	{
		wait 1;
		
		if ( !getdvarint( "bots_real_reactive" ) )
		{
			continue;
		}
		
		if ( !isdefined( level.bots_real_humans ) )
		{
			level.bots_real_humans = [];
			level.bots_real_greeted = [];
		}
		
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( !level.players[ i ] is_bot() )
			{
				level.bots_real_humans[ level.players[ i ].name ] = true;
			}
		}
		
		// killstreaks in the air: uavs and air support
		targets = maps\mp\bots\_bot_realism::getAirTargets();
		stillThere = [];
		
		for ( i = 0; i < targets.size; i++ )
		{
			t = targets[ i ];
			
			if ( !isdefined( t ) || isplayer( t ) )
			{
				continue;
			}
			
			key = t getentitynumber() + "";
			stillThere[ key ] = t;
			
			if ( isdefined( seen[ key ] ) && seen[ key ] == t )
			{
				continue;
			}
			
			if ( !isdefined( t.owner ) || !isplayer( t.owner ) )
			{
				continue;
			}
			
			owner = t.owner;
			isUav = ( isdefined( t.model ) && issubstr( t.model, "uav" ) && !issubstr( t.model, "remote" ) );
			enemyKind = "air_enemy";
			teamKind = "air_team";
			
			if ( isUav )
			{
				enemyKind = "uav_enemy";
				teamKind = "uav_team";
			}
			
			level thread reactSay( enemyKind, otherTeamOf( owner.team ), owner.name, undefined, undefined, 35, false, owner );
			
			if ( level.teambased )
			{
				level thread reactSay( teamKind, owner.team, owner.name, undefined, undefined, 25, true, owner );
			}
		}
		
		seen = stillThere;
		
		if ( !level.teambased )
		{
			continue;
		}
		
		// domination flags
		if ( level.gametype == "dom" && isdefined( level.flags ) )
		{
			for ( i = 0; i < level.flags.size; i++ )
			{
				team = level.flags[ i ] maps\mp\gametypes\dom::getflagteam();
				
				if ( isdefined( flagTeams[ i ] ) && flagTeams[ i ] != team && ( team == "allies" || team == "axis" ) )
				{
					letter = getFlagLetter( level.flags[ i ] );
					level thread reactSay( "flag_ours", team, undefined, undefined, letter, 40, true );
					level thread reactSay( "flag_lost", otherTeamOf( team ), undefined, undefined, letter, 40, true );
				}
				
				flagTeams[ i ] = team;
			}
		}
		
		// search and destroy bomb
		if ( level.gametype == "sd" && isdefined( level.bombplanted ) )
		{
			if ( level.bombplanted && !lastPlanted )
			{
				level thread reactSay( "bomb_att", game[ "attackers" ], undefined, undefined, undefined, 50, true );
				level thread reactSay( "bomb_def", game[ "defenders" ], undefined, undefined, undefined, 50, true );
			}
			
			lastPlanted = level.bombplanted;
			
			if ( isdefined( level.bombdefused ) )
			{
				if ( level.bombdefused && !lastDefused )
				{
					level thread reactSay( "defused_def", game[ "defenders" ], undefined, undefined, undefined, 60, false );
					level thread reactSay( "defused_att", game[ "attackers" ], undefined, undefined, undefined, 40, false );
				}
				
				lastDefused = level.bombdefused;
			}
		}
		
		// capture the flag
		if ( level.gametype == "ctf" && isdefined( level.teamflags ) )
		{
			teams = strtok( "allies,axis", "," );
			
			for ( i = 0; i < teams.size; i++ )
			{
				flag = level.teamflags[ teams[ i ] ];
				
				if ( !isdefined( flag ) )
				{
					continue;
				}
				
				carrier = flag.carrier;
				
				if ( isdefined( carrier ) && isplayer( carrier ) && !isdefined( ctfCarriers[ teams[ i ] ] ) )
				{
					level thread reactSay( "ctf_lost", teams[ i ], carrier.name, undefined, undefined, 50, true );
					level thread reactSay( "ctf_took", otherTeamOf( teams[ i ] ), carrier.name, undefined, undefined, 40, true, carrier );
				}
				
				ctfCarriers[ teams[ i ] ] = carrier;
			}
		}
		
		// headquarters
		if ( level.gametype == "koth" && isdefined( level.radio ) && isdefined( level.radio.gameobject ) )
		{
			owner = level.radio.gameobject.ownerteam;
			
			if ( isdefined( owner ) && ( owner == "allies" || owner == "axis" ) && ( !isdefined( lastHq ) || lastHq != owner ) )
			{
				level thread reactSay( "hq_ours", owner, undefined, undefined, undefined, 40, true );
				level thread reactSay( "hq_lost", otherTeamOf( owner ), undefined, undefined, undefined, 40, true );
			}
			
			lastHq = owner;
		}
		
		// the lead changing, not in round based modes
		if ( level.gametype != "sd" && level.gametype != "sab" && level.gametype != "dd" && isdefined( game[ "teamScores" ] ) )
		{
			leader = undefined;
			
			if ( game[ "teamScores" ][ "allies" ] > game[ "teamScores" ][ "axis" ] )
			{
				leader = "allies";
			}
			else if ( game[ "teamScores" ][ "axis" ] > game[ "teamScores" ][ "allies" ] )
			{
				leader = "axis";
			}
			
			if ( isdefined( leader ) )
			{
				if ( isdefined( lastLeader ) && leader != lastLeader && maps\mp\bots\_bot_realism::timeSince( lastLeadTime, 45000 ) )
				{
					lastLeadTime = gettime();
					level thread reactSay( "lead_gained", leader, undefined, undefined, undefined, 35, true );
					level thread reactSay( "lead_lost", otherTeamOf( leader ), undefined, undefined, undefined, 35, true );
				}
				
				lastLeader = leader;
			}
		}
		
		// the last minute
		if ( !saidMinute && gettimelimit() > 0 && maps\mp\gametypes\_gamelogic::gettimeremaining() <= 60000 )
		{
			saidMinute = true;
			level thread reactSay( "minute_left", "allies", undefined, undefined, undefined, 50, true );
			level thread reactSay( "minute_left", "axis", undefined, undefined, undefined, 50, true );
		}
	}
}

/*
	Every minute or two a bot says something on its own, or asks a human player something.
*/
ambientChat()
{
	level endon( "game_ended" );
	
	gameflagwait( "prematch_done" );
	
	for ( ;; )
	{
		wait randomintrange( 50, 110 );
		
		if ( !getdvarint( "bots_real_reactive" ) )
		{
			continue;
		}
		
		bot = pickChatBot();
		
		if ( !isdefined( bot ) )
		{
			continue;
		}
		
		humans = [];
		
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( !level.players[ i ] is_bot() )
			{
				humans[ humans.size ] = level.players[ i ];
			}
		}
		
		// nobody to talk to
		if ( !humans.size )
		{
			continue;
		}
		
		if ( randomint( 100 ) >= 60 * bot getChattiness() * getdvarfloat( "bots_main_chat" ) )
		{
			continue;
		}
		
		if ( randomint( 100 ) < 40 )
		{
			human = random( humans );
			
			// usually a question it can follow up on
			if ( randomint( 100 ) < 60 && bot openTopicWith( human ) )
			{
				continue;
			}
			
			line = fillLine( bot getReactPool( "askhuman" ), human.name );
			
			if ( isdefined( line ) )
			{
				bot startConvo( human );
				bot thread reactSpeak( line, false );
			}
			
			continue;
		}
		
		line = fillLine( bot getReactPool( "ambient" ) );
		
		if ( isdefined( line ) )
		{
			bot thread reactSpeak( line, false );
		}
	}
}

/*
	Remembers that this bot is talking with a player, so it answers whatever they say next.
*/
startConvo( player )
{
	self.bot_real_convo = spawnstruct();
	self.bot_real_convo.player = player;
	self.bot_real_convo.time = gettime();
}

/*
	True if this bot is in a conversation with the player.
*/
inConvoWith( player )
{
	return ( isdefined( self.bot_real_convo ) && isdefined( self.bot_real_convo.player ) && self.bot_real_convo.player == player && !maps\mp\bots\_bot_realism::timeSince( self.bot_real_convo.time, 25000 ) );
}

/*
	True if the message reads like an insult.
*/
isInsult( msg )
{
	words = strtok( "noob,trash,garbage,suck,loser,idiot,dumb,stupid,clown,l2p,get good,git gud,bad,ez", "," );
	
	for ( i = 0; i < words.size; i++ )
	{
		if ( issubstr( msg, words[ i ] ) )
		{
			return true;
		}
	}
	
	return false;
}

/*
	A human insulted this bot: flame back, harder every time they keep going.
*/
flameBackAt( player )
{
	self endon( "disconnect" );
	
	if ( !isdefined( self.bot_real_beef ) )
	{
		self.bot_real_beef = [];
	}
	
	beef = self.bot_real_beef[ player.name ];
	
	if ( !isdefined( beef ) || maps\mp\bots\_bot_realism::timeSince( beef.time, 30000 ) )
	{
		beef = spawnstruct();
		beef.count = 0;
	}
	
	beef.count++;
	beef.time = gettime();
	self.bot_real_beef[ player.name ] = beef;
	
	kind = "flame";
	
	if ( beef.count == 1 )
	{
		pool = self getModernPool( "bait" );
	}
	else if ( beef.count == 2 )
	{
		pool = self getFlamePool( "flame" );
	}
	else
	{
		pool = self getFlamePool( "meltdown" );
		kind = "flamecaps";
	}
	
	self startConvo( player );
	
	wait randomfloatrange( 0.8, 1.8 );
	self BotDoChat( 100, modernLine( pool, player.name ), undefined, kind );
}

/*
	Another bot chimes in after a reply.
*/
chimeIn( speaker )
{
	if ( randomint( 100 ) >= 25 )
	{
		return;
	}
	
	bot = pickChatBot( undefined, speaker );
	
	if ( !isdefined( bot ) )
	{
		return;
	}
	
	line = fillLine( bot getReactPool( "convo" ) );
	
	if ( !isdefined( line ) )
	{
		return;
	}
	
	wait randomfloatrange( 1.8, 3 );
	
	if ( isdefined( bot ) )
	{
		bot BotDoChat( 100, line, undefined, "reply" );
	}
}

/*
	What a bot says at a step of a conversation topic, given the kind of answer (yes, no, num or any).
*/
getTopicStepPool( topic, step, cls )
{
	switch ( topic )
	{
		case "kd":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "num":
							return "nice, carry us then. how long have you been playing?|not bad at all. how long you been playing?|ok you're better than me lol. been playing long?";
							
						case "any":
							return "that's not a number lol. how long have you been playing?|i'll take that as bad lol. you play a lot?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "num":
							return "that explains it|a veteran, respect|oh so you're still new-ish";
							
						case "yes":
							return "you can tell lol|makes sense";
							
						case "no":
							return "could've fooled me|you're a natural then";
							
						case "any":
							return "fair|nice";
					}
					
					break;
			}
			
			break;
			
		case "1v1":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "no":
							return "scared lol|thought so";
							
						case "any":
							return "bet. rust, no hardscopes, first to 3?|say less. rust, first to 3?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "yes":
							return "ok, see you on rust. loser says gg|i'm warming up already";
							
						case "no":
							return "knew it|chicken";
							
						case "any":
							return "sounds like a yes to me|we'll see about that";
					}
					
					break;
			}
			
			break;
			
		case "lag":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "same here. where are you from?|it's the servers. where you playing from?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "ah that explains it|that's far lol|same region i think|the servers here are rough anyway";
					}
					
					break;
			}
			
			break;
			
		case "askclass":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "running the %w. you?|the %w with sitrep. what about you?|just the %w. you?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "nice, i'll try that|solid setup|that's a sweaty setup lol|respect";
					}
					
					break;
			}
			
			break;
			
		case "theirclass":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "nice, i'll try that|solid|that's a sweaty setup lol|respect";
					}
					
					break;
			}
			
			break;
			
		case "map":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "it's alright. what's your favourite map?|it's fine. favourite map?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "good pick|that one's a classic|terminal is better|ok that's a weird choice lol";
					}
					
					break;
			}
			
			break;
			
		case "playing":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "num":
							return "that explains it|respect|nice";
							
						case "yes":
							return "you can tell|makes sense";
							
						case "no":
							return "could've fooled me";
							
						case "any":
							return "nice|fair";
					}
					
					break;
			}
			
			break;
			
		case "favgun":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "solid choice|mid choice tbh|respect|that thing is broken lol";
					}
					
					break;
			}
			
			break;
			
		case "bot":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "yes":
							return "knew it|beep boop confirmed";
							
						case "no":
							return "that's what a bot would say|suspicious";
							
						case "any":
							return "who are you calling a bot. are YOU a bot?|rude. are you a bot?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "yes":
							return "knew it|lol called it";
							
						case "no":
							return "that's what a bot would say|sure, sure";
							
						case "any":
							return "suspicious|hmm";
					}
					
					break;
			}
			
			break;
			
		case "carry":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "on it, where are you?|stick with me";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "coming|on my way|got you";
					}
					
					break;
			}
			
			break;
			
		case "howareyou":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "good, you?|chillin, you?|not bad, you?";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "nice|same|glad to hear it";
					}
					
					break;
			}
			
			break;
			
		case "score":
			switch ( step )
			{
				case 0:
					switch ( cls )
					{
						case "any":
							return "close game so far|check the scoreboard lol|we can still win this";
					}
					
					break;
					
				case 1:
					switch ( cls )
					{
						case "any":
							return "lock in then|let's go|true";
					}
					
					break;
			}
			
			break;
	}
	
	return undefined;
}

/*
	How many exchanges a topic lasts.
*/
getTopicSteps( topic )
{
	switch ( topic )
	{
		case "kd":
			return 2;
			
		case "1v1":
			return 2;
			
		case "lag":
			return 2;
			
		case "askclass":
			return 2;
			
		case "theirclass":
			return 1;
			
		case "map":
			return 2;
			
		case "playing":
			return 1;
			
		case "favgun":
			return 1;
			
		case "bot":
			return 2;
			
		case "carry":
			return 2;
			
		case "howareyou":
			return 2;
			
		case "score":
			return 2;
	}
	
	return 0;
}

/*
	How a bot starts a topic with a player, undefined if it never starts that one.
*/
getTopicOpener( topic )
{
	switch ( topic )
	{
		case "kd":
			return "%n what's your k/d?|%n what's your k/d btw";
			
		case "1v1":
			return "%n 1v1 me after this?|%n you and me, 1v1, rust";
			
		case "theirclass":
			return "%n what class are you running?|%n what gun is that?";
			
		case "playing":
			return "%n how long have you been playing mw3?|%n you play this a lot?";
			
		case "favgun":
			return "%n what's your favourite gun?|%n best gun in this game?";
			
		case "bot":
			return "%n are you a bot?|%n you're not a bot, right?";
	}
	
	return undefined;
}

/*
	Topics a bot can bring up itself.
*/
getOpenerTopics()
{
	return "kd,1v1,theirclass,playing,favgun,bot";
}

/*
	The topic a player's message starts, undefined if none.
*/
getTopicForMessage( msg )
{
	padded = " " + msg;
	
	if ( issubstr( padded, "k/d" ) )
	{
		return "kd";
	}
	
	if ( issubstr( padded, "1v1" ) )
	{
		return "1v1";
	}
	
	if ( issubstr( padded, " lag" ) || issubstr( padded, "lagging" ) || issubstr( padded, "laggy" ) || issubstr( padded, " ping" ) )
	{
		return "lag";
	}
	
	if ( issubstr( padded, "your class" ) || issubstr( padded, "what class" ) || issubstr( padded, "loadout" ) || issubstr( padded, "what gun" ) || issubstr( padded, "your setup" ) )
	{
		return "askclass";
	}
	
	if ( issubstr( padded, "this map" ) || issubstr( padded, "the map" ) || issubstr( padded, "fav map" ) || issubstr( padded, "favorite map" ) || issubstr( padded, "favourite map" ) )
	{
		return "map";
	}
	
	if ( issubstr( padded, "are you a bot" ) || issubstr( padded, "you a bot" ) || issubstr( padded, "r u a bot" ) || issubstr( padded, "are u a bot" ) || issubstr( padded, "you're a bot" ) || issubstr( padded, "ur a bot" ) )
	{
		return "bot";
	}
	
	if ( issubstr( padded, "carry" ) || issubstr( padded, "help me" ) || issubstr( padded, "cover me" ) )
	{
		return "carry";
	}
	
	if ( issubstr( padded, "how are you" ) || issubstr( padded, "hru" ) || issubstr( padded, "how r u" ) || issubstr( padded, "how's it going" ) || issubstr( padded, "hows it going" ) || issubstr( padded, "wyd" ) )
	{
		return "howareyou";
	}
	
	if ( issubstr( padded, "score" ) || issubstr( padded, "are we winning" ) || issubstr( padded, "who's winning" ) || issubstr( padded, "whos winning" ) )
	{
		return "score";
	}
	
	return undefined;
}

/*
	How many bot-to-bot dialogues there are.
*/
getDialogueCount()
{
	return 10;
}

/*
	Who says a step of a dialogue: a (who started it) or b.
*/
getDialogueRole( d, step )
{
	switch ( d )
	{
		case 0:
			roles = "aba";
			return roles[ step ];
			
		case 1:
			roles = "aba";
			return roles[ step ];
			
		case 2:
			roles = "aba";
			return roles[ step ];
			
		case 3:
			roles = "aba";
			return roles[ step ];
			
		case 4:
			roles = "aba";
			return roles[ step ];
			
		case 5:
			roles = "aba";
			return roles[ step ];
			
		case 6:
			roles = "aba";
			return roles[ step ];
			
		case 7:
			roles = "aba";
			return roles[ step ];
			
		case 8:
			roles = "aba";
			return roles[ step ];
			
		case 9:
			roles = "aba";
			return roles[ step ];
	}
	
	return "a";
}

/*
	How many lines a dialogue has.
*/
getDialogueSteps( d )
{
	return 3;
}

/*
	A dialogue line for this bot to say at a step, in its era voice where the line depends on it.
*/
getDialoguePool( d, step )
{
	gen = self getChatGen();
	
	switch ( d )
	{
		case 0:
			switch ( step )
			{
				case 0:
					return "anyone else lagging?|is it just me or is it laggy";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "yeah, it's rough tonight|same here, ugh";
							
						case "zoomer":
							return "lag is crazy rn|nah i'm good actually";
							
						case "alpha":
							return "my wifi is so ohio rn|yes my mom is streaming netflix";
							
						case "boomer":
							return "Is that what the stuttering is?|I thought my computer was broken.";
					}
					
					break;
					
				case 2:
					return "must be the servers|ugh";
			}
			
			break;
			
		case 1:
			switch ( step )
			{
				case 0:
					return "who picked this map|this map again?";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "it's a classic, relax|i kinda like it";
							
						case "zoomer":
							return "it's mid ngl|this map is lowkey goated";
							
						case "alpha":
							return "this map is so ohio|this map has aura";
							
						case "boomer":
							return "Back in my day this was the best map.|I like this one. It has a nice view.";
					}
					
					break;
					
				case 2:
					return "fair|hard disagree|ok";
			}
			
			break;
			
		case 2:
			switch ( step )
			{
				case 0:
					return "is the %w overpowered or is it just me|the %w needs a nerf";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "it's busted|skill issue lol";
							
						case "zoomer":
							return "it's actually broken|nah you're just bad lol";
							
						case "alpha":
							return "the %w has crazy aura|it's so sigma";
							
						case "boomer":
							return "Back in my day we just had one gun.|Which one is that again?";
					}
					
					break;
					
				case 2:
					return "whatever, i'm using it next round|ok fair|lol";
			}
			
			break;
			
		case 3:
			switch ( step )
			{
				case 0:
					return "who's carrying this team|who's top of the scoreboard";
					
				case 1:
					return "not me lol|%f obviously|%f is carrying hard";
					
				case 2:
					return "facts|we need more of that";
			}
			
			break;
			
		case 4:
			switch ( step )
			{
				case 0:
					return "remember mw2 lobbies?|mw2 was better than this";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "best days of my life|those were the days";
							
						case "zoomer":
							return "i was like 5 when that came out|never played it";
							
						case "alpha":
							return "what's mw2|is that a roblox game";
							
						case "boomer":
							return "I remember when it came out on disc.|My grandson played that one.";
					}
					
					break;
					
				case 2:
					return "ok that makes me feel old|same|lol";
			}
			
			break;
			
		case 5:
			switch ( step )
			{
				case 0:
					return "it's so late|i should be sleeping";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "one more game|same lol";
							
						case "zoomer":
							return "sleep is for the weak|bro it's 3am for me";
							
						case "alpha":
							return "my mom thinks i'm asleep|i have school tomorrow";
							
						case "boomer":
							return "It's past my bedtime too.|I'm usually asleep by nine.";
					}
					
					break;
					
				case 2:
					return "one more. always one more|lol same";
			}
			
			break;
			
		case 6:
			switch ( step )
			{
				case 0:
					return "who's camping in that building|someone keeps camping that window";
					
				case 1:
					return "not me|some guy with a sniper|probably %f lol";
					
				case 2:
					return "i'm nading it|i'll flank him";
			}
			
			break;
			
		case 7:
			switch ( step )
			{
				case 0:
					return "brb dinner|brb food";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "enjoy|bring me some";
							
						case "zoomer":
							return "W food|what are you eating";
							
						case "alpha":
							return "fanum tax it|save me some";
							
						case "boomer":
							return "Enjoy your supper.|Don't forget to wash your hands.";
					}
					
					break;
					
				case 2:
					return "back|ok i'm back";
			}
			
			break;
			
		case 8:
			switch ( step )
			{
				case 0:
					return "my aim is so off today|i can't hit anything today";
					
				case 1:
					switch ( gen )
					{
						case "millennial":
							return "same|warm up first";
							
						case "zoomer":
							return "skill issue|lock in";
							
						case "alpha":
							return "your aura is low today|mewing helps aim";
							
						case "boomer":
							return "Have you tried glasses?|Try sitting closer to the screen.";
					}
					
					break;
					
				case 2:
					return "...i'll try that|lol";
			}
			
			break;
			
		case 9:
			switch ( step )
			{
				case 0:
					return "what's the score|are we winning?";
					
				case 1:
					return "no idea lol|it's close|check the scoreboard";
					
				case 2:
					return "nice|ugh|lock in then";
			}
			
			break;
	}
	
	return undefined;
}

/*
	Roughly what kind of answer a message is: yes, no, num (has a number) or any.
*/
classifyAnswer( msg )
{
	words = strtok( msg, " ,.!?" );
	
	if ( !words.size )
	{
		return "any";
	}
	
	first = words[ 0 ];
	yes = strtok( "yes,yeah,yep,ya,yup,sure,ok,okay,k,bet,y,ofc,absolutely,definitely", "," );
	no = strtok( "no,nah,nope,n,never,naw", "," );
	
	for ( i = 0; i < yes.size; i++ )
	{
		if ( first == yes[ i ] )
		{
			return "yes";
		}
	}
	
	for ( i = 0; i < no.size; i++ )
	{
		if ( first == no[ i ] )
		{
			return "no";
		}
	}
	
	for ( i = 0; i < msg.size; i++ )
	{
		if ( issubstr( "0123456789", msg[ i ] ) )
		{
			return "num";
		}
	}
	
	return "any";
}

/*
	True if this bot is in the middle of a topic with the player.
*/
topicActive( player )
{
	return ( isdefined( self.bot_real_topic ) && isdefined( self.bot_real_topic.player ) && self.bot_real_topic.player == player && !maps\mp\bots\_bot_realism::timeSince( self.bot_real_topic.time, 30000 ) );
}

/*
	Starts a topic with a player, at the given step.
*/
startTopic( topic, player )
{
	self.bot_real_topic = spawnstruct();
	self.bot_real_topic.name = topic;
	self.bot_real_topic.player = player;
	self.bot_real_topic.step = 0;
	self.bot_real_topic.time = gettime();
	self startConvo( player );
}

/*
	The bot's next line in the topic, based on how the player answered. Moves the topic along.
*/
topicReply( msg, player )
{
	t = self.bot_real_topic;
	cls = classifyAnswer( msg );
	pool = getTopicStepPool( t.name, t.step, cls );
	
	if ( !isdefined( pool ) )
	{
		pool = getTopicStepPool( t.name, t.step, "any" );
	}
	
	line = fillLine( pool, player.name, chatWeaponName( self getcurrentweapon() ) );
	
	t.step++;
	t.time = gettime();
	
	if ( t.step >= getTopicSteps( t.name ) )
	{
		// a 1v1 that wasn't turned down becomes personal: the bot goes looking for them
		if ( t.name == "1v1" && cls != "no" )
		{
			self maps\mp\bots\_bot_realism::setGrudgeAgainst( player );
		}
		
		self.bot_real_topic = undefined;
	}
	
	return line;
}

/*
	Brings up a topic with a player by asking them something. Returns true if it did.
*/
openTopicWith( player )
{
	topic = random( strtok( getOpenerTopics(), "," ) );
	line = fillLine( getTopicOpener( topic ), player.name );
	
	if ( !isdefined( line ) )
	{
		return false;
	}
	
	self startTopic( topic, player );
	player.bot_real_talking_to = self;
	player.bot_real_talking_time = gettime();
	self thread reactSpeak( line, false );
	return true;
}

/*
	Name of the top scorer, on the bot's team in team modes. undefined if nobody has scored.
*/
getTopPlayerName( bot )
{
	best = undefined;
	bestScore = 0;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		p = level.players[ i ];
		
		if ( !isdefined( p.pers[ "score" ] ) || p.pers[ "score" ] <= bestScore )
		{
			continue;
		}
		
		if ( level.teambased && isdefined( bot ) && isdefined( bot.team ) && p.team != bot.team )
		{
			continue;
		}
		
		best = p;
		bestScore = p.pers[ "score" ];
	}
	
	if ( !isdefined( best ) )
	{
		return undefined;
	}
	
	return best.name;
}

/*
	Every couple of minutes two bots have a short conversation: a question, an answer in the second bot's voice, a reply.
*/
botDialogueThink()
{
	level endon( "game_ended" );
	
	gameflagwait( "prematch_done" );
	
	weapons = strtok( "mp7,acr,type 95,pp90m1,msr,usas 12,striker,p90,scar-l,mk46", "," );
	
	for ( ;; )
	{
		wait randomintrange( 70, 140 );
		
		if ( !getdvarint( "bots_real_reactive" ) || !getdvarint( "bots_real_banter" ) || getdvarfloat( "bots_main_chat" ) <= 0 )
		{
			continue;
		}
		
		// don't talk over a flame war
		if ( isdefined( level.bots_flamewar ) && level.bots_flamewar )
		{
			continue;
		}
		
		a = pickChatBot();
		
		if ( !isdefined( a ) || randomint( 100 ) >= 70 * a getChattiness() * getdvarfloat( "bots_main_chat" ) )
		{
			continue;
		}
		
		b = pickChatBot( undefined, a );
		
		if ( !isdefined( b ) )
		{
			continue;
		}
		
		d = randomint( getDialogueCount() );
		weap = random( weapons );
		top = getTopPlayerName( a );
		
		for ( i = 0; i < getDialogueSteps( d ); i++ )
		{
			speaker = a;
			other = b;
			
			if ( getDialogueRole( d, i ) == "b" )
			{
				speaker = b;
				other = a;
			}
			
			if ( !isdefined( speaker ) || !isdefined( other ) )
			{
				break;
			}
			
			line = fillLine( speaker getDialoguePool( d, i ), other.name, weap, top );
			
			// its own thread, so a bot leaving mid-sentence can't end the dialogue loop
			if ( isdefined( line ) )
			{
				speaker thread BotDoChat( 100, line, undefined, "reply" );
			}
			
			wait randomfloatrange( 4.5, 6 );
		}
	}
}

/*
	Special kills (realism)
*/
bot_chat_specialkill_watch( state, type, other, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !isdefined( other ) || !isplayer( other ) || !isdefined( type ) )
	{
		return;
	}
	
	pool = getSpecialKillPool( state, type );
	
	if ( !isdefined( pool ) )
	{
		return;
	}
	
	wait randomfloatrange( 0.5, 1.5 );
	
	if ( state == "brag" )
	{
		self BotDoChat( 35, modernLine( pool, other.name ), undefined, "brag", other );
	}
	else
	{
		self BotDoChat( 30, modernLine( pool, other.name ) );
	}
}

/*
	Avenging a teammate (realism)
*/
bot_chat_avenge_watch( state, killer, victimName, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !isdefined( killer ) || !isplayer( killer ) || !isdefined( victimName ) )
	{
		return;
	}
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 15, "going after " + killer.name, true );
					break;
					
				case 1:
					self BotDoChat( 15, "i got you " + victimName, true );
					break;
			}
			
			break;
			
		case "done":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 50, "that's for " + victimName );
					break;
					
				case 1:
					self BotDoChat( 50, "avenged you " + victimName, true );
					break;
					
				case 2:
					self BotDoChat( 50, "got the trade" );
					break;
			}
			
			break;
	}
}

/*
	Killcam
*/
bot_chat_killcam_watch( state, b, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 1, "ok how did that even hit" );
					break;
					
				case 1:
					self BotDoChat( 1, "let me see this killcam..." );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 1, "reported" );
					break;
					
				case 1:
					self BotDoChat( 1, "clipped it, that's going on the channel" );
					break;
			}
			
			break;
	}
}

/*
	Stuck
*/
bot_chat_stuck_watch( a, b, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	sayLength = randomintrange( 5, 30 );
	msg = "";
	
	for ( i = 0; i < sayLength; i++ )
	{
		switch ( randomint( 9 ) )
		{
			case 0:
				msg = msg + "w";
				break;
				
			case 1:
				msg = msg + "s";
				break;
				
			case 2:
				msg = msg + "d";
				break;
				
			case 3:
				msg = msg + "a";
				break;
				
			case 4:
				msg = msg + " ";
				break;
				
			case 5:
				msg = msg + "we won";
				break;
				
			case 6:
				msg = msg + "S";
				break;
				
			case 7:
				msg = msg + "D";
				break;
				
			case 8:
				msg = msg + "A";
				break;
		}
	}
	
	self BotDoChat( 20, msg );
}

/*
	Tube
*/
bot_chat_tube_watch( state, tubeWp, tubeWeap, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i am going to go tube" );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i tubed" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_killstreak_watch( streakName, b, c, d, e, f, g )
*/
bot_chat_killstreak_watch( state, streakName, c, directionYaw, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "call":
			location = c;
			
			switch ( streakName )
			{
				case "helicopter_flares":
					switch ( randomint( 1 ) )
					{
						case 0:
							self BotDoChat( 100, "pave low incoming" );
							break;
					}
					
					break;
					
				case "emp":
					switch ( randomint( 2 ) )
					{
						case 0:
							self BotDoChat( 100, "EMP up, didn't see that coming" );
							break;
							
						case 1:
							self BotDoChat( 100, "You don't see an EMP everyday!" );
							break;
					}
					
					break;
					
				case "nuke":
					switch ( randomint( 8 ) )
					{
						case 0:
							self BotDoChat( 100, "NUUUKE" );
							break;
							
						case 1:
							self BotDoChat( 100, "lol sweet nuke" );
							break;
							
						case 2:
							self BotDoChat( 100, "NUKE READY" );
							break;
							
						case 3:
							self BotDoChat( 100, "YEEEEEEEES!!" );
							break;
							
						case 4:
							self BotDoChat( 100, "i get a nuke and my team still can't hold a flag" );
							break;
							
						case 5:
							self BotDoChat( 100, "GET NUKED NERDS!!!!" );
							break;
							
						case 6:
							self BotDoChat( 100, "calling it in" );
							break;
							
						case 7:
							self BotDoChat( 100, "Get nuked kids!" );
							break;
					}
					
					break;
					
				case "ac130":
					switch ( randomint( 5 ) )
					{
						case 0:
							self BotDoChat( 100, "time to clean up" );
							break;
							
						case 1:
							self BotDoChat( 100, "Stingers are not welcome! AC130 rules all!" );
							break;
							
						case 2:
							self BotDoChat( 100, "AC130 online, find cover" );
							break;
							
						case 3:
							self BotDoChat( 100, "ac130 Madness!" );
							break;
							
						case 4:
							self BotDoChat( 100, "say hello to my little friend" );
							break;
					}
					
					break;
					
				case "helicopter_minigun":
					switch ( randomint( 7 ) )
					{
						case 0:
							self BotDoChat( 100, "Eat my Chopper Gunner!!" );
							break;
							
						case 1:
							self BotDoChat( 100, "and here comes the pain" );
							break;
							
						case 2:
							self BotDoChat( 100, "chopper gunner up, 40 seconds of chaos" );
							break;
							
						case 3:
							self BotDoChat( 100, "Woot! Got my chopper gunner!" );
							break;
							
						case 4:
							self BotDoChat( 100, "got my chopper" );
							break;
							
						case 5:
							self BotDoChat( 100, "Time to spawn kill with the OP chopper!" );
							break;
							
						case 6:
							self BotDoChat( 100, "GET TO DA CHOPPA!!" );
							break;
					}
					
					break;
			}
			
			break;
			
		case "camp":
			campSpot = c;
			break;
	}
}

/*
	self thread bot_chat_crate_cap_watch( a, b, c, d, e, f, g )
*/
bot_chat_crate_cap_watch( state, aircare, player, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !isdefined( aircare ) )
	{
		return;
	}
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 2 ) )
			{
				case 0:
					if ( !isdefined( aircare.owner ) || aircare.owner == self )
					{
						self BotDoChat( 5, "going to my carepackage" );
					}
					else
					{
						self BotDoChat( 5, "going to " + aircare.owner.name + "'s carepackage" );
					}
					
					break;
					
				case 1:
					self BotDoChat( 5, "going to this carepackage" );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 2 ) )
			{
				case 0:
					if ( !isdefined( aircare.owner ) || aircare.owner == self )
					{
						self BotDoChat( 15, "taking my carepackage" );
					}
					else
					{
						self BotDoChat( 15, "taking " + aircare.owner.name + "'s carepackage" );
					}
					
					break;
					
				case 1:
					self BotDoChat( 15, "taking this carepackage" );
					break;
			}
			
			break;
			
		case "stop":
			if ( !isdefined( aircare.owner ) || aircare.owner == self )
			{
				switch ( randomint( 6 ) )
				{
					case 0:
						self BotDoChat( 10, "Pheww... Got my carepackage" );
						break;
						
					case 1:
						self BotDoChat( 10, "got my care package, what now" );
						break;
						
					case 2:
						self BotDoChat( 10, "holy cow! that was a close one!" );
						break;
						
					case 3:
						self BotDoChat( 10, "nice try, it's mine" );
						break;
						
					case 4:
						self BotDoChat( 10, "package secured" );
						break;
						
					case 5:
						if ( isdefined( aircare.cratetype ) )
						{
							self BotDoChat( 10, "got my " + aircare.cratetype );
						}
						
						break;
				}
			}
			else
			{
				switch ( randomint( 5 ) )
				{
					case 0:
						self BotDoChat( 10, "thanks for the care package " + aircare.owner.name );
						break;
						
					case 1:
						self BotDoChat( 10, "free care package, don't mind if i do" );
						break;
						
					case 2:
						self BotDoChat( 10, "I heard " + aircare.owner.name + " owed me a carepackage. Thanks lol." );
						break;
						
					case 3:
						self BotDoChat( 10, "your care package is mine now" );
						break;
						
					case 4:
						if ( isdefined( aircare.cratetype ) )
						{
							self BotDoChat( 10, "stole your " + aircare.cratetype );
						}
						
						break;
				}
			}
			
			break;
			
		case "captured":
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 10, "bye care package..." );
					break;
					
				case 1:
					self BotDoChat( 10, "WTF MAN! THAT WAS MINE." );
					break;
					
				case 2:
					self BotDoChat( 10, "Wow wtf " + player.name + ", i worked hard for that carepackage..." );
					break;
					
				case 3:
					self BotDoChat( 10, "fine " + player.name + ", take it" );
					break;
					
				case 4:
					if ( isdefined( aircare.cratetype ) )
					{
						self BotDoChat( 10, "Wow! there goes my " + aircare.cratetype + "!" );
					}
					
					break;
			}
			
			break;
			
		case "unreachable":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 25, "i cant reach that carepackage!" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_attack_vehicle_watch( a, b, c, d, e, f, g )
*/
bot_chat_attack_vehicle_watch( state, vehicle, rocketAmmo, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 14 ) )
			{
				case 0:
					self BotDoChat( 10, "Not on my watch..." );
					break;
					
				case 1:
					self BotDoChat( 10, "Take down aircraft I am" );
					break;
					
				case 2:
					self BotDoChat( 10, "i hate killstreaks" );
					break;
					
				case 3:
					self BotDoChat( 10, "Killstreaks ruin this game!!" );
					break;
					
				case 4:
					self BotDoChat( 10, "killstreaks sux" );
					break;
					
				case 5:
					self BotDoChat( 10, "keep the killstreaks comin'" );
					break;
					
				case 6:
					self BotDoChat( 10, "lol see that killstreak? its going to go BOOM!" );
					break;
					
				case 7:
					self BotDoChat( 10, "Lol I bet that noob used hardline to get that streak." );
					break;
					
				case 8:
					self BotDoChat( 10, "WOW HOW DO YOU GET THAT?? ITS GONE NOW." );
					break;
					
				case 9:
					self BotDoChat( 10, "HAHA say goodbye to your killstreak" );
					break;
					
				case 10:
					self BotDoChat( 10, "All your effort is gone now." );
					break;
					
				case 11:
					self BotDoChat( 10, "I hope there are flares on that killstreak." );
					break;
					
				case 12:
					self BotDoChat( 10, "taking down your killstreaks" );
					break;
					
				case 13:
					weap = rocketAmmo;
					
					if ( !isdefined( weap ) )
					{
						weap = self getcurrentweapon();
					}
					
					self BotDoChat( 10, "Im going to takedown your ks with my " + getbaseweaponname( weap ) );
					break;
			}
			
			break;
			
		case "stop":
			break;
	}
}

/*
	bot_chat_follow_threat_watch( a, b, c, d, e, f, g )
*/
bot_chat_follow_threat_watch( state, threat, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			break;
			
		case "stop":
			break;
	}
}

/*
	bot_chat_camp_watch( a, b, c, d, e, f, g )
*/
bot_chat_camp_watch( state, wp, time, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, "going to camp for " + time + " seconds" );
					break;
					
				case 1:
					self BotDoChat( 10, "time to go camp!" );
					break;
					
				case 2:
					self BotDoChat( 10, "rofl im going to camp" );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, "well im camping... this is fun!" );
					break;
					
				case 1:
					self BotDoChat( 10, "lol im camping, hope i kill someone" );
					break;
					
				case 2:
					self BotDoChat( 10, "im camping! i guess ill wait " + time + " before moving again" );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, "finished camping.." );
					break;
					
				case 1:
					self BotDoChat( 10, "wow that was a load of camping!" );
					break;
					
				case 2:
					self BotDoChat( 10, "well its been over " + time + " seconds, i guess ill stop camping" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_follow_watch( a, b, c, d, e, f, g )
*/
bot_chat_follow_watch( state, player, time, d, e, f, g )
{
	self endon( "disconnect" );
	
	if ( !isdefined( player ) )
	{
		return;
	}
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, "well im going to follow " + player.name + " for " + time + " seconds" );
					break;
					
				case 1:
					self BotDoChat( 10, "i've got your back " + player.name );
					break;
					
				case 2:
					self BotDoChat( 10, "sticking with you " + player.name );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 10, "well that was fun following " + player.name + " for " + time + " seconds" );
					break;
					
				case 1:
					self BotDoChat( 10, "im done following that guy" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_equ_watch
*/
bot_chat_equ_watch( state, wp, weap, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "going to place a " + getbaseweaponname( weap ) );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "placed a " + getbaseweaponname( weap ) );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_nade_watch
*/
bot_chat_nade_watch( state, wp, weap, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "going to throw a " + getbaseweaponname( weap ) );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "threw a " + getbaseweaponname( weap ) );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_jav_watch
*/
bot_chat_jav_watch( state, wp, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			break;
			
		case "start":
			break;
	}
}

/*
	bot_chat_throwback_watch
*/
bot_chat_throwback_watch( state, nade, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i am going to throw back the grenade!" );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i threw back the grenade!" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_tbag_watch
*/
bot_chat_tbag_watch( state, who, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, "going to teabag" );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, "teabag time" );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, "how do you like that?" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_rage_watch
*/
bot_chat_rage_watch( state, b, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 80, "K this is not going as I planned." );
					break;
					
				case 1:
					self BotDoChat( 80, "Screw this! I'm out." );
					break;
					
				case 2:
					self BotDoChat( 80, "Have fun being owned." );
					break;
					
				case 3:
					self BotDoChat( 80, "MY TEAM IS GARBAGE!" );
					break;
					
				case 4:
					self BotDoChat( 80, "kthxbai hackers" );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_revenge_watch
*/
bot_chat_revenge_watch( state, loc, killer, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "Im going to check out my death location." );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i checked out my deathlocation..." );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_heard_target_watch
*/
bot_chat_heard_target_watch( state, heard, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, "I think I hear " + heard.name + "..." );
					break;
			}
			
			break;
			
		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, "Well i checked out " + heard.name + "'s location..." );
					break;
			}
			
			break;
	}
}

/*
	bot_chat_uav_target_watch
*/
bot_chat_uav_target_watch( state, heard, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "start":
			break;
			
		case "stop":
			break;
	}
}

/*
	bot_chat_turret_attack_watch
*/
bot_chat_turret_attack_watch( state, turret, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, "going to this sentry..." );
					break;
			}
			
			break;
			
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, "attacking this sentry..." );
					break;
			}
			
			break;
			
		case "stop":
			break;
	}
}

/*
	bot_chat_attack_equ_watch
*/
bot_chat_attack_equ_watch( state, equ, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go_ti":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "going to this ti..." );
					break;
			}
			
			break;
			
		case "camp_ti":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "lol im camping this ti!" );
					break;
			}
			
			break;
			
		case "trigger_ti":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "destroyed their tactical insertion" );
					break;
			}
			
			break;
			
		case "start":
			break;
			
		case "stop":
			break;
	}
}

/*
	bot_chat_dom_watch
*/
bot_chat_dom_watch( state, sub_state, flag, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "spawnkill":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defend":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "cap":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_hq_watch
*/
bot_chat_hq_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defend":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_sab_watch
*/
bot_chat_sab_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "bomb":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defuser":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "planter":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "plant":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defuse":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_sd_watch
*/
bot_chat_sd_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "bomb":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defuser":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "planter":
			site = obj;
			
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "plant":
			site = obj;
			
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defuse":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_cap_watch
*/
bot_chat_cap_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "their_flag":
			flag = obj;
			
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "my_flag":
			flag = obj;
			
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_dem_watch
*/
bot_chat_dem_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "defuser":
			site = obj;
			
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "planter":
			site = obj;
			
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "plant":
			site = obj;
			
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "defuse":
			site = obj;
			
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_gtnw_watch
*/
bot_chat_gtnw_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_oneflag_watch
*/
bot_chat_oneflag_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "their_flag":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "my_flag":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_arena_watch
*/
bot_chat_arena_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;
					
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_vip_watch
*/
bot_chat_vip_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_conf_watch
*/
bot_chat_conf_watch( state, sub_state, tag, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_grnd_watch
*/
bot_chat_grnd_watch( state, sub_state, target, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "kill":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
			
		case "go_cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_tdef_watch
*/
bot_chat_tdef_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;
					
				case "stop":
					break;
			}
			
			break;
	}
}

/*
	bot_chat_box_cap_watch
*/
bot_chat_box_cap_watch( state, box, c, d, e, f, g )
{
	self endon( "disconnect" );
	
	switch ( state )
	{
		case "go":
			break;
			
		case "start":
			break;
			
		case "stop":
			break;
	}
}
