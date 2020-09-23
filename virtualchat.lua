-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
-- Author upgradeQ , project homepage github.com/upgradeQ/OBS-VirutalChat
local obs = obslua
local ffi = require("ffi")

text_data = {buffer="",duration=0,show=false,lock=false}
source_name = ''
prop_duration = 3
shift_state = false
hotkeys = {
	htk_stop = "Stop virtual text",
	htk_restart = "Restart and clear virtual text",
}
hk = {}

keyboard_layout = {
{id="OBS_KEY_ASCIITILDE",c="`",cs="~"},
{id ="OBS_KEY_COMMA",c=",",cs="<"},
{id ="OBS_KEY_PLUS",c="=",cs="+"},
{id ="OBS_KEY_MINUS",c="-",cs="_"},
{id ="OBS_KEY_BRACKETLEFT",c="[",cs="{"},
{id ="OBS_KEY_BRACKETRIGHT",c="]",cs="}"},
{id ="OBS_KEY_PERIOD",c=".",cs=">"},
{id ="OBS_KEY_APOSTROPHE",c="'",cs='"'},
{id ="OBS_KEY_SEMICOLON",c=";",cs=":"},
{id ="OBS_KEY_SLASH",c="/",cs="?"},
{id ="OBS_KEY_SPACE",c=" ",cs=" "},
{id ="OBS_KEY_0",c="0",cs=")"},
{id ="OBS_KEY_1",c="1",cs="!"},
{id ="OBS_KEY_2",c="2",cs="@"},
{id ="OBS_KEY_3",c="3",cs="#"},
{id ="OBS_KEY_4",c="4",cs="$"},
{id ="OBS_KEY_5",c="5",cs="%"},
{id ="OBS_KEY_6",c="6",cs="^"},
{id ="OBS_KEY_7",c="7",cs="&"},
{id ="OBS_KEY_8",c="8",cs="*"},
{id ="OBS_KEY_9",c="9",cs="("},
{id ="OBS_KEY_A",c="a",cs="A"},
{id ="OBS_KEY_B",c="b",cs="B"},
{id ="OBS_KEY_C",c="c",cs="C"},
{id ="OBS_KEY_D",c="d",cs="D"},
{id ="OBS_KEY_E",c="e",cs="E"},
{id ="OBS_KEY_F",c="f",cs="F"},
{id ="OBS_KEY_G",c="g",cs="G"},
{id ="OBS_KEY_H",c="h",cs="H"},
{id ="OBS_KEY_I",c="i",cs="I"},
{id ="OBS_KEY_J",c="j",cs="J"},
{id ="OBS_KEY_K",c="k",cs="K"},
{id ="OBS_KEY_L",c="l",cs="L"},
{id ="OBS_KEY_M",c="m",cs="M"},
{id ="OBS_KEY_N",c="n",cs="N"},
{id ="OBS_KEY_O",c="o",cs="O"},
{id ="OBS_KEY_P",c="p",cs="P"},
{id ="OBS_KEY_Q",c="q",cs="Q"},
{id ="OBS_KEY_R",c="r",cs="R"},
{id ="OBS_KEY_S",c="s",cs="S"},
{id ="OBS_KEY_T",c="t",cs="T"},
{id ="OBS_KEY_U",c="u",cs="U"},
{id ="OBS_KEY_V",c="v",cs="V"},
{id ="OBS_KEY_W",c="w",cs="W"},
{id ="OBS_KEY_X",c="x",cs="X"},
{id ="OBS_KEY_Y",c="y",cs="Y"},
{id ="OBS_KEY_Z",c="z",cs="Z"},
}

json_s = '{'

for _,v in pairs(keyboard_layout) do 
  form_c = '"htk_id%s_id": [ { "key": "%s" } ],'
  form_cs = '"htk_id_shift%s_id": [ { "key": "%s","shift":true } ],'
  
  local id = v.id
  json_s = json_s .. form_c:format(id,id)
  json_s = json_s .. form_cs:format(id,id)
  _G['__' .. id] = function(pressed)
    if pressed and not shift_state then to_buffer(v.c) end
    end

  _G['__' .. id .. '_shift'] = function(pressed)
    if pressed then to_buffer(v.cs) end
    end
end

backspace_key = '"htk_idbackspace": [ { "key": "OBS_KEY_BACKSPACE" } ],'
json_s = json_s .. backspace_key

if ffi.os == "Windows" then
  enter_key = '"htk_identer": [ { "key": "OBS_KEY_RETURN" } ],'
else
  enter_key = '"htk_identer": [ { "key": "OBS_KEY_BACKSLASH" } ],'
end

json_s = json_s .. enter_key
shift_key_last = '"htk_idshift": [ { "key": "OBS_KEY_NONE", "shift": true }]}'
json_s = json_s .. shift_key_last

