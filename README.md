# Akagi-Bot
赤木

A Discord bot that runs a game of riichi mahjong.

Akagi-Bot uses the rules outlined in the [European Mahjong Association's 2016 rulebook](http://mahjong-europe.org/portal/images/docs/Riichi-rules-2016-EN.pdf) as a guide.  If you notice a discrepancy, please document it and open a Github issue, or better yet fix it and open a pull request.  

WIP.

Currently contains the following commands:
'#' means it is currently being worked on and doesn't work
~ means it only works in mahjong channels

~draw - Draws a tile for the active players

~discard - Needs name of tile to discard.  Discards the specified tile from the hand of the active player.

~hand - Only usable in player channel.  Looks at the tiles in that player's hand.

~remaining - Only usable in player channel.  Looks at the tiles in that player's hand which have yet to be melded.

~melds - If given a player number, looks at the tiles a player has melded.  If used alone, looks at own called tiles.

~tenpai - Tells you if you are in tenpai, and which tiles will make you win, if you are.

~furiten - Tells you if you are in furiten, and which tiles are keeping you there if you are.

~pile - If given a player number, looks at the tiles in the discard pile of that player. If used alone, looks at your own discard pile.

~toggle - Turns off or on the written form of the tiles. Only usable by players.

~abort game - Currently does nothing, but claims the game is over

~next - Used after a round is over, in order to start next round.

~riichi - Used to declare riichi, takes the tile to be discarded as its argument

~pon - Allows one to Pon players discards.

~chi - Allows one to Chi.  Takes 4 arguments, the two tiles you are forming the meld with from your hand.

~kan - Allows one to Kan players discards.  If done on your turn, requires the tile you want to Kan as an argument.

~tsumo - Allows one to win off of self draw.

!tiles - Displays a picture of each tile.

~dora - Displays all current dora indicators.

~prevailing - Displays prevailing wind

~seat - If given a number, returns the seat wind of that player.  Without an argument, it returns one's own seat wind.

~turn - Displays who's turn it is.

~phase - Displays what phase it is.

~wall - Displays how many tiles are left in the live wall.

~points - Gives you the points every player currently has in the round.

~sticks - Tells how many riichi sticks are available.

~counters - Tells how many counters have built up.

!forge - Takes one argument.  Makes a channel with the argument as its name. People mentioned are able to see the channel.

!mahjong - Takes one argument, and at least 3 mentions.  Makes a channel for poster and each of the first three mentions, as well as a group channel that everyone mentioned can see, and starts a game of mahjong.  

!yell - Takes any number of arguments.  Outputs those arguments to all forged channels.

!ragnarok - Deletes all forged channels that exist in server where the command is issued

!score - Gives a list of ways of interpreting a hand of mahjong.  Takes 28 arguments.

!roll - Rolls dice in the XdY+AdB-V-CdD sorta format
