#!/bin/bash
d=`date +%y%m%d%H%M%S`

cp ../../../SavedVariables/PacBankTools.lua ./PacBankTools.lua
lua SavedVartoJson.lua
python3 convertJSONtoCSV.py
rm PacBankTools.lua
rm SavedVarOutput.json

mv guild_history.csv logs/history/guild_history-$d.csv
mv guild_roster.csv logs/roster/guild_roster-$d.csv
mv guild_store.csv logs/store/guild_store-$d.csv