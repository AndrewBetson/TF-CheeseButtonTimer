/**
 * Copyright Andrew Betson.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

float CHEESEBUTTON0_ORIGIN[ 3 ] = { -513.0, -564.0, 231.25 };
float CHEESEBUTTON1_ORIGIN[ 3 ] = { -548.5, 944.0, 256.0 };

bool	g_bCanPlayCheeseSound = true;
int		g_nCheeseSoundPlayNum = 0;

ConVar	sv_cbt_interval;
bool	g_bCBTEnabled = true;

public Plugin myinfo =
{
	name		= "Cheese Button Timer",
	author		= "Andrew \"andrewb\" Betson; thanks to reBane for the suggestion to find the buttons by origin rather than hammerID",
	description	= "Places a timer on the cheese buttons on mcwallmart_g3_winter_256 that gets longer each time either button is pressed.",
	version		= "2.1.2",
	url			= "https://www.github.com/AndrewBetson/TF-CheeseButtonTimer"
};

public void OnPluginStart()
{
	if ( GetEngineVersion() != Engine_TF2 )
	{
		SetFailState( "Cheese Button Timer is only compatible with Team Fortress 2." );
	}

	LoadTranslations( "cheesebuttontimer.phrases" );

	sv_cbt_interval = CreateConVar( "sv_cbt_interval", "15.0", "Number of seconds for cheese button timer length to increase each time the sound is played." );
	AutoExecConfig( true, "cheesebuttontimer" );

	// Command to allow staff to toggle the timer functionality.
	RegAdminCmd( "sm_cbt", Cmd_CBT, ADMFLAG_SLAY );

	HookEvent( "teamplay_round_start", Event_TeamplayRoundBeginOrEnd, EventHookMode_PostNoCopy );
	HookEvent( "teamplay_game_over", Event_TeamplayRoundBeginOrEnd, EventHookMode_PostNoCopy );
}

public void Event_TeamplayRoundBeginOrEnd( Event hEvent, const char[] szName, bool bDontBroadcast )
{
	char szMapName[ PLATFORM_MAX_PATH ];
	GetCurrentMap( szMapName, sizeof( szMapName ) );

	if ( StrEqual( szMapName, "mcwallmart_g3_winter_256" ) )
	{
		if ( StrEqual( szName, "teamplay_round_start" ) )
		{
			HookEntityOutput( "func_button", "OnDamaged", OnButtonDamaged );
		}
		else // teamplay_game_over
		{
			UnhookEntityOutput( "func_button", "OnDamaged", OnButtonDamaged );
		}

		g_bCanPlayCheeseSound = true;
		g_nCheeseSoundPlayNum = 0;
		g_bCBTEnabled = true;
	}
}

Action OnButtonDamaged( const char[] szOutput, int nCallerID, int nActivatorID, float flDelay )
{
	if ( !g_bCBTEnabled )
	{
		return Plugin_Continue;
	}

	// HACK(AndrewB): Caching neither an index nor a ref of these buttons works reliably, so just brute force it.

	float vButtonOrigin[ 3 ];
	GetEntPropVector( nCallerID, Prop_Send, "m_vecOrigin", vButtonOrigin );

	if ( !( GetVectorDistance( vButtonOrigin, CHEESEBUTTON0_ORIGIN ) <= 1.0 || GetVectorDistance( vButtonOrigin, CHEESEBUTTON1_ORIGIN ) <= 1.0 ) )
	{
		return Plugin_Continue;
	}

	if ( g_bCanPlayCheeseSound )
	{
		g_bCanPlayCheeseSound = false;
		g_nCheeseSoundPlayNum++;

		CreateTimer( sv_cbt_interval.FloatValue * g_nCheeseSoundPlayNum, Timer_EnableCheeseSound );

		return Plugin_Continue;
	}

	// HACK(AndrewB): Sometimes the activator ID is -1. I do not know why. I do not care why.
	if ( nActivatorID != -1 )
	{
		CPrintToChat( nActivatorID, "%t", "CBT_ButtonsUnavailable" );
	}

	return Plugin_Handled;
}

Action Timer_EnableCheeseSound( Handle hTimer )
{
	g_bCanPlayCheeseSound = true;
}

Action Cmd_CBT( int nClientID, int nNumArgs )
{
	g_bCBTEnabled = !g_bCBTEnabled;
	CReplyToCommand( nClientID, "%t", g_bCBTEnabled ? "CBT_Enabled" : "CBT_Disabled" );
}
