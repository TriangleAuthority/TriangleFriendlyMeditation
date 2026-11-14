modFriendlyMeditation
=====================
by wghost81 aka Wasteland Ghost


This mod requires UPatch (or Community Patch - Base) installed to work properly.

Description:
============

The mod introduces real time meditation into the game: start meditation as usual or press a hotkey for Geralt to assume meditation pose and time begin to fast-forward. No menu cluttering the view, meditation is as immersive as it can possibly be.

While vanilla meditation simply clears all buffs and advances time, real time meditation actually updates all buffs, toxicity, etc in accelerated time as you meditate. This means that all potions and skills like Sun and Stars continue to function properly during meditation, restoring your health.

Same as vanilla, real time meditation also refills all your alchemy after you've meditated for an hour.

Real time meditation uses special fully configurable camera with three presets available in the options menu: camera facing Geralt, "sightseeing" camera and default exploration camera with larger FOV (field of view). You can switch special camera off if you don't like it.

There are several modes for meditation hotkey: in hold mode Geralt meditates for as long as you hold the button; in switch mode you hold the button to start meditation and then hold the button again when you decide to end it; in manual mode meditation hotkey is used to assume meditation pose and another hotkey is used to advance time - you can use this one for enjoying the scenery with "sightseeing" camera preset.

Note: This mod doesn't change your save files, so installing or uninstalling it in the middle of playthrough is safe.

Default key bindings:
=====================

"Hold N" ("Hold controller Right Thumb") - real time meditation.
"Hold Space" ("Hold controller Left Thumb") - advance time.
"Press End" - toggle campfire spawning on/off.
"Press C" ("Press controller Y") - stop meditation when in meditation menu.

Configuration:
==============

All mod options are configurable directly from in-game menu - look for "Mods" and "Friendly Meditation" entries.

Installation:
=============

It's recommended to use The Witcher 3 Mod Manager (TW3MM) available on Nexus for installing the mod. TW3MM installs all parts of the mod automatically, no additional manual steps are needed.

Note that Nexus Mod Manager (NMM) doesn't support installing new menus and hotkeys, so additional manual steps are required for NMM users (see below)!

Resolving conflicts with other mods
===================================

If you have other mods installed, use Script Merger to find and resolve conflicts. Note that some of the mods on Nexus might not support the latest patch and thus are incompatible nor with this mod not with the current game version in general. Also note that you need to re-merge all your merges after updating any of the mods to a newer version.

Manual installation:
====================

1. Creating backups (optional)

If you have vanilla version of the game, backup your "[Path To The Witcher 3]\bin\config" folder as some of the mods (including this one) make changes to configuration files and it won't hurt to have vanilla version in case you will need to quickly clean up all your mods.

2. Installing core mod files

Install core package by unpacking the mod and copying an entire "modFriendlyMeditation" folder to "[Path To The Witcher 3]\Mods" folder. If "Mods" folder doesn't exist, create it first. You can use NMM for this step, but make sure you also perform all the steps below.

3. Installing in-game menu and new hotkeys

For in-game menu to work you need modFMeditationConfig.xml to be in your "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc" folder.

For new hotkeys to work, they have to be added to your "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc\input.xml" file.

3.1. Quick install

If you don't have any other mods which add new hotkeys installed, simply copy "[Path To The Witcher 3]\Mods\modFriendlyMeditation\bin" folder into your "[Path To The Witcher 3]" folder. A window will pop up, asking if you want to replace existing input.xml file, if you're doing everything right. Choose "overwrite" to replace vanilla input.xml with the modded one.

3.2. Step by step install

If you have other mod(s) installed which add new hotkeys, you most probably don't want to replace your existing input.xml. To install new hotkeys in this case open your existing "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc\input.xml" file and modded "[Path To The Witcher 3]\Mods\modFriendlyMeditation\bin\config\r4game\user_config_matrix\pc\input.xml" file and manually copy modFriendlyMeditation changes (they are marked with "modFriendlyMeditation begin" and "modFriendlyMeditation end" comments) into the same part of your existing input.xml file.

