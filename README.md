# Akagi-Bot
赤木

A Discord bot that runs a game of riichi mahjong.

Akagi-Bot is meant to follow the rules outlined in the [European Mahjong Association's 2016 rulebook](http://mahjong-europe.org/portal/images/docs/Riichi-rules-2016-EN.pdf).  If you notice a discrepancy, please document it and open a Github issue, or better yet fix it and open a pull request.  

WIP.

Currently contains the following commands:
'#' means it is currently being worked on and doesn't work
~ means it only works in mahjong channels

#!draw - Draws a tile for the active players

#!discard - Needs name of tile to discard.  Discards the specified tile from the hand of the active player.

~hand - Only usable in player channel.  Looks at the tiles in that player's hand.

#!pile - Needs a player number.  Looks at the tiles in the discard pile of that player.

#!toggle writing - Turns off or on the written form of the tiles.

~abort game - Currently does nothing, but claims the game is over

!tiles - Displays a picture of each tile.

~dora - Displays all current dora indicators.

~prevailing - Displays prevailing wind

~turn - Displays who's turn it is.

~phase - Displays what phase it is.

!forge - Takes one argument.  Makes a channel with the argument as its name. People mentioned are able to see the channel.

!mahjong - Takes one argument, and at least 3 mentions.  Makes a channel for poster and each of the first three mentions, as well as a group channel that everyone mentioned can see, and starts a game of mahjong.  

!yell - Takes any number of arguments.  Outputs those arguments to all forged channels.

!ragnarok - Deletes all forged channels.  

!roll - Rolls dice in the XdY+AdB-V-CdD sorta format
