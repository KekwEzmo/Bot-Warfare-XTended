/*
	_menu
	Author: INeedGames
	Date: 05/11/2021
	The ingame menu.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

init()
{
	if ( getdvar( "bots_main_menu" ) == "" )
	{
		setdvar( "bots_main_menu", true );
	}
	
	if ( !getdvarint( "bots_main_menu" ) )
	{
		return;
	}
	
	// Bot Warfare XTended menu colors, tweak here
	level.bw_menu_bg = ( 0.05, 0.06, 0.09 ); // bars and panels
	level.bw_menu_bg_alpha = 0.85;
	level.bw_menu_accent = ( 1, 0.5, 0.1 ); // highlight and trim
	level.bw_menu_text = ( 0.75, 0.77, 0.82 ); // unselected text
	level.bw_menu_text_sel = ( 1, 1, 1 ); // selected text
	
	// names shown when a realism toggle is flipped
	level.bw_real_labels = [];
	level.bw_real_labels[ "traits" ] = "Bots have personalities";
	level.bw_real_labels[ "aim" ] = "Bots aim like humans";
	level.bw_real_labels[ "hearing" ] = "Bots react to sounds";
	level.bw_real_labels[ "retreat" ] = "Bots retreat when hurt";
	level.bw_real_labels[ "counter" ] = "Bots counter-pick classes";
	level.bw_real_labels[ "mood" ] = "Bots get cocky or tilted";
	level.bw_real_labels[ "airhide" ] = "Bots hide from air support";
	level.bw_real_labels[ "hotspots" ] = "Bots learn camping spots";
	level.bw_real_labels[ "teamintel" ] = "Bots share enemy sightings";
	level.bw_real_labels[ "matchaware" ] = "Bots react to the score";
	level.bw_real_labels[ "slipups" ] = "Bots make human mistakes";
	level.bw_real_labels[ "preaim" ] = "Bots check corners";
	level.bw_real_labels[ "turrets" ] = "Bots use mounted turrets";
	level.bw_real_labels[ "adaptive" ] = "Bots adapt to your skill";
	level.bw_real_labels[ "chat" ] = "Bots type like people";
	level.bw_real_labels[ "banter" ] = "Bots talk to each other";
	level.bw_real_labels[ "voice" ] = "Bots use voice callouts";
	level.bw_real_labels[ "grudge" ] = "Bots hold grudges";
	level.bw_real_labels[ "avenge" ] = "Bots avenge teammates";
	level.bw_real_labels[ "parties" ] = "Bots play in parties";
	level.bw_real_labels[ "churn" ] = "Bots come and go";
	
	thread watchPlayers();
}

/*
	Toggle state as colored text.
*/
onOff( value )
{
	if ( value )
	{
		return "^2ON";
	}
	
	return "^1OFF";
}

/*
	Fades a hud element in from invisible to the given alpha.
*/
fadeIn( alpha, time )
{
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self.alpha = 0;
	self fadeovertime( time );
	self.alpha = alpha;
}

/*
	Destroys the XTended title and trim on the top bar.
*/
destroyMainExtras()
{
	if ( isdefined( self.menutitlehud ) )
	{
		self.menutitlehud destroyFixed();
	}
	
	if ( isdefined( self.menu ) && isdefined( self.menu[ "X" ] ) && isdefined( self.menu[ "X" ][ "Trim" ] ) )
	{
		self.menu[ "X" ][ "Trim" ] destroyElemFixed();
	}
}

/*
	Destroys the submenu panel and its cursor bar.
*/
destroySubPanel()
{
	if ( !isdefined( self.menu ) || !isdefined( self.menu[ "Y" ] ) )
	{
		return;
	}
	
	if ( isdefined( self.menu[ "Y" ][ "Panel" ] ) )
	{
		self.menu[ "Y" ][ "Panel" ] destroyElemFixed();
	}
	
	if ( isdefined( self.menu[ "Y" ][ "Highlight" ] ) )
	{
		self.menu[ "Y" ][ "Highlight" ] destroyElemFixed();
	}
}

watchPlayers()
{
	for ( ;; )
	{
		wait 1;
		
		if ( !getdvarint( "bots_main_menu" ) )
		{
			return;
		}
		
		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[ i ];
			
			if ( !player is_host() )
			{
				continue;
			}
			
			if ( isdefined( player.menuinit ) && player.menuinit )
			{
				continue;
			}
			
			player thread init_menu();
		}
	}
}

destroyFixed()
{
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self destroy();
}

removeChildFixed( element )
{
	temp = [];
	
	for ( i = 0; i < self.children.size ; i++ )
	{
		if ( isdefined( self.children[ i ] ) && self.children[ i ] != element )
		{
			self.children[ i ].index = temp.size;
			temp[ temp.size ] = self.children[ i ];
		}
	}
	
	self.children = temp;
}

destroyElemFixed()
{
	if ( !isdefined( self ) )
	{
		return;
	}
	
	if ( isdefined( self.parent ) )
	{
		self.parent removeChildFixed( self );
	}
	
	self destroyelem();
}

kill_menu()
{
	self notify( "bots_kill_menu" );
	self.menuinit = undefined;
}

init_menu()
{
	self.menuinit = true;
	
	self.menuopen = false;
	self.submenu = "Main";
	self.curs[ "Main" ][ "X" ] = 0;
	self addOptions();
	
	self thread watchPlayerOpenMenu();
	self thread MenuSelect();
	self thread RightMenu();
	self thread LeftMenu();
	self thread UpMenu();
	self thread DownMenu();
	
	self thread watchDisconnect();
	
	self thread doGreetings();
}

