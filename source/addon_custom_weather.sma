public stock const PluginName[ ] =		"Addon: Custom Weather";
public stock const PluginVersion[ ] =	"2.1";
public stock const PluginAuthor[ ] =	"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <json>
#include <custom_weather>

/* ~ [ Plugin Settings ] ~ */
const TaskId_UpdateWeather =			9250; // Change this value if conflict with another tasks
new const WeatherConfigFile[ ] =		"zc_weather.json";

/* ~ [ Params ] ~ */
enum eWeatherData {
	bool: eWeather_FogEnabled,
	eWeather_Type,
	eWeather_FogColor[ 3 ],
	Float: eWeather_FogDensity,
	eWeather_LightingLevel[ 2 ],
	eWeather_SkyName[ MAX_NAME_LENGTH ]
};
new Array: gl_arWeatherData;

new gl_FM_Hook_LightStyle_Pre;
new gl_aWeatherData[ eWeatherData ];

/* ~ [ Macroses ] ~ */
#define MAX_INFO_LENGTH					64
#define MAX_CONFIG_PATH_LENGHT			128
#define IsNullString(%0)				bool: ( %0[ 0 ] == EOS )

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( "zc_reset_weather_effects", "native_reset_weather_effects" );
	register_native( "zc_reset_lighting", "native_reset_lighting" );
	register_native( "zc_reset_weather", "native_reset_weather" );
	register_native( "zc_reset_fog", "native_reset_fog" );
}

public plugin_precache( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Array's <- */
	gl_arWeatherData = ArrayCreate( eWeatherData );

	/* -> Load JSON Data <- */
	JSON_Weather_LoadData( );
}

public plugin_init( )
{
	/* -> Forward's <- */
	unregister_forward( FM_LightStyle, gl_FM_Hook_LightStyle_Pre, false );
}