function shift_callback(pressed) 
  if pressed then
    shift_state = true
  else 
    shift_state = false
  end
end

function backspace_callback(pressed) 
  if pressed then
    text_data.buffer = text_data.buffer:sub(1,-2)
  end
end

function enter_callback(pressed) 
  if pressed then
    if text_data.show then 
      text_data.duration = prop_duration 
      text_data.lock = false
      update_text(text_data.buffer)
    end
  end
end

-- needs to be defined after callbacks has been defined
special_keys = {
  {id='htk_idshift',des='Shift',callback=shift_callback},
  {id='htk_idbackspace',des='Delete one char',callback=backspace_callback},
  {id='htk_identer',des='Send text',callback=enter_callback},
}

function to_buffer(text)
  if text_data.lock and text_data.duration>0 then
    text_data.buffer = text_data.buffer .. text
  end
end

function hotkey_mapping(hotkey)
  if hotkey == "htk_stop" then
    text_data.lock = false
    text_data.show = false
    text_data.duration = 0
  elseif hotkey == "htk_restart" then
    text_data.lock = true
    text_data.buffer = ''
    text_data.duration = 86400
    text_data.show = true
  end
end

function clear_buffer()
  if text_data.buffer ~= '' then

    local source = obs.obs_get_source_by_name(source_name)
    source_id = obs.obs_source_get_unversioned_id(source)

    if source_id == "text_ft2_source" then
      text_data.buffer = ' ' -- notice space, OBS cant set empty string to ft2
    else
      text_data.buffer = ''
    end

    update_text(text_data.buffer)
    obs.obs_source_release(source)
  end
end

function duration_watcher()
  if text_data.duration <1 then 
    clear_buffer()
    text_data.lock = true
  else 
    text_data.duration = text_data.duration - 1
  end
end

function update_text(text)
  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", text)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
  end
end

function script_load(settings)
  obs.timer_add(duration_watcher,1000) -- on start begin checking duration

  -- automatically generate OBS_HOTKEY_CHARACTER and _shift based on keyboard_layout
  s = obs.obs_data_create_from_json(json_s)
  for _,v in pairs(keyboard_layout) do 
    name_c = 'htk_id' .. v.id .. '_id'
    name_cs = 'htk_id_shift' .. v.id .. '_id'
    local ca = obs.obs_data_get_array(s, name_c)

    -- htk_id_OBS_KEY_Q_id,  OBS_KEY_Q,   __OBS_KEY_Q
    htk_c = obs.obs_hotkey_register_frontend(name_c,v.id,_G['__' .. v.id ])
    obs.obs_hotkey_load(htk_c,ca)

    -- htk_id_shiftOBS_KEY_Q_id_shift , OBS_KEY_Q_shift,    __OBS_KEY_Q_shift 
    htk_cs = obs.obs_hotkey_register_frontend(name_cs,v.id .. "_shift",_G['__' .. v.id .. '_shift'])
    local csa = obs.obs_data_get_array(s, name_cs)
    obs.obs_hotkey_load(htk_cs,csa)

    obs.obs_data_array_release(ca)
    obs.obs_data_array_release(csa)
  end

  -- same for special keys
  for _,v in pairs(special_keys) do 
    a = obs.obs_data_get_array(s,v.id)
    h = obs.obs_hotkey_register_frontend(v.id,v.des,v.callback)
    obs.obs_hotkey_load(h,a)
    obs.obs_data_array_release(a)
  end

  obs.obs_data_release(s)

  -- you can rebind those 
  for k, v in pairs(hotkeys) do 
    hk[k] = obs.obs_hotkey_register_frontend(k, v, function(pressed)
    if pressed then hotkey_mapping(k) end end)
    local a = obs.obs_data_get_array(settings, k)
    obs.obs_hotkey_load(hk[k], a)
    obs.obs_data_array_release(a)
  end
end

function script_save(settings)
  for k, v in pairs(hotkeys) do
    local a = obs.obs_hotkey_save(hk[k])
    obs.obs_data_set_array(settings, k, a)
    obs.obs_data_array_release(a)
  end
end

function script_properties()
  local props = obs.obs_properties_create()
  local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
  local sources = obs.obs_enum_sources()
  if sources ~= nil then
    for _, source in ipairs(sources) do
      source_id = obs.obs_source_get_unversioned_id(source)
      if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
        local name = obs.obs_source_get_name(source)
        obs.obs_property_list_add_string(p, name, name)
      end
    end
  end
  obs.source_list_release(sources)

  obs.obs_properties_add_int(props,"_int","Text duration",3,24*60*60,1)
  return props
end

function script_update(settings)
  source_name = obs.obs_data_get_string(settings, "source")
  prop_duration = obs.obs_data_get_int(settings,"_int")
end