watchDisconnect()
{
	self waittill_either( "disconnect", "bots_kill_menu" );
	
	if ( self.menuopen )
	{
		if ( isdefined( self.menutexty ) )
		{
			for ( i = 0; i < self.menutexty.size; i++ )
			{
				if ( isdefined( self.menutexty[ i ] ) )
				{
					self.menutexty[ i ] destroyElemFixed();
				}
			}
		}
		
		if ( isdefined( self.menutext ) )
		{
			for ( i = 0; i < self.menutext.size; i++ )
			{
				if ( isdefined( self.menutext[ i ] ) )
				{
					self.menutext[ i ] destroyElemFixed();
				}
			}
		}
		
		if ( isdefined( self.menu ) && isdefined( self.menu[ "X" ] ) )
		{
			if ( isdefined( self.menu[ "X" ][ "Shader" ] ) )
			{
				self.menu[ "X" ][ "Shader" ] destroyElemFixed();
			}
			
			if ( isdefined( self.menu[ "X" ][ "Scroller" ] ) )
			{
				self.menu[ "X" ][ "Scroller" ] destroyElemFixed();
			}
		}
		
		if ( isdefined( self.menuversionhud ) )
		{
			self.menuversionhud destroyFixed();
		}
		
		self destroyMainExtras();
		self destroySubPanel();
	}
}

doGreetings()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	wait 1;
	self iprintln( "Welcome to ^3Bot Warfare XTended^7, " + self.name + "!" );
	wait 5;
	self iprintln( "Press ^3[{+actionslot 1}]^7 to open the menu" );
}

watchPlayerOpenMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_open_menu", "+actionslot 1" );
	
	for ( ;; )
	{
		self waittill( "bots_open_menu" );
		
		if ( !self.menuopen )
		{
			self playlocalsound( "mouse_click" );
			self thread OpenSub( self.submenu );
		}
		else
		{
			self playlocalsound( "mouse_click" );
			
			if ( self.submenu != "Main" )
			{
				self ExitSub();
			}
			else
			{
				self ExitMenu();
				
				if ( !gameflag( "prematch_done" ) || level.gameended )
				{
					self freezecontrols( true );
				}
				else
				{
					self freezecontrols( false );
				}
			}
		}
	}
}

MenuSelect()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_select", "+gostand" );
	
	for ( ;; )
	{
		self waittill( "bots_select" );
		
		if ( self.menuopen )
		{
			self playlocalsound( "mouse_click" );
			
			if ( self.submenu == "Main" )
			{
				self thread [[ self.option[ "Function" ][ self.submenu ][ self.curs[ "Main" ][ "X" ] ] ]]( self.option[ "Arg1" ][ self.submenu ][ self.curs[ "Main" ][ "X" ] ], self.option[ "Arg2" ][ self.submenu ][ self.curs[ "Main" ][ "X" ] ] );
			}
			else
			{
				self thread [[ self.option[ "Function" ][ self.submenu ][ self.curs[ self.submenu ][ "Y" ] ] ]]( self.option[ "Arg1" ][ self.submenu ][ self.curs[ self.submenu ][ "Y" ] ], self.option[ "Arg2" ][ self.submenu ][ self.curs[ self.submenu ][ "Y" ] ] );
			}
		}
	}
}

LeftMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_left", "+moveleft" );
	
	for ( ;; )
	{
		self waittill( "bots_left" );
		
		if ( self.menuopen && self.submenu == "Main" )
		{
			self playlocalsound( "mouse_over" );
			self.curs[ "Main" ][ "X" ]--;
			
			if ( self.curs[ "Main" ][ "X" ] < 0 )
			{
				self.curs[ "Main" ][ "X" ] = self.option[ "Name" ][ self.submenu ].size - 1;
			}
			
			self CursMove( "X" );
		}
	}
}

RightMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_right", "+moveright" );
	
	for ( ;; )
	{
		self waittill( "bots_right" );
		
		if ( self.menuopen && self.submenu == "Main" )
		{
			self playlocalsound( "mouse_over" );
			self.curs[ "Main" ][ "X" ]++;
			
			if ( self.curs[ "Main" ][ "X" ] > self.option[ "Name" ][ self.submenu ].size - 1 )
			{
				self.curs[ "Main" ][ "X" ] = 0;
			}
			
			self CursMove( "X" );
		}
	}
}

UpMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_up", "+forward" );
	
	for ( ;; )
	{
		self waittill( "bots_up" );
		
		if ( self.menuopen && self.submenu != "Main" )
		{
			self playlocalsound( "mouse_over" );
			self.curs[ self.submenu ][ "Y" ]--;
			
			if ( self.curs[ self.submenu ][ "Y" ] < 0 )
			{
				self.curs[ self.submenu ][ "Y" ] = self.option[ "Name" ][ self.submenu ].size - 1;
			}
			
			self CursMove( "Y" );
		}
	}
}

DownMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyonplayercommand( "bots_down", "+back" );
	
	for ( ;; )
	{
		self waittill( "bots_down" );
		
		if ( self.menuopen && self.submenu != "Main" )
		{
			self playlocalsound( "mouse_over" );
			self.curs[ self.submenu ][ "Y" ]++;
			
			if ( self.curs[ self.submenu ][ "Y" ] > self.option[ "Name" ][ self.submenu ].size - 1 )
			{
				self.curs[ self.submenu ][ "Y" ] = 0;
			}
			
			self CursMove( "Y" );
		}
	}
}