public client_putinserver( pPlayer )
{
	/**
	 * Because it is impossible to send these messages 
	 * immediately after the player enters the server
	 */
	set_task( 0.1, "CTask__UpdateWeather", TaskId_UpdateWeather + pPlayer );
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_LightStyle_Pre( )
{
	engfunc( EngFunc_LightStyle, 0, gl_aWeatherData[ eWeather_LightingLevel ] );
	return FMRES_SUPERCEDE;
}

/* ~ [ Other ] ~ */
public bool: CWeather__SetData( )
{
	new iArraySize = ArraySize( gl_arWeatherData );
	if ( !iArraySize )
		return false;

	ArrayGetArray( gl_arWeatherData, random( iArraySize ), gl_aWeatherData );

	gl_FM_Hook_LightStyle_Pre = register_forward( FM_LightStyle, "FM_Hook_LightStyle_Pre", false );

	if ( !IsNullString( gl_aWeatherData[ eWeather_SkyName ] ) )
	{
		UTIL_PrecacheSkies( gl_aWeatherData[ eWeather_SkyName ] );
		set_cvar_string( "sv_skyname", gl_aWeatherData[ eWeather_SkyName ] );
	}

	ArrayDestroy( gl_arWeatherData );
	return true;
}

/* ~ [ Tasks ] ~ */
public CTask__UpdateWeather( const iTaskId )
{
	static pPlayer; pPlayer = iTaskId - TaskId_UpdateWeather;

	UTIL_ReceiweW( MSG_ONE, pPlayer, gl_aWeatherData[ eWeather_Type ] );

	if ( gl_aWeatherData[ eWeather_FogEnabled ] )
		UTIL_Fog( MSG_ONE, pPlayer, gl_aWeatherData[ eWeather_FogColor ], gl_aWeatherData[ eWeather_FogDensity ] );

	remove_task( iTaskId );
}

/* ~ [ JSON ] ~ */
public JSON_Weather_LoadData( )
{
	new szConfigsDir[ MAX_CONFIG_PATH_LENGHT ];
	get_localinfo( "amxx_configsdir", szConfigsDir, charsmax( szConfigsDir ) );
	strcat( szConfigsDir, fmt( "/%s", WeatherConfigFile ), charsmax( szConfigsDir ) );

	if ( !file_exists( szConfigsDir ) )
	{
		set_fail_state( "[%s] Invalid open file: ^"%s^"", PluginPrefix, szConfigsDir );
		return;
	}

	new JSON: JSON_Handle = json_parse( szConfigsDir, true );
	if ( JSON_Handle == Invalid_JSON )
	{
		set_fail_state( "[%s] Invalid read file: ^"%s^"", PluginPrefix, szConfigsDir );
		return;
	}

	new iJsonSize = json_object_get_count( JSON_Handle );
	if ( !iJsonSize )
	{
		json_free( JSON_Handle );

		set_fail_state( "[%s] File ^"%s^" is empty.", PluginPrefix, szConfigsDir );
		return;
	}

	new aWeatherData[ eWeatherData ], szBuffer[ MAX_INFO_LENGTH ];
	new szMapName[ MAX_INFO_LENGTH ];

	new bool: bMapFinded = false;
	new iJsonMapSize, iJsonColorSize;
	new JSON: JSON_MapObject = Invalid_JSON;
	new JSON: JSON_MapArray = Invalid_JSON;
	new JSON: JSON_FogObject = Invalid_JSON;
	new JSON: JSON_FogColor = Invalid_JSON;

	#if defined _reapi_included
		rh_get_mapname( szMapName, charsmax( szMapName ), MNT_TRUE );
	#else
		get_mapname( szMapName, charsmax( szMapName ) );
	#endif

	for ( new i = 0; i < iJsonSize; i++ )
	{
		json_object_get_name( JSON_Handle, i, szBuffer, charsmax( szBuffer ) );
		if ( IsNullString( szBuffer ) || szBuffer[ 0 ] == '#' )
			continue;

		if ( ( ( containi( szMapName, szBuffer ) != -1 ) && ( bMapFinded = true ) ) || equali( szBuffer, "any" ) && !bMapFinded )
		{
			JSON_MapObject = json_object_get_value( JSON_Handle, szBuffer );
			if ( JSON_MapObject == Invalid_JSON )
				continue;

			iJsonMapSize = json_array_get_count( JSON_MapObject );
			for ( new j = 0; j < iJsonMapSize; j++ )
			{
				JSON_MapArray = json_array_get_value( JSON_MapObject, j );
				if ( JSON_MapArray != Invalid_JSON )
				{
					if ( json_object_has_value( JSON_MapArray, "weather", JSONString ) )
					{
						json_object_get_string( JSON_MapArray, "weather", szBuffer, charsmax( szBuffer ) );
						aWeatherData[ eWeather_Type ] = equal( szBuffer, "rain" ) ? 1 : equal( szBuffer, "snow" ) ? 2 : 0;
					}
					else aWeatherData[ eWeather_Type ] = 0;

					if ( json_object_has_value( JSON_MapArray, "fog", JSONObject ) )
					{
						JSON_FogObject = json_object_get_value( JSON_MapArray, "fog" );
						if ( JSON_FogObject != Invalid_JSON )
						{
							aWeatherData[ eWeather_FogEnabled ] = true;

							if ( json_object_has_value( JSON_FogObject, "color", JSONArray ) )
							{
								JSON_FogColor = json_object_get_value( JSON_FogObject, "color" );
								if ( JSON_FogColor != Invalid_JSON )
								{
									iJsonColorSize = clamp( json_array_get_count( JSON_FogColor ), 0, 3 );
									for ( new k = 0; k < iJsonColorSize; k++ )
										aWeatherData[ eWeather_FogColor ][ k ] = clamp( json_array_get_number( JSON_FogColor, k ), 0, 255 );

									json_free( JSON_FogColor );
								}
							}

							if ( json_object_has_value( JSON_FogObject, "density", JSONNumber ) )
								aWeatherData[ eWeather_FogDensity ] = json_object_get_real( JSON_FogObject, "density" );
							else aWeatherData[ eWeather_FogDensity ] = 0.0;

							json_free( JSON_FogObject );
						}
					}
					else aWeatherData[ eWeather_FogEnabled ] = false;

					if ( json_object_has_value( JSON_MapArray, "lighting", JSONString ) )
						json_object_get_string( JSON_MapArray, "lighting", aWeatherData[ eWeather_LightingLevel ], charsmax( aWeatherData[ eWeather_LightingLevel ] ) );
					else aWeatherData[ eWeather_LightingLevel ] = EOS;

					if ( json_object_has_value( JSON_MapArray, "sky", JSONString ) )
						json_object_get_string( JSON_MapArray, "sky", aWeatherData[ eWeather_SkyName ], charsmax( aWeatherData[ eWeather_SkyName ] ) );
					else aWeatherData[ eWeather_SkyName ] = EOS;

					ArrayPushArray( gl_arWeatherData, aWeatherData );
					UTIL_ClearColorList( aWeatherData[ eWeather_FogColor ] );

					json_free( JSON_MapArray );
				}
			}

			json_free( JSON_MapObject );
		}

		if ( bMapFinded )
			break;
	}

	json_free( JSON_Handle );

	CWeather__SetData( );
}

/* ~ [ Natives ] ~ */
public bool: native_reset_weather_effects( const iPlugin, const iParams )
{
	enum { arg_receiver = 1 };

	static pReceiver; pReceiver = get_param( arg_receiver );
	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
	{
		static iDest; iDest = pReceiver == 0 ? MSG_ALL : MSG_ONE;

		UTIL_SetLightingLevel( iDest, pReceiver, gl_aWeatherData[ eWeather_LightingLevel ] );
		UTIL_ReceiweW( iDest, pReceiver, gl_aWeatherData[ eWeather_Type ] );
		UTIL_Fog( iDest, pReceiver, gl_aWeatherData[ eWeather_FogColor ], gl_aWeatherData[ eWeather_FogDensity ] );
	}
	else
	{
		log_error( AMX_ERR_NATIVE, "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

public bool: native_reset_lighting( const iPlugin, const iParams )
{
	enum { arg_receiver = 1 };

	return zc_set_lighting( get_param( arg_receiver ), gl_aWeatherData[ eWeather_LightingLevel ] );
}

public bool: native_reset_weather( const iPlugin, const iParams )
{
	enum { arg_receiver = 1 };

	static pReceiver; pReceiver = get_param( arg_receiver );
	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
		UTIL_ReceiweW( pReceiver == 0 ? MSG_ALL : MSG_ONE, pReceiver, gl_aWeatherData[ eWeather_Type ] );
	else
	{
		log_error( AMX_ERR_NATIVE, "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

public bool: native_reset_fog( const iPlugin, const iParams )
{
	enum { arg_receiver = 1 };

	static pReceiver; pReceiver = get_param( arg_receiver );

	if ( pReceiver == 0 || is_user_connected( pReceiver ) )
		UTIL_Fog( pReceiver == 0 ? MSG_ALL : MSG_ONE, pReceiver, gl_aWeatherData[ eWeather_FogColor ], gl_aWeatherData[ eWeather_FogDensity ] );
	else
	{
		log_error( AMX_ERR_NATIVE, "[%s] Invalid Player (%i)", PluginPrefix, pReceiver );
		return false;
	}

	return true;
}

/* ~ [ Stocks ] ~ */
stock UTIL_ClearColorList( iColor[ ] )
	iColor[ 0 ] = iColor[ 1 ] = iColor[ 2 ] = 0;

stock UTIL_PrecacheSkies( const szSkies[ ] )
{
	new const szTags[ ][ ] = { "bk", "dn", "ft", "lf", "rt", "up" };

	for ( new i, iSize = sizeof( szTags ); i < iSize; i++ )
		engfunc( EngFunc_PrecacheGeneric, fmt( "gfx/env/%s%s.tga", szSkies, szTags[ i ] ) );
}
