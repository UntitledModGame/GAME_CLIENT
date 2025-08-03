
:: Dev helper file for launching quickly:


::  If you are using VSCode,
::  Put this inside of your `keybindings.json`:
@REM {
@REM     "key": "alt+j",
@REM     "command": "workbench.action.terminal.sendSequence",
@REM     "when": "editorTextFocus",
@REM     "args": {
@REM         "text": "dev.bat\r"
@REM     }
@REM }



@echo off

start "Server" lovec . --server
start "Client" lovec .