OpenSub( menu, menu2 )
{
	if ( menu != "Main" && ( !isdefined( self.menu[ menu ] ) || !!isdefined( self.menu[ menu ][ "FirstOpen" ] ) ) )
	{
		self.curs[ menu ][ "Y" ] = 0;
		self.menu[ menu ][ "FirstOpen" ] = true;
	}
	
	logOldi = true;
	self.submenu = menu;
	
	if ( self.submenu == "Main" )
	{
		if ( isdefined( self.menutext ) )
		{
			for ( i = 0; i < self.menutext.size; i++ )
			{
				if ( isdefined( self.menutext[ i ] ) )
				{
					self.menutext[ i ] destroyElemFixed();
				}
			}
		}
		
		if ( isdefined( self.menu ) && isdefined( self.menu[ "X" ] ) )
		{
			if ( isdefined( self.menu[ "X" ][ "Shader" ] ) )
			{
				self.menu[ "X" ][ "Shader" ] destroyElemFixed();
			}
			
			if ( isdefined( self.menu[ "X" ][ "Scroller" ] ) )
			{
				self.menu[ "X" ][ "Scroller" ] destroyElemFixed();
			}
		}
		
		if ( isdefined( self.menuversionhud ) )
		{
			self.menuversionhud destroyFixed();
		}
		
		self destroyMainExtras();
		self destroySubPanel();
		
		for ( i = 0 ; i < self.option[ "Name" ][ self.submenu ].size ; i++ )
		{
			self.menutext[ i ] = self createfontstring( "default", 1.4 );
			tabCount = self.option[ "Name" ][ self.submenu ].size;
			self.menutext[ i ] setpoint( "CENTER", "CENTER", ( i - ( tabCount - 1 ) / 2.0 ) * 110, -226 );
			self.menutext[ i ] settext( self.option[ "Name" ][ self.submenu ][ i ] );
			
			if ( logOldi )
			{
				self.oldi = i;
			}
			
			if ( self.menutext[ i ].x > 300 )
			{
				logOldi = false;
				x = i - self.oldi;
				self.menutext[ i ] setpoint( "CENTER", "CENTER", ( ( ( -300 ) - ( i * 100 ) ) + ( i * 100 ) ) + ( x * 100 ), -196 );
			}
			
			self.menutext[ i ].alpha = 1;
			self.menutext[ i ].sort = 999;
		}
		
		barHeight = 30;
		
		if ( !logOldi )
		{
			barHeight = 90;
		}
		
		self.menu[ "X" ][ "Shader" ] = self createRectangle( "CENTER", "CENTER", 0, -225, 1000, barHeight, level.bw_menu_bg, -2, level.bw_menu_bg_alpha, "white" );
		self.menu[ "X" ][ "Trim" ] = self createRectangle( "CENTER", "CENTER", 0, -225 + barHeight / 2 + 1, 1000, 2, level.bw_menu_accent, -2, 1, "white" );
		self.menu[ "X" ][ "Scroller" ] = self createRectangle( "CENTER", "CENTER", self.menutext[ self.curs[ "Main" ][ "X" ] ].x, -225, 114, 24, level.bw_menu_accent, -1, 0.9, "white" );
		
		self.menutitlehud = self createfontstring( "objective", 1.2 );
		self.menutitlehud setpoint( "RIGHT", "TOPRIGHT", -16, 15 );
		self.menutitlehud settext( "BW ^3XTENDED" );
		self.menutitlehud.color = level.bw_menu_text_sel;
		self.menutitlehud.sort = 999;
		
		self CursMove( "X" );
		
		self.menuversionhud = initHudElem( "Bot Warfare XTended " + level.bw_version + "  -  based on Bot Warfare " + level.bw_base_version + " by INeedGames", 0, 0 );
		self.menuversionhud.color = level.bw_menu_text;
		
		// fade the menu in instead of popping it on screen
		self.menu[ "X" ][ "Shader" ] fadeIn( level.bw_menu_bg_alpha, 0.15 );
		self.menu[ "X" ][ "Trim" ] fadeIn( 1, 0.15 );
		self.menutitlehud fadeIn( 1, 0.2 );
		self.menuversionhud fadeIn( 1, 0.2 );
		
		for ( i = 0; i < self.menutext.size; i++ )
		{
			self.menutext[ i ] fadeIn( 1, 0.15 );
		}
		
		self.menuopen = true;
	}
	else
	{
		if ( isdefined( self.menutexty ) )
		{
			for ( i = 0 ; i < self.menutexty.size ; i++ )
			{
				if ( isdefined( self.menutexty[ i ] ) )
				{
					self.menutexty[ i ] destroyElemFixed();
				}
			}
		}
		
		self destroySubPanel();
		
		// keep the column on screen for the outer tabs
		colX = clamp( self.menutext[ self.curs[ "Main" ][ "X" ] ].x, -140, 140 );
		count = self.option[ "Name" ][ self.submenu ].size;
		
		self.menu[ "Y" ][ "Panel" ] = self createRectangle( "CENTER", "CENTER", colX, -160 + ( count - 1 ) * 10, 340, count * 20 + 16, level.bw_menu_bg, -2, level.bw_menu_bg_alpha, "white" );
		curY = self.curs[ self.submenu ][ "Y" ];
		
		if ( !isdefined( curY ) )
		{
			curY = 0;
		}
		
		self.menu[ "Y" ][ "Highlight" ] = self createRectangle( "CENTER", "CENTER", colX, -160 + curY * 20, 340, 20, level.bw_menu_accent, -1, 0.85, "white" );
		self.menu[ "Y" ][ "Panel" ] fadeIn( level.bw_menu_bg_alpha, 0.12 );
		
		for ( i = 0 ; i < self.option[ "Name" ][ self.submenu ].size ; i++ )
		{
			self.menutexty[ i ] = self createfontstring( "default", 1.4 );
			self.menutexty[ i ] setpoint( "CENTER", "CENTER", colX, -160 + ( i * 20 ) );
			self.menutexty[ i ] settext( self.option[ "Name" ][ self.submenu ][ i ] );
			self.menutexty[ i ].sort = 999;
			self.menutexty[ i ] fadeIn( 1, 0.12 );
		}
		
		self CursMove( "Y" );
	}
}

