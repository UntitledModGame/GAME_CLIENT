
:: Dev helper file for launching quickly:


::  If you are using VSCode,
::  Put this inside of your `keybindings.json`:
:: {
::     "key": "alt+j",
::     "command": "workbench.action.terminal.sendSequence",
::     "when": "editorTextFocus",
::     "args": {
::         "text": "dev.bat\r"
::     }
:: }



@echo off

start "Server" lovec . "{\"kind\":\"server\",\"localServer\":true}"
start "Client" lovec . "{\"kind\":\"client\",\"localClient\":true}"


