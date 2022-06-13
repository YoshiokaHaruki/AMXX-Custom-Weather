#if defined _custom_weather_included
	#endinput
#endif
#define _custom_weather_included

new const PluginPrefix[ ] =		"Custom Weather";

/**
 * Reset all weather effects to default value
 * The default value is the one that was selected at the start of the map
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * 
 * @return						Returns 'true' if all effects was reseted
 */
native bool: zc_reset_weather_effects( const pReceiver = 0 );

/**
 * Set specific value for lighting level
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * @param szLightingLevel		Lighting Level ("" - Default by map, a-z - Specific)
 * 
 * @return						Returns 'true' if lighting level was setted
 */
stock bool: zc_set_lighting( const pReceiver = 0, const szLightingLevel[ ] = "" )
{
	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
		UTIL_SetLightingLevel( pReceiver == 0 ? MSG_ALL : MSG_ONE, pReceiver, szLightingLevel );
	else
	{
		log_amx( "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

/**
 * Reset ligthting level to default value
 * The default value is the one that was selected at the start of the map
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * 
 * @return						Returns 'true' if lighting level was reseted
 */
native bool: zc_reset_lighting( const pReceiver = 0 );

/**
 * Set specific value for weather
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * @param iWeatherMode			Weather Mode (0 - none, 1 - rain, 2 - snow)
 * 
 * @return						Returns 'true' if weather was setted
 */
stock bool: zc_set_weather( const pReceiver = 0, const iWeatherMode = 0 )
{
	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
		UTIL_ReceiweW( pReceiver == 0 ? MSG_ALL : MSG_ONE, pReceiver, iWeatherMode );
	else
	{
		log_amx( "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

/**
 * Reset weather mode to default value
 * The default value is the one that was selected at the start of the map
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * 
 * @return						Returns 'true' if weather was reseted
 */
native zc_reset_weather( const pReceiver = 0 );

/**
 * Set specific value of fog
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 * @param iColor				Color of fog (RGB)
 * @param flDensity				Density of fog
 * 
 * @return						Returns 'true' if weather was setted
 */
stock bool: zc_set_fog( const pReceiver = 0, const iColor[ 3 ] = { 0, 0, 0 }, const Float: flDensity = 0.0 )
{
	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
		UTIL_Fog( pReceiver == 0 ? MSG_ALL : MSG_ONE, pReceiver, iColor, flDensity );
	else
	{
		log_amx( "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

/**
 * Reset fog to default value
 * The default value is the one that was selected at the start of the map
 * 
 * @param pReceiver				Player Index (If 0 - reset to all, any - reset to concrete player)
 */
native zc_reset_fog( const pReceiver = 0 );

/* ~ [ Stocks ] ~ */
stock UTIL_SetLightingLevel( const iDest, const pReceiver , const szLightingLevel[ ] )
{
	message_begin( iDest, SVC_LIGHTSTYLE, .player = pReceiver );
	write_byte( 0 );
	write_string( szLightingLevel );
	message_end( );
}

stock UTIL_ReceiweW( const iDest, const pReceiver, const iWeatherMode )
{
	static iMsgId_ReceiweW; if ( !iMsgId_ReceiweW ) iMsgId_ReceiweW = get_user_msgid( "ReceiveW" );

	message_begin( iDest, iMsgId_ReceiweW, .player = pReceiver );
	write_byte( iWeatherMode ); // [ 0: None | 1: Rain | 2: Snow ]
	message_end( );
}

stock UTIL_Fog( const iDest, const pReceiver, const iColor[ 3 ], const Float: flDensity )
{
	static iMsgId_Fog; if ( !iMsgId_Fog ) iMsgId_Fog = get_user_msgid( "Fog" );

	message_begin( iDest, iMsgId_Fog, .player = pReceiver );
	write_byte( iColor[ 0 ] );
	write_byte( iColor[ 1 ] );
	write_byte( iColor[ 2 ] );
	write_density( flDensity );
	message_end( )
}

// ty PRoSToTeM@
// https://forums.alliedmods.net/showpost.php?p=1626640&postcount=20
stock write_density( Float: flDensity )
{
	static bitPattern; bitPattern = ( 1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7 );

	write_byte( _:flDensity & ( bitPattern ) );
	write_byte( ( _:flDensity>>8 ) & ( bitPattern ) );
	write_byte( ( _:flDensity>>16 ) & ( bitPattern ) );
	write_byte( ( _:flDensity>>24 ) & ( bitPattern ) );
}