CursMove( direction )
{
	self notify( "scrolled" );
	
	if ( self.submenu == "Main" )
	{
		if ( isdefined( self.menutext ) )
		{
			self.menu[ "X" ][ "Scroller" ] moveovertime( 0.12 );
			self.menu[ "X" ][ "Scroller" ].x = self.menutext[ self.curs[ "Main" ][ "X" ] ].x;
			self.menu[ "X" ][ "Scroller" ].y = self.menutext[ self.curs[ "Main" ][ "X" ] ].y;
			
			for ( i = 0; i < self.menutext.size; i++ )
			{
				if ( isdefined( self.menutext[ i ] ) )
				{
					self.menutext[ i ].fontscale = 1.4;
					self.menutext[ i ].color = level.bw_menu_text;
					self.menutext[ i ].glowalpha = 0;
				}
			}
		}
		
		self thread ShowOptionOn( direction );
	}
	else
	{
		if ( isdefined( self.menutexty ) )
		{
			for ( i = 0; i < self.menutexty.size; i++ )
			{
				if ( isdefined( self.menutexty[ i ] ) )
				{
					self.menutexty[ i ].fontscale = 1.4;
					self.menutexty[ i ].color = level.bw_menu_text;
					self.menutexty[ i ].glowalpha = 0;
				}
			}
			
			cur = self.curs[ self.submenu ][ "Y" ];
			
			if ( isdefined( cur ) && isdefined( self.menutexty[ cur ] ) && isdefined( self.menu[ "Y" ] ) && isdefined( self.menu[ "Y" ][ "Highlight" ] ) )
			{
				self.menu[ "Y" ][ "Highlight" ] moveovertime( 0.1 );
				self.menu[ "Y" ][ "Highlight" ].y = self.menutexty[ cur ].y;
			}
		}
		
		if ( isdefined( self.menutext ) )
		{
			for ( i = 0; i < self.menutext.size; i++ )
			{
				if ( isdefined( self.menutext[ i ] ) )
				{
					self.menutext[ i ].fontscale = 1.4;
					self.menutext[ i ].color = level.bw_menu_text;
					self.menutext[ i ].glowalpha = 0;
				}
			}
		}
		
		self thread ShowOptionOn( direction );
	}
}

ShowOptionOn( variable )
{
	self endon( "scrolled" );
	self endon( "disconnect" );
	self endon( "exit" );
	self endon( "bots_kill_menu" );
	
	for ( time = 0;; time += 0.05 )
	{
		if ( !self isonground() && isalive( self ) && gameflag( "prematch_done" ) && !level.gameended )
		{
			self freezecontrols( false );
		}
		else
		{
			self freezecontrols( true );
		}
		
		self setclientdvar( "r_blur", "5" );
		self setclientdvar( "sc_blur", "15" );
		self addOptions();
		
		if ( self.submenu == "Main" )
		{
			if ( isdefined( self.curs[ self.submenu ][ variable ] ) && isdefined( self.menutext ) && isdefined( self.menutext[ self.curs[ self.submenu ][ variable ] ] ) )
			{
				self.menutext[ self.curs[ self.submenu ][ variable ] ].fontscale = 1.5;
				self.menutext[ self.curs[ self.submenu ][ variable ] ].color = level.bw_menu_text_sel;
				
				if ( isdefined( self.menu[ "X" ][ "Scroller" ] ) )
				{
					self.menu[ "X" ][ "Scroller" ].alpha = 0.8 + 0.2 * sin( time * 180 );
				}
			}
			
			if ( isdefined( self.menutext ) )
			{
				for ( i = 0; i < self.option[ "Name" ][ self.submenu ].size; i++ )
				{
					if ( isdefined( self.menutext[ i ] ) )
					{
						self.menutext[ i ] settext( self.option[ "Name" ][ self.submenu ][ i ] );
					}
				}
			}
		}
		else
		{
			if ( isdefined( self.curs[ self.submenu ][ variable ] ) && isdefined( self.menutexty ) && isdefined( self.menutexty[ self.curs[ self.submenu ][ variable ] ] ) )
			{
				self.menutexty[ self.curs[ self.submenu ][ variable ] ].fontscale = 1.5;
				self.menutexty[ self.curs[ self.submenu ][ variable ] ].color = level.bw_menu_text_sel;
				
				if ( isdefined( self.menu[ "Y" ] ) && isdefined( self.menu[ "Y" ][ "Highlight" ] ) )
				{
					self.menu[ "Y" ][ "Highlight" ].alpha = 0.75 + 0.15 * sin( time * 180 );
				}
			}
			
			if ( isdefined( self.menutexty ) )
			{
				for ( i = 0; i < self.option[ "Name" ][ self.submenu ].size; i++ )
				{
					if ( isdefined( self.menutexty[ i ] ) )
					{
						self.menutexty[ i ] settext( self.option[ "Name" ][ self.submenu ][ i ] );
					}
				}
			}
		}
		
		wait 0.05;
	}
}

AddMenu( menu, num, text, function, arg1, arg2 )
{
	self.option[ "Name" ][ menu ][ num ] = text;
	self.option[ "Function" ][ menu ][ num ] = function;
	self.option[ "Arg1" ][ menu ][ num ] = arg1;
	self.option[ "Arg2" ][ menu ][ num ] = arg2;
}

AddBack( menu, back )
{
	self.menu[ "Back" ][ menu ] = back;
}

ExitSub()
{
	if ( isdefined( self.menutexty ) )
	{
		for ( i = 0; i < self.menutexty.size; i++ )
		{
			if ( isdefined( self.menutexty[ i ] ) )
			{
				self.menutexty[ i ] destroyElemFixed();
			}
		}
	}
	
	self destroySubPanel();
	
	self.submenu = self.menu[ "Back" ][ self.submenu ];
	
	if ( self.submenu == "Main" )
	{
		self CursMove( "X" );
	}
	else
	{
		self CursMove( "Y" );
	}
}

