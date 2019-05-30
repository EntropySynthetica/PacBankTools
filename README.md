# Pacrooti's Guild Tools
ESO Addon for Guild Roster Management by Erica Zavaleta, @LadyWinry

# How to Install
* The most recent build can be downloaded from this link,  https://github.com/EntropySynthetica/PacGuildTools/archive/master.zip
* Open the zip and copy the folder to Documents/Elder Scrolls Online/live/AddOns
* Rename the directory from PacGuildTools-Master to PacGuildTools 

# Current Features
* Export Current Guild Roster to Documents/Elder Scrolls Online/live/SavedVariables/PacGuildTools.lua
* Guild Roster Raffle Generator

# Todo
* Spin off raffle tool into it's own seperate addon.  Get it on Minion
* Refactor the code and make sure all variables are in a proper namespace.
* After Elsweyr patch selecting a different guild is currently not working.  The app will default to whatever your first guild is.  

# How to run a raffle
This addon allows you to run raffles, randomly picking a winner.  There are three raffle modes currently supported.

* Participants can sign up to a raffle roster via a magic word.  They simply need to type that word in chat to enter.
* A raffle can be run for all members in a guild.
* A raffle can be run for all online members in a guild. 

Raffle Commands:
/pgt_raffle_online   - Run a raffle with those online in the guild.
/pgt_raffle_guild    - Run a raffle with everyone in the guild.
/pgt_raffle          - Run a raffle with those on the roster.
                
/pgt_raffle_show   Show the raffle roster.
/pgt_rafflw_clear   Clear the Raffle Roster.

* A blank magic word will enter everyone who types in chat.  


# Valid Slash Commands
Opens the Pacrooti's Guild Tools Menu
* /pgt

Runs a raffle               
* /pgt_raffle
Runs a raffle for everyone online in the guild
* /pgt_raffle_online
Runs a raffle for everyone in the guild
* /pgt_raffle_guild

Summons Pacrooti to your position!       
* /summon_pacrooti  

Sends Pacrooti Away
* /dismiss_pacrooti  

