// Slice 0 (test only): shows that this mod's compiled scripts load in game.
//   fmtest_ping()  logs one line on channel 'FMTest'.

exec function fmtest_ping()
{
	LogChannel('FMTest', "PASS fmtest_ping: modFriendlyMeditation scripts are loaded");
}