ExitMenu()
{
	if ( isdefined( self.menutext ) )
	{
		for ( i = 0; i < self.menutext.size; i++ )
		{
			if ( isdefined( self.menutext[ i ] ) )
			{
				self.menutext[ i ] destroyElemFixed();
			}
		}
	}
	
	if ( isdefined( self.menu ) && isdefined( self.menu[ "X" ] ) )
	{
		if ( isdefined( self.menu[ "X" ][ "Shader" ] ) )
		{
			self.menu[ "X" ][ "Shader" ] destroyElemFixed();
		}
		
		if ( isdefined( self.menu[ "X" ][ "Scroller" ] ) )
		{
			self.menu[ "X" ][ "Scroller" ] destroyElemFixed();
		}
	}
	
	if ( isdefined( self.menuversionhud ) )
	{
		self.menuversionhud destroyFixed();
	}
	
	self destroyMainExtras();
	self destroySubPanel();
	
	self.menuopen = false;
	self notify( "exit" );
	
	self setclientdvar( "r_blur", "0" );
	self setclientdvar( "sc_blur", "2" );
}

initHudElem( txt, xl, yl )
{
	hud = newclienthudelem( self );
	hud settext( txt );
	hud.alignx = "center";
	hud.aligny = "bottom";
	hud.horzalign = "center";
	hud.vertalign = "bottom";
	hud.x = xl;
	hud.y = yl;
	hud.foreground = true;
	hud.fontscale = 1;
	hud.font = "objective";
	hud.alpha = 1;
	hud.glow = 0;
	hud.glowcolor = ( 0, 0, 0 );
	hud.glowalpha = 1;
	hud.color = ( 1.0, 1.0, 1.0 );
	
	return hud;
}

createRectangle( align, relative, x, y, width, height, color, sort, alpha, shader )
{
	barElemBG = newclienthudelem( self );
	barElemBG.elemtype = "bar_";
	barElemBG.width = width;
	barElemBG.height = height;
	barElemBG.align = align;
	barElemBG.relative = relative;
	barElemBG.xoffset = 0;
	barElemBG.yoffset = 0;
	barElemBG.children = [];
	barElemBG.sort = sort;
	barElemBG.color = color;
	barElemBG.alpha = alpha;
	barElemBG setparent( level.uiparent );
	barElemBG setshader( shader, width, height );
	barElemBG.hidden = false;
	barElemBG setpoint( align, relative, x, y );
	return barElemBG;
}

