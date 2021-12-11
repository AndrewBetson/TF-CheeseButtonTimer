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

#pragma semicolon 1
#pragma newdecls required

const int CHEESEBUTTON_0_HAMMERID = 3261827;
const int CHEESEBUTTON_1_HAMMERID = 3271925;

int		g_nCheeseButton0Idx = -1;
int		g_nCheeseButton1Idx = -1;
bool	g_bCanPlayCheeseSound = true;
int		g_nCheeseSoundPlayNum = 0;

ConVar	sv_cbt_interval;
bool	g_bCBTEnabled = true;

public Plugin myinfo =
{
	name		= "Cheese Button Timer",
	author		= "Andrew \"andrewb\" Betson",
	description	= "Places a timer on the cheese buttons on mcwallmart_g3_winter_256 that gets 15 seconds longer each time either button is pressed.",
	version		= "1.1.5",
	url			= "https://www.github.com/AndrewBetson/TF-CheeseButtonTimer"
};

public void OnPluginStart()
{
	if ( GetEngineVersion() != Engine_TF2 )
	{
		SetFailState( "Cheese Button Timer is only compatible with Team Fortress 2." );
	}

	sv_cbt_interval = CreateConVar( "sv_cbt_interval", "15.0", "Number of seconds for cheese button timer length to increase each time the sound is played." );
	AutoExecConfig( true, "cheesebuttontimer" );

	// Command to allow staff to toggle the timer functionality.
	RegAdminCmd( "sm_cbt", Cmd_CBT, ADMFLAG_SLAY );

	HookEvent( "teamplay_game_over", Event_TeamplayGameOver, EventHookMode_PostNoCopy );
}

public void TF2_OnWaitingForPlayersStart()
{
	char szMapName[ PLATFORM_MAX_PATH ];
	GetCurrentMap( szMapName, sizeof( szMapName ) );

	if ( StrEqual( szMapName, "mcwallmart_g3_winter_256" ) )
	{
		HookEntityOutput( "func_button", "OnDamaged", OnButtonDamaged );

		// Get the indices of the two cheese buttons.
		int nEntIdx = -1;
		while( ( nEntIdx = FindEntityByClassname( nEntIdx, "func_button" ) ) != INVALID_ENT_REFERENCE )
		{
			// These don't have targetnames so we have to find them by hammerID.
			int nEntHammerID = GetEntProp( nEntIdx, Prop_Data, "m_iHammerID" );
			if ( nEntHammerID == CHEESEBUTTON_0_HAMMERID )
			{
				g_nCheeseButton0Idx = nEntIdx;
			}

			if ( nEntHammerID == CHEESEBUTTON_1_HAMMERID )
			{
				g_nCheeseButton1Idx = nEntIdx;
			}
		}

		g_bCanPlayCheeseSound = true;
		g_nCheeseSoundPlayNum = 0;
	}
}

public Action Event_TeamplayGameOver( Event hEvent, const char[] szName, bool bDontBroadcast )
{
	char szMapName[ PLATFORM_MAX_PATH ];
	GetCurrentMap( szMapName, sizeof( szMapName ) );

	if ( StrEqual( szMapName, "mcwallmart_g3_winter_256" ) )
	{
		// NOTE(AndrewB): Not sure if this is actually needed, or if the hook gets implicitly removed when TF2_OnWaitingForPlayersStart gets called again...
		UnhookEntityOutput( "func_button", "OnDamaged", OnButtonDamaged );
	}
}

Action OnButtonDamaged( const char[] szOutput, int nCallerID, int nActivatorID, float flDelay )
{
	// Not a cheese button; don't care.
	if ( !( nCallerID == g_nCheeseButton0Idx || nCallerID == g_nCheeseButton1Idx ) || !g_bCBTEnabled )
	{
		return Plugin_Continue;
	}

	if ( g_bCanPlayCheeseSound )
	{
		g_bCanPlayCheeseSound = false;
		g_nCheeseSoundPlayNum++;

		CreateTimer( sv_cbt_interval.FloatValue * g_nCheeseSoundPlayNum, Timer_EnableCheeseSound );

		AcceptEntityInput( g_nCheeseButton0Idx, "Lock", 0, 0, 0 );
		AcceptEntityInput( g_nCheeseButton1Idx, "Lock", 0, 0, 0 );

		return Plugin_Continue;
	}

	return Plugin_Handled;
}

Action Timer_EnableCheeseSound( Handle hTimer )
{
	g_bCanPlayCheeseSound = true;

	AcceptEntityInput( g_nCheeseButton0Idx, "Unlock", 0, 0, 0 );
	AcceptEntityInput( g_nCheeseButton1Idx, "Unlock", 0, 0, 0 );
}

Action Cmd_CBT( int nClientID, int nNumArgs )
{
	g_bCBTEnabled = !g_bCBTEnabled;
	ReplyToCommand( nClientID, "[SM]: %s", g_bCBTEnabled ? "Enabled CBT" : "Disabled CBT" );
}
