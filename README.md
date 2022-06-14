# AMXX Custom Weather
The plugin adds the ability to put your own weather effects under each map.

This is version 2.0, since earlier, in the year 2019, I already made this plugin, but I decided to update it and make support for using the plugin as an API for other plugins and adding settings using a JSON file.

Old version: https://vk.com/t3_plugins?w=wall-150066493_599

---
### Requirements
* HLDS, Metamod (or Metamod-P), AMX Mod X 1.9.0 and above

---
### How install
* Source code ***addon_custom_weather.sma*** put in the `scripting` folder
* Include file ***custom_weather.inc*** put in the `scripting\include` folder
* Compile the plugin ***addon_custom_weather.sma***
* Compiled plugin ***addon_custom_weather.amxx*** you need to put it in the `plugins` folder
* JSON file ***zc_weather.json*** put in the `addons\amxmodx\configs` folder
* Restart server or change map
* If everything is done correctly, the plugin is installed

---
### How to use
* Open ***zc_weather.json*** file and watch examples with 2 maps and 1 any map
* Array `any` in JSON file means that all other maps will use these settings
* In `{ }` the settings for the map are specified
* You can specify several settings at once, just do this:

```
"map name": [
  {
    SETTINGS #1
  },
  {
    SETTINGS #2
  },
  {
    SETTINGS #3
  }
]
```
* The settings will be selected randomly from all possible settings for a particular map

---
### JSON fields
* Object `"weather":` responsible for the weather. Possible options: `"rain"` & `"snow"`
* Object `"lighting":` lighting level. Possible options: `""`, `"a-z"`. `""` - Standard lighting level on this map
* Object `"sky":` skies for map. All types of sky should be in the folder: `gfx\env`. You need to specify the sky without these values: `bk, dn, ft, lf, rt, up`
* Object `"fog":` Includes fog
  * Array `"color":` in object `"fog":` responsible for the color of the fog. Specify the color value in RGB
  * Object `"density":` in object `"fog":` responsible for the density of fog. The value must be fractional.

If you do not specify any fields in the JSON file at all, the default values from the map will be used

---
### Natives and stocks
There are several in the ***custom_weather.inc*** file natives and stocks for using in another plugins API.

```Pawn
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
```

I didn't use everything as natives, since there is no need to use natives to expose my data in other plugins. When using native, extra time is used to execute them, so I did it like regular stocks.

To use them in other plugins, it is enough to enable
```Pawn
#include <custom_weather>
```