addOptions()
{
	self AddMenu( "Main", 0, "Bots", ::OpenSub, "man_bots", "" );
	self AddBack( "man_bots", "Main" );
	
	_temp = "";
	_tempDvar = getdvarint( "bots_manage_add" );
	self AddMenu( "man_bots", 0, "Add 1 bot", ::man_bots, "add", 1 + _tempDvar );
	self AddMenu( "man_bots", 1, "Add 3 bot", ::man_bots, "add", 3 + _tempDvar );
	self AddMenu( "man_bots", 2, "Add 7 bot", ::man_bots, "add", 7 + _tempDvar );
	self AddMenu( "man_bots", 3, "Add 11 bot", ::man_bots, "add", 11 + _tempDvar );
	self AddMenu( "man_bots", 4, "Add 17 bot", ::man_bots, "add", 17 + _tempDvar );
	self AddMenu( "man_bots", 5, "Kick a bot", ::man_bots, "kick", 1 );
	self AddMenu( "man_bots", 6, "Kick all bots", ::man_bots, "kick", getBotArray().size );
	
	_tempDvar = getdvarint( "bots_manage_fill_kick" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "man_bots", 7, "Toggle auto bot kicking: " + _temp, ::man_bots, "autokick", _tempDvar );
	
	_tempDvar = getdvarint( "bots_manage_fill_mode" );
	
	switch ( _tempDvar )
	{
		case 0:
			_temp = "everyone";
			break;
			
		case 1:
			_temp = "just bots";
			break;
			
		case 2:
			_temp = "everyone, adjust to map";
			break;
			
		case 3:
			_temp = "just bots, adjust to map";
			break;
			
		case 4:
			_temp = "bots used as team balance";
			break;
			
		case 5:
			_temp = "bots used as team balance, adjust to map";
			break;
			
		default:
			_temp = "out of range";
			break;
	}
	
	self AddMenu( "man_bots", 8, "Change bot_fill_mode: " + _temp, ::man_bots, "fillmode", _tempDvar );
	
	_tempDvar = getdvarint( "bots_manage_fill" );
	self AddMenu( "man_bots", 9, "Increase bots to keep in-game: " + _tempDvar, ::man_bots, "fillup", _tempDvar );
	self AddMenu( "man_bots", 10, "Decrease bots to keep in-game: " + _tempDvar, ::man_bots, "filldown", _tempDvar );
	
	_tempDvar = getdvarint( "bots_manage_fill_spec" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "man_bots", 11, "Count players for fill on spectator: " + _temp, ::man_bots, "fillspec", _tempDvar );
	
	//
	
	self AddMenu( "Main", 1, "Teams & Skill", ::OpenSub, "man_team", "" );
	self AddBack( "man_team", "Main" );
	
	_tempDvar = getdvar( "bots_team" );
	self AddMenu( "man_team", 0, "Change bot team: " + _tempDvar, ::bot_teams, "team", _tempDvar );
	
	_tempDvar = getdvarint( "bots_team_amount" );
	self AddMenu( "man_team", 1, "Increase bots to be on axis team: " + _tempDvar, ::bot_teams, "teamup", _tempDvar );
	self AddMenu( "man_team", 2, "Decrease bots to be on axis team: " + _tempDvar, ::bot_teams, "teamdown", _tempDvar );
	
	_tempDvar = getdvarint( "bots_team_force" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "man_team", 3, "Toggle forcing bots on team: " + _temp, ::bot_teams, "teamforce", _tempDvar );
	
	_tempDvar = getdvarint( "bots_team_mode" );
	
	if ( _tempDvar )
	{
		_temp = "only bots";
	}
	else
	{
		_temp = "everyone";
	}
	
	self AddMenu( "man_team", 4, "Toggle bot_team_bot: " + _temp, ::bot_teams, "teammode", _tempDvar );
	
	_tempDvar = getdvarint( "bots_skill" );
	
	switch ( _tempDvar )
	{
		case 0:
			_temp = "random for all";
			break;
			
		case 1:
			_temp = "too easy";
			break;
			
		case 2:
			_temp = "easy";
			break;
			
		case 3:
			_temp = "easy-medium";
			break;
			
		case 4:
			_temp = "medium";
			break;
			
		case 5:
			_temp = "hard";
			break;
			
		case 6:
			_temp = "very hard";
			break;
			
		case 7:
			_temp = "hardest";
			break;
			
		case 8:
			_temp = "custom";
			break;
			
		case 9:
			_temp = "complete random";
			break;
			
		default:
			_temp = "out of range";
			break;
	}
	
	self AddMenu( "man_team", 5, "Change bot difficulty: " + _temp, ::bot_teams, "skill", _tempDvar );
	
	_tempDvar = getdvarint( "bots_skill_axis_hard" );
	self AddMenu( "man_team", 6, "Increase amount of hard bots on axis team: " + _tempDvar, ::bot_teams, "axishardup", _tempDvar );
	self AddMenu( "man_team", 7, "Decrease amount of hard bots on axis team: " + _tempDvar, ::bot_teams, "axisharddown", _tempDvar );
	
	_tempDvar = getdvarint( "bots_skill_axis_med" );
	self AddMenu( "man_team", 8, "Increase amount of med bots on axis team: " + _tempDvar, ::bot_teams, "axismedup", _tempDvar );
	self AddMenu( "man_team", 9, "Decrease amount of med bots on axis team: " + _tempDvar, ::bot_teams, "axismeddown", _tempDvar );
	
	_tempDvar = getdvarint( "bots_skill_allies_hard" );
	self AddMenu( "man_team", 10, "Increase amount of hard bots on allies team: " + _tempDvar, ::bot_teams, "allieshardup", _tempDvar );
	self AddMenu( "man_team", 11, "Decrease amount of hard bots on allies team: " + _tempDvar, ::bot_teams, "alliesharddown", _tempDvar );
	
	_tempDvar = getdvarint( "bots_skill_allies_med" );
	self AddMenu( "man_team", 12, "Increase amount of med bots on allies team: " + _tempDvar, ::bot_teams, "alliesmedup", _tempDvar );
	self AddMenu( "man_team", 13, "Decrease amount of med bots on allies team: " + _tempDvar, ::bot_teams, "alliesmeddown", _tempDvar );
	
	//
	
	self AddMenu( "Main", 2, "Settings", ::OpenSub, "set1", "" );
	self AddBack( "set1", "Main" );
	
	_tempDvar = getdvarint( "bots_loadout_reasonable" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 0, "Bots use only good class setups: " + _temp, ::bot_func, "reasonable", _tempDvar );
	
	_tempDvar = getdvarint( "bots_loadout_allow_op" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 1, "Bots can use op and annoying class setups: " + _temp, ::bot_func, "op", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_move" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 2, "Bots can move: " + _temp, ::bot_func, "move", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_knife" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 3, "Bots can knife: " + _temp, ::bot_func, "knife", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_fire" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 4, "Bots can fire: " + _temp, ::bot_func, "fire", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_nade" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 5, "Bots can nade: " + _temp, ::bot_func, "nade", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_take_carepackages" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 6, "Bots can take carepackages: " + _temp, ::bot_func, "care", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_obj" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 7, "Bots play the objective: " + _temp, ::bot_func, "obj", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_camp" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 8, "Bots can camp: " + _temp, ::bot_func, "camp", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_jumpdrop" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 9, "Bots can jump and dropshot: " + _temp, ::bot_func, "jump", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_target_other" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 10, "Bots can target other script objects: " + _temp, ::bot_func, "targetother", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_killstreak" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 11, "Bots can use killstreaks: " + _temp, ::bot_func, "killstreak", _tempDvar );
	
	_tempDvar = getdvarint( "bots_play_ads" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "set1", 12, "Bots can ads: " + _temp, ::bot_func, "ads", _tempDvar );

	self AddMenu( "Main", 3, "Realism", ::OpenSub, "real1", "" );
	self AddMenu( "Main", 4, "Social", ::OpenSub, "real2", "" );
	self AddBack( "real1", "Main" );
	self AddBack( "real2", "Main" );
	
	_temp = getdvar( "bots_real_preset" );
	self AddMenu( "real1", 0, "Preset: " + _temp, ::bot_real_preset, _temp, "" );
	
	_tempDvar = getdvarint( "bots_real_traits" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 1, "Bots have personalities: " + _temp, ::bot_real_func, "traits", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_aim" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 2, "Bots aim like humans: " + _temp, ::bot_real_func, "aim", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_hearing" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 3, "Bots react to sounds: " + _temp, ::bot_real_func, "hearing", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_retreat" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 4, "Bots retreat when hurt: " + _temp, ::bot_real_func, "retreat", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_counter" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 5, "Bots counter-pick classes: " + _temp, ::bot_real_func, "counter", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_mood" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 6, "Bots get cocky or tilted: " + _temp, ::bot_real_func, "mood", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_airhide" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 7, "Bots hide from air support: " + _temp, ::bot_real_func, "airhide", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_hotspots" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 8, "Bots learn camping spots: " + _temp, ::bot_real_func, "hotspots", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_teamintel" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 9, "Bots share enemy sightings: " + _temp, ::bot_real_func, "teamintel", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_matchaware" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 10, "Bots react to the score: " + _temp, ::bot_real_func, "matchaware", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_slipups" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 11, "Bots make human mistakes: " + _temp, ::bot_real_func, "slipups", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_preaim" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 12, "Bots check corners: " + _temp, ::bot_real_func, "preaim", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_turrets" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 13, "Bots use mounted turrets: " + _temp, ::bot_real_func, "turrets", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_adaptive" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real1", 14, "Bots adapt to your skill: " + _temp, ::bot_real_func, "adaptive", _tempDvar );
	
	self AddMenu( "real1", 15, "Show bot status", maps\mp\bots\_bot_realism::printBotStatus, "", "" );
	
	_tempDvar = getdvarint( "bots_real_chat" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 0, "Bots type like people: " + _temp, ::bot_real_func, "chat", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_banter" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 1, "Bots talk to each other: " + _temp, ::bot_real_func, "banter", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_voice" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 2, "Bots use voice callouts: " + _temp, ::bot_real_func, "voice", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_grudge" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 3, "Bots hold grudges: " + _temp, ::bot_real_func, "grudge", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_avenge" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 4, "Bots avenge teammates: " + _temp, ::bot_real_func, "avenge", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_parties" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 5, "Bots play in parties: " + _temp, ::bot_real_func, "parties", _tempDvar );
	
	_tempDvar = getdvarint( "bots_real_churn" );
	
	if ( _tempDvar )
	{
		_temp = onOff( true );
	}
	else
	{
		_temp = onOff( false );
	}
	
	self AddMenu( "real2", 6, "Bots come and go: " + _temp, ::bot_real_func, "churn", _tempDvar );
}

bot_real_func( a, b )
{
	setdvar( "bots_real_" + a, !b );
	
	// changing a single setting means you're making your own mix now
	setdvar( "bots_real_preset", "custom" );
	
	if ( isdefined( level.bw_real_labels ) && isdefined( level.bw_real_labels[ a ] ) )
	{
		self iprintln( level.bw_real_labels[ a ] + ": " + onOff( !b ) );
	}
}

/*
	Cycles the realism preset: custom, casual, competitive, chaos, off.
*/
bot_real_preset( a, b )
{
	next = "casual";
	
	switch ( a )
	{
		case "casual":
			next = "competitive";
			break;
			
		case "competitive":
			next = "chaos";
			break;
			
		case "chaos":
			next = "off";
			break;
			
		case "off":
			next = "custom";
			break;
	}
	
	setdvar( "bots_real_preset", next );
	self iprintln( "Realism preset: ^3" + next );
}

bot_func( a, b )
{
	switch ( a )
	{
		case "reasonable":
			setdvar( "bots_loadout_reasonable", !b );
			self iprintln( "Bots using reasonable setups: " + onOff( !b ) );
			break;
			
		case "op":
			setdvar( "bots_loadout_allow_op", !b );
			self iprintln( "Bots using op setups: " + onOff( !b ) );
			break;
			
		case "move":
			setdvar( "bots_play_move", !b );
			self iprintln( "Bots move: " + onOff( !b ) );
			break;
			
		case "knife":
			setdvar( "bots_play_knife", !b );
			self iprintln( "Bots knife: " + onOff( !b ) );
			break;
			
		case "fire":
			setdvar( "bots_play_fire", !b );
			self iprintln( "Bots fire: " + onOff( !b ) );
			break;
			
		case "nade":
			setdvar( "bots_play_nade", !b );
			self iprintln( "Bots nade: " + onOff( !b ) );
			break;
			
		case "care":
			setdvar( "bots_play_take_carepackages", !b );
			self iprintln( "Bots take carepackages: " + onOff( !b ) );
			break;
			
		case "obj":
			setdvar( "bots_play_obj", !b );
			self iprintln( "Bots play the obj: " + onOff( !b ) );
			break;
			
		case "camp":
			setdvar( "bots_play_camp", !b );
			self iprintln( "Bots camp: " + onOff( !b ) );
			break;
			
		case "jump":
			setdvar( "bots_play_jumpdrop", !b );
			self iprintln( "Bots jump: " + onOff( !b ) );
			break;
			
		case "targetother":
			setdvar( "bots_play_target_other", !b );
			self iprintln( "Bots target other: " + onOff( !b ) );
			break;
			
		case "killstreak":
			setdvar( "bots_play_killstreak", !b );
			self iprintln( "Bots use killstreaks: " + onOff( !b ) );
			break;
			
		case "ads":
			setdvar( "bots_play_ads", !b );
			self iprintln( "Bots ads: " + onOff( !b ) );
			break;
	}
}

bot_teams( a, b )
{
	switch ( a )
	{
		case "team":
			switch ( b )
			{
				case "autoassign":
					setdvar( "bots_team", "allies" );
					self iprintlnbold( "Changed bot team to allies." );
					break;
					
				case "allies":
					setdvar( "bots_team", "axis" );
					self iprintlnbold( "Changed bot team to axis." );
					break;
					
				case "axis":
					setdvar( "bots_team", "custom" );
					self iprintlnbold( "Changed bot team to custom." );
					break;
					
				default:
					setdvar( "bots_team", "autoassign" );
					self iprintlnbold( "Changed bot team to autoassign." );
					break;
			}
			
			break;
			
		case "teamup":
			setdvar( "bots_team_amount", b + 1 );
			self iprintln( ( b + 1 ) + " bot(s) will try to be on axis team." );
			break;
			
		case "teamdown":
			setdvar( "bots_team_amount", b - 1 );
			self iprintln( ( b - 1 ) + " bot(s) will try to be on axis team." );
			break;
			
		case "teamforce":
			setdvar( "bots_team_force", !b );
			self iprintln( "Forcing bots to team: " + onOff( !b ) );
			break;
			
		case "teammode":
			setdvar( "bots_team_mode", !b );
			self iprintln( "Only count bots on team: " + onOff( !b ) );
			break;
			
		case "skill":
			switch ( b )
			{
				case 0:
					self iprintlnbold( "Changed bot skill to easy." );
					setdvar( "bots_skill", 1 );
					break;
					
				case 1:
					self iprintlnbold( "Changed bot skill to easy-med." );
					setdvar( "bots_skill", 2 );
					break;
					
				case 2:
					self iprintlnbold( "Changed bot skill to medium." );
					setdvar( "bots_skill", 3 );
					break;
					
				case 3:
					self iprintlnbold( "Changed bot skill to med-hard." );
					setdvar( "bots_skill", 4 );
					break;
					
				case 4:
					self iprintlnbold( "Changed bot skill to hard." );
					setdvar( "bots_skill", 5 );
					break;
					
				case 5:
					self iprintlnbold( "Changed bot skill to very hard." );
					setdvar( "bots_skill", 6 );
					break;
					
				case 6:
					self iprintlnbold( "Changed bot skill to hardest." );
					setdvar( "bots_skill", 7 );
					break;
					
				case 7:
					self iprintlnbold( "Changed bot skill to custom. Base is easy." );
					setdvar( "bots_skill", 8 );
					break;
					
				case 8:
					self iprintlnbold( "Changed bot skill to complete random. Takes effect at restart." );
					setdvar( "bots_skill", 9 );
					break;
					
				default:
					self iprintlnbold( "Changed bot skill to random. Takes effect at restart." );
					setdvar( "bots_skill", 0 );
					break;
			}
			
			break;
			
		case "axishardup":
			setdvar( "bots_skill_axis_hard", ( b + 1 ) );
			self iprintln( ( ( b + 1 ) ) + " hard bots will be on axis team." );
			break;
			
		case "axisharddown":
			setdvar( "bots_skill_axis_hard", ( b - 1 ) );
			self iprintln( ( ( b - 1 ) ) + " hard bots will be on axis team." );
			break;
			
		case "axismedup":
			setdvar( "bots_skill_axis_med", ( b + 1 ) );
			self iprintln( ( ( b + 1 ) ) + " med bots will be on axis team." );
			break;
			
		case "axismeddown":
			setdvar( "bots_skill_axis_med", ( b - 1 ) );
			self iprintln( ( ( b - 1 ) ) + " med bots will be on axis team." );
			break;
			
		case "allieshardup":
			setdvar( "bots_skill_allies_hard", ( b + 1 ) );
			self iprintln( ( ( b + 1 ) ) + " hard bots will be on allies team." );
			break;
			
		case "alliesharddown":
			setdvar( "bots_skill_allies_hard", ( b - 1 ) );
			self iprintln( ( ( b - 1 ) ) + " hard bots will be on allies team." );
			break;
			
		case "alliesmedup":
			setdvar( "bots_skill_allies_med", ( b + 1 ) );
			self iprintln( ( ( b + 1 ) ) + " med bots will be on allies team." );
			break;
			
		case "alliesmeddown":
			setdvar( "bots_skill_allies_med", ( b - 1 ) );
			self iprintln( ( ( b - 1 ) ) + " med bots will be on allies team." );
			break;
	}
}

man_bots( a, b )
{
	switch ( a )
	{
		case "add":
			setdvar( "bots_manage_add", b );
			
			if ( b == 1 )
			{
				self iprintln( "Adding " + b + " bot." );
			}
			else
			{
				self iprintln( "Adding " + b + " bots." );
			}
			
			break;
			
		case "kick":
			result = false;
			
			for ( i = 0; i < b; i++ )
			{
				tempBot = random( getBotArray() );
				
				if ( isdefined( tempBot ) )
				{
					kick( tempBot getentitynumber(), "EXE_PLAYERKICKED" );
					result = true;
				}
				
				wait 0.25;
			}
			
			if ( !result )
			{
				self iprintln( "No bots to kick" );
			}
			
			break;
			
		case "autokick":
			setdvar( "bots_manage_fill_kick", !b );
			self iprintln( "Kicking bots when bots_fill is exceeded: " + onOff( !b ) );
			break;
			
		case "fillmode":
			switch ( b )
			{
				case 0:
					setdvar( "bots_manage_fill_mode", 1 );
					self iprintln( "bot_fill will now count only bots." );
					break;
					
				case 1:
					setdvar( "bots_manage_fill_mode", 2 );
					self iprintln( "bot_fill will now count everyone, adjusting to map." );
					break;
					
				case 2:
					setdvar( "bots_manage_fill_mode", 3 );
					self iprintln( "bot_fill will now count only bots, adjusting to map." );
					break;
					
				case 3:
					setdvar( "bots_manage_fill_mode", 4 );
					self iprintln( "bot_fill will now use bots as team balance." );
					break;
					
				case 4:
					setdvar( "bots_manage_fill_mode", 5 );
					self iprintln( "bot_fill will now use bots as team balance, adjusting to map." );
					break;
					
				default:
					setdvar( "bots_manage_fill_mode", 0 );
					self iprintln( "bot_fill will now count everyone." );
					break;
			}
			
			break;
			
		case "fillup":
			setdvar( "bots_manage_fill", b + 1 );
			self iprintln( "Increased to maintain " + ( b + 1 ) + " bot(s)." );
			break;
			
		case "filldown":
			setdvar( "bots_manage_fill", b - 1 );
			self iprintln( "Decreased to maintain " + ( b - 1 ) + " bot(s)." );
			break;
			
		case "fillspec":
			setdvar( "bots_manage_fill_spec", !b );
			self iprintln( "Count players on spectator for bots_fill: " + onOff( !b ) );
			break;
	}
}
