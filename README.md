# OBS-VirtualChat
Write to text source , using **only** keyboard.

# MCOSU full screen example
[see demo ](virtualchatdemo.webm )
# Setup

- download ,add it via Tools > Scripts > + button
- create hotkeys for on/off. Search for "Restart" and "Stop" in settings 

# Usage 

- Restart hotkey clears buffer and hooks keyboard
- Stop hotkey clears buffer , updates text source to be empty.
- Enter will show all characters that has been registered since restart was pressed. 
- Backspace - delete one character . Note : repeat delay e.g pressed down , will only delete one character regardless of how long it has been pressed down.

# Limitations

only English (ANSI characters) currently supported , but keys can be remapped and added , see
keyboard_layout table and this file:
https://github.com/obsproject/obs-studio/blob/master/libobs/obs-hotkeys.h

# How it works 
First its generates keyboard settings in json , then its creates mapping to callbacks
for characters with shift and without, then on Restart button hooks keyboard_layout mapping,
and until enter is not pressed (or Restart itself) it's accumulate text , on enter updates 
text source with that. 

# Contribute
- add keyboard layouts for other languages
- report bugs , suggest ideas , etc.
