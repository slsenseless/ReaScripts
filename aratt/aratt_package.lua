--[[
@description
	ARATT (Automatic Routing And Track Types)
@author
	slsenseless
@license
	GNU GPLv3
@version
	1.2
@links
	GitHub (Source code) https://github.com/slsenseless/aratt
@metapackage
@provides
	[nomain] aratt_package.lua
	[nomain] rtconfig.txt
	[nomain] aratt_core.lua
	[nomain] aratt_template.lua
	[main=main] aratt_Automatic*.lua
	[main=main] aratt_Create*.lua
	[main=main] aratt_Transform*.lua
	[main=main] aratt_ShowHide*.lua
	[main=main] aratt_Remove*.lua
	[main=main] aratt_Assisted*.lua
@about
	# ARATT 
	## What is it ?
	Aratt (Automatic Routing And Track Types) is a package for Reaper which adds track types via template and facilitated routing between tracks.
	## How to install it ?
	You can download scripts via reapack.
	To complete the installation, you will need to customize the default theme :
	- Go to your reaper ressource path (Options -> Show REAPER resource path in explorer/finder) in the ColorThemes folder.
	- Make a copy of Default_6.0.ReaperThemeZip
	- Rename the copy Default_6.0_ARATT.ReaperThemeZip
	- Open it with a file archiver
	- Go to Default_6.0_unpacked
	- Paste the rtconfig.txt (from aratt installation folder) in it
	- Change your theme to Default_6.0_ARATT
--]]