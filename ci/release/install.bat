@echo off
title Bot Warfare XTended installer
echo ==============================================
echo    BOT WARFARE XTENDED 1.1 for PlutoniumIW5
echo ==============================================
echo.
set "IW5=%LOCALAPPDATA%\Plutonium\storage\iw5"
if not exist "%IW5%\" mkdir "%IW5%"
xcopy z_svr_bots.iwd "%IW5%\" /Y
echo.
if exist "%IW5%\bots.txt" (
	echo You already have a bots.txt, keeping your bot names.
	echo To use the XTended names, replace it with the bots.txt from this folder.
) else (
	copy bots.txt "%IW5%\bots.txt" >nul
	echo Installed bots.txt with XTended bot names.
)
echo.
if exist "%IW5%\xtended.cfg" (
	echo You already have an xtended.cfg, keeping your settings.
) else (
	copy xtended.cfg "%IW5%\xtended.cfg" >nul
	echo Installed xtended.cfg. Edit it, then type "exec xtended.cfg" in the console.
)
echo.
echo Installed. Start PlutoniumIW5, load a map and press N for the menu.
pause