Also copy "[Path To The Witcher 3]\Mods\modFriendlyMeditation\bin\config\r4game\user_config_matrix\pc\modFMeditationConfig.xml" file into "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc" folder to install in-game menu.

4. Initializing mod default settings and hotkeys

Mod settings are stored in "C:\Users\[Your Username]\Documents\The Witcher 3\user.settings".

Key bindings are stored in "C:\Users\[Your Username]\Documents\The Witcher 3\input.settings".

To initialize default settings open both "C:\Users\[Your Username]\Documents\The Witcher 3\user.settings" and "[Path To The Witcher 3]\Mods\modFriendlyMeditation\user.settings.part.txt" file from the mod, select everything inside "user.settings.part.txt" and copy and paste it at the beginning of "user.settings" file. Note that if you miss this step, most of the mod's options will be off and the mod will appear to be not functioning properly.

To initialize key bindings open both "C:\Users\[Your Username]\Documents\The Witcher 3\input.settings" and "[Path To The Witcher 3]\Mods\modFriendlyMeditation\input.settings.part.txt" file from the mod, select everything inside "input.settings.part.txt" and copy and paste it at the beginning of "input.settings" file. Note that if you miss this step, you will see hotkeys in game menu, but you will be unable to assign them properly.

5. Resolving conflicts with other mods

If you have other mods installed, use Script Merger to find and resolve conflicts. Note that some of the mods on Nexus might not support the latest patch and thus are incompatible nor with this mod not with the current game version in general. Also note that you need to re-merge all your merges after updating any of the mods to a newer version.

Updating:
=========

It is always safer, both when updating manually and with TW3MM/NMM, to remove previous mod version (and make sure "[Path To The Witcher 3]\Mods\modFriendlyMeditation" folder was indeed deleted) and install it anew. No other steps but installing core mod files are needed, if changelog for the new version has no new menu options and no new bindings mentioned.

If there were changes to hotkeys in a new version, safest way to upgrade is to delete your "C:\Users\[Your Username]\Documents\The Witcher 3\input.settings", run the game once to create a default one and then repeat steps 3 and 4 of the install process, described above.

If there were changes to menu options in a new version, safest way to upgrade is to delete your "C:\Users\[Your Username]\Documents\The Witcher 3\user.settings", run the game once to create a default one and then repeat steps 3 and 4 of the install process, described above.

Warning! Deleting input.settings and user.settings files will reset your input and game settings to defaults, so you'll need to restore your preferred setting after doing so!

If you have other mods installed, un-merge your existing merges in ScriptMerger and re-merge everything again.

Uninstallation:
===============

If you've installed the mod using TW3MM, simply choose uninstall option an it will handle uninstalling all the parts of the mod.

Do not forget to run Script Merger to fix your merged files.

Manual uninstallation:
======================

1. Uninstalling core mod files

You can either uninstall the mod with NMM or manually delete "[Path To The Witcher 3]\Mods\modFriendlyMeditation" folder.

2. Uninstalling menu and hotkeys

To remove in-game menu you need to delete modFMeditationConfig.xml from your "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc" folder.

To remove new hotkeys, you have to delete them from your "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc\input.xml" file.

2.1. Quick uninstall using backup

If you have backup of your vanilla "[Path To The Witcher 3]\bin\config" folder and have no other mods installed which change configuration files, simply delete your "[Path To The Witcher 3]\bin\config" folder and copy backup "config" folder in its place.

2.2. Step by step uninstall

To remove key bindings you need to open "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc\input.xml" file and delete everything in between "modFriendlyMeditation begin" and "modFriendlyMeditation end" comments.

To remove menu options simply delete "[Path To The Witcher 3]\bin\config\r4game\user_config_matrix\pc\modFMeditationConfig.xml" file.

3. Conflicts with other mods

If you have this mod merged with the others, you will need to re-merge remaining mods after uninstalling this one.
