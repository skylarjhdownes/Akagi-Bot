## Import the discord.js module
Discord = require('discord.js');
mahjongTiles = require('./akagiTiles.coffee')
mahjongGame = require('./akagiGame.coffee')
mahjongPlayer = require('./akagiPlayer.coffee')
dice = require('./akagiDice.coffee')
mahjongScoring = require('./akagiScoring.coffee')
_ = require('./node_modules/lodash/lodash.js')
Promise = require('promise')

## Create an instance of a Discord client
bot = new Discord.Client()

## The token of your bot - https://discordapp.com/developers/applications/me
token = process.env.AKAGI_BOT_TOKEN
debugId = process.env.AKAGI_DEBUG_ID

#Usable for debugging if source of message is unclear.
sendID = (placeOfSending, toPrint) ->
  placeOfSending.send("#{debugId}"+toPrint)

## The ready event is vital, it means that your bot will only start reacting to information
## from Discord _after_ ready is emitted
bot.on('ready', =>
  console.log('Logged in as %s - %s\n', bot.user.username, bot.user.id)
  console.log('I am ready!')
  exports.activeServers = bot.guilds.array()
  for value in exports.activeServers
    console.log(value.name)
  exports.mahjongGames = []
  exports.parlors = [] #Created channels
)

# Create an event listener for messages
bot.on('message', (message) =>
  if (message.content.substring(0, 1) in ["!","/"])
    commandArgs = message.content.substring(1).split(/\s+/)
    commandArgs = _.map(commandArgs,_.toLower)

    if(commandArgs[0] == "roll")
      message.channel.send("#{message.author.username} rolled: "+dice.rollDice(commandArgs[1..].join("")))

    if(commandArgs[0] == "f")
      message.channel.send("#{message.author.username} has paid their respects.")

    if(commandArgs[0] == "throw")
      if(commandArgs[1] in ["rock","paper","scissors"])
        akagiThrow = Math.floor(Math.random()*3) #Zero is rock, One is paper, two is scissors
        if(commandArgs[1] == "rock")
          if(akagiThrow == 0)
            message.channel.send("Rock. Tie.")
          if(akagiThrow == 1)
            message.channel.send("Paper. You lose.")
          if(akagiThrow == 2)
            message.channel.send("Scissors. You win.")
        if(commandArgs[1] == "paper")
          if(akagiThrow == 0)
            message.channel.send("Rock. You win.")
          if(akagiThrow == 1)
            message.channel.send("Paper. Tie.")
          if(akagiThrow == 2)
            message.channel.send("Scissors. You lose.")
        if(commandArgs[1] == "scissors")
          if(akagiThrow == 0)
            message.channel.send("Rock. You lose.")
          if(akagiThrow == 1)
            message.channel.send("Paper. You win.")
          if(akagiThrow == 2)
            message.channel.send("Scissors. Tie.")
      else
        message.channel.send("Use rock, paper, or scissors.")


    if(commandArgs[0] == "help")
      if(commandArgs.length == 1)
        message.channel.send("Type '!help akagi' to learn about mahjong specific commands.  Type '!help general' to learn about commands that can be used anywhere.")
      else if(commandArgs[1] == "general")
        message.channel.send("Type '!help X' where X is the command you want to learn about.  The general commands are: roll, mahjong, english, value, and tiles.")
      else if(commandArgs[1] == "mahjong")
        message.channel.send("Used to start a new game of mahjong.  Type '!mahjong Y @a @b @c' where Y is the game name, and a, b, and c are players you want to play with.")
      else if(commandArgs[1] == "roll")
        message.channel.send("Used to roll dice.  Type '!rollXdY' where X is the number of dice, and Y is the number of sides.  You can also add and subtract other dice, or add and subtract constant numbers.")
      else if(commandArgs[1] == "tiles")
        message.channel.send("Prints out the unicode text of all of the mahjong tiles in riichi mahjong.")
      else if(commandArgs[1] == "english")
        message.channel.send("Gives you the english translation of the japanese yaku.")
      else if(commandArgs[1] == "tiles")
        message.channel.send("Gives the fan value of a yaku.  Input must use the japanese name.")
      else if(commandArgs[1] == "akagi")
        message.channel.send("""Type '!help X' where X is the command you want to learn about.
                              Mahjong commands may only be used in channels created by Akagi-Bot.
                              The mahjong commands are: draw, discard, hand, remaining, melds, tenpai, furiten, pile, toggle, end, next, riichi, pon, chi, kan, tsumo, ron, dora, seat, turn, phase, wall, points, sticks, and counters.""")
      else if(commandArgs[1] == "draw")
        message.channel.send("Draws a tile for you if it is currently your draw phase.")
      else if(commandArgs[1] == "discard")
        message.channel.send("""Syntax: discard <tile name>
                              Examples: \"discard red dragon\", \"discard 2 sou\", \"discard north wind\"
                              Discard a tile from your hand if it is currently your discard phase.""")
      else if(commandArgs[1] == "hand")
        message.channel.send("Display your hand.")
      else if(commandArgs[1] == "remaining")
        message.channel.send("Displays the tiles in your hand that are not part of called melds.")
      else if(commandArgs[1] == "melds")
        message.channel.send("""Syntax: melds <player number>
                              Examples: \"melds\", \"melds 1\", \"melds 3\"
                              Displays the tiles in either your or another player's hand that are part of called melds.""")
      else if(commandArgs[1] == "tenpai")
        message.channel.send("""Tells you if you are in tenpai, and which tiles will make you win if you are.
                              Being in tenpai means it is possible to complete your hand with the addition of a single tile""")
      else if(commandArgs[1] == "furiten")
        message.channel.send("""Tells you if you are in furiten, and which tiles are keeping you there if you are.
                              Being in furiten means that you have discarded a tile that would have otherwise completed your hand.
                              A player who is furiten cannot win on an opponent's discard, but can only win by self-drawing the needed tile.""")
      else if(commandArgs[1] == "pile")
        message.channel.send("""Syntax: pile <player number>
                              Examples: \"pile\", \"pile 1\", \"pile 3\"
                              Displays your discard pile, or the pile of another player.""")
      else if(commandArgs[1] == "toggle")
        message.channel.send("""Syntax: toggle <tiles || help>
                              Typing \"toggle tiles\" will toggle the display of tile text, ex. \"green dragon 🀅\" -> \"🀅\".
                              Typing \"toggle help\" will toggle help suggestions.""")
      else if(commandArgs[1] == "end")
        message.channel.send("Typing \"end game\" will end the game and destroy all game channels.")
      else if(commandArgs[1] == "play")
        message.channel.send("Typing \"play again\" after the game has finished will start a new game of mahjong.")
      else if(commandArgs[1] == "next")
        message.channel.send("Start the next round.")
      else if(commandArgs[1] == "riichi")
        message.channel.send("""Syntax: riichi <tile name>
                              Examples: \"riichi green dragon\", \"riichi 3 wan\", riichi 7 sou\"
                              Declare riichi.  Takes the tile to be discarded as its argument.""")
      else if(commandArgs[1] == "pon")
        message.channel.send("Declare pon on the last discarded tile.")
      else if(commandArgs[1] == "chi")
        message.channel.send("""Syntax: chi <tile name> <tile name>
                              Examples: \"chi 2 sou 4 sou\", \"chi 8 wan 9 wan\"
                              Declare chi on the last discarded tile.""")
      else if(commandArgs[1] == "kan")
        message.channel.send("""Syntax: kan [<tile name>]
                              Examples: \"kan\", \"kan 1 wan\", \"kan west wind\"
                              Declare kan on the last discarded tile, or on a tile in your hand.""")
      else if(commandArgs[1] == "tsumo")
        message.channel.send("Declare tsumo on a drawn tile.")
      else if(commandArgs[1] == "ron")
        message.channel.send("Declares ron on a discarded tile, or on the kan of a tile that would finish your hand.")
      else if(commandArgs[1] == "dora")
        message.channel.send("Prints out all the dora indicators that have been revealed this hand.")
      else if(commandArgs[1] == "seat")
        message.channel.send("""Syntax: seat <player number>
                              Examples: \"seat\", \"seat 1\", \"seat 3\"
                              Displays your seat wind, or the seat wind of another player.""")
      else if(commandArgs[1] == "turn")
        message.channel.send("Prints the player number of the person who's turn it is.")
      else if(commandArgs[1] == "phase")
        message.channel.send("Prints the phase that the game is currently in.")
      else if(commandArgs[1] == "wall")
        message.channel.send("Prints out how many tiles remain in the wall.")
      else if(commandArgs[1] == "points")
        message.channel.send("Prints out everyone's current points for the round.")
      else if(commandArgs[1] == "sticks")
        message.channel.send("Prints out the number of riichi sticks currently on the field.")
      else if(commandArgs[1] == "counters")
        message.channel.send("Prints out the number of 300 point counters currently on the field.")
      else if(commandArgs[1] in [])
        message.channel.send("Help text currently unavailable for this command.")
      else
        message.channel.send("Command not recognized.  Try typing !help to get a list of commands.")

    if(commandArgs[0] == "mahjong")
      playersToAddToGame = message.mentions.members.array()
      if (playersToAddToGame.length < 3)
        message.channel.send("Please @ mention at least 3 other users to play in your game.")
      else
        playersToAddToGame.unshift(message.author)

        userPermissions = [
          {type:'role', id:message.channel.guild.defaultRole.id, deny: Discord.Permissions.FLAGS.VIEW_CHANNEL}
        ]
        for gameObserver,i in playersToAddToGame
          if(i<4)
            userPermissions.push({type:'member', id:gameObserver.id, allow: Discord.Permissions.FLAGS.VIEW_CHANNEL+Discord.Permissions.FLAGS.MANAGE_ROLES})
          else
            userPermissions.push({type:'member', id:gameObserver.id, allow: Discord.Permissions.FLAGS.VIEW_CHANNEL})

        chatChannel = message.channel.guild.createChannel(commandArgs[1]+"-Mahjong-Table-Center","text",userPermissions)
          .then((channel) ->
            return channel)
          .catch(console.error)

        channelHolder = []
        for i in [0..3]
          temp = message.channel.guild.createChannel(
            commandArgs[1]+"-Mahjong-Hand-Player-"+(i+1),
            "text",
            [
              {type:'role', id:message.channel.guild.defaultRole.id, deny: Discord.Permissions.FLAGS.VIEW_CHANNEL},
              {type:'member', id:playersToAddToGame[i].id, allow: Discord.Permissions.FLAGS.VIEW_CHANNEL+Discord.Permissions.FLAGS.MANAGE_ROLES}
            ]
            )
            .then((channel) ->
              console.log("Hapa")
              return channel
              )
            .catch(console.error)
          channelHolder.push(temp)

        Promise.all([chatChannel,channelHolder[0],channelHolder[1],channelHolder[2],channelHolder[3]])
          .then((allChannels) ->
            exports.mahjongGames.push(new mahjongGame(allChannels, message.channel.guild, []))
            for channel in allChannels
              exports.parlors.push(channel)
            bot.user.setStatus('online','Mahjong')
            )
          .catch(console.error)

    if(commandArgs[0] == "forge")
      usersMentioned = message.mentions.members
      console.log(usersMentioned.array().length)
      message.channel.guild.createChannel(commandArgs[1],"text")
        .then((channel) ->
          channel.overwritePermissions(message.channel.guild.defaultRole, {READ_MESSAGES: false})
            .then(console.log("Hidden!!"))
            .catch(console.error)
          channel.overwritePermissions(message, {READ_MESSAGES: true, MANAGE_CHANNELS: true})
            .then(console.log("Revealed!!"))
            .catch(console.error)
          for x in usersMentioned.array()
            channel.overwritePermissions(x, {READ_MESSAGES: true})
              .then(console.log(x.displayName))
              .catch(console.error)
          exports.parlors.push(channel))
        .catch(console.error)

    if(commandArgs[0] == "yell")
      for x in exports.parlors
        x.send(commandArgs[1..])

    if(commandArgs[0] == "english")
      yaku = _.map(commandArgs[1..],_.capitalize).join(" ")
      message.channel.send(mahjongScoring.yakuList[yaku].eng)

    if(commandArgs[0] == "value")
      yaku = _.map(commandArgs[1..],_.capitalize).join(" ")
      message.channel.send(mahjongScoring.yakuList[yaku].score)

    if(commandArgs[0] == "ragnarok")
      if message.channel.type == "text"
        message.channel.send("Let's Ragnarok!!!!!")
        exports.mahjongGames = (game for game in exports.mahjongGames when game.gameObservationChannel.guild.id != message.guild.id)
        for x in exports.parlors when x.guild.id == message.guild.id
          x.delete()
        exports.parlors = (parlor for parlor in exports.parlors when parlor.guild.id != message.guild.id)
      else
        message.channel.send("Can't Ragnarok outside a server.  :(")

    if(commandArgs[0] == "nuke")
      #Testing utility. Should only run on our specific testing Discord.
      console.log(message.guild.name)
      if message.channel.type == "text" && message.guild.name == "Akagi's Mahjong Parlor"
        message.channel.send("Launching...")
        for channel in message.guild.channels.array()
          console.log(channel.name)
          if(channel.type == "text" && channel.name != "general")
            channel.delete()

    if(commandArgs[0] == "tiles")
      message.channel.send(mahjongTiles.allTilesGetter())

    if(commandArgs[0] == "score")
      inputTiles = commandArgs[1..28]
      testHand = new mahjongTiles.Hand(new mahjongTiles.Pile())
      for x in [0...14]
        testHand.contains.push(new mahjongTiles.Tile(inputTiles[2*x+1],inputTiles[2*x]))
      testHand.draw(null,0)
      testHand.lastTileDrawn = new mahjongTiles.Tile(inputTiles[27],inputTiles[26])
      console.log(mahjongScoring.getPossibleHands(testHand))


  if(exports.mahjongGames.length > 0)
    commandArgs = message.content.split(/\s+/)
    commandArgs = _.map(commandArgs,_.toLower)
    channelType = "none"
    fromChannel = message.channel
    for game in exports.mahjongGames
      if(message.author.bot)
        channelType = "bot"
      else if(fromChannel.id == game.gameObservationChannel.id)
        channelType = "public"
        fromGame = game
      else
        for player in game.players
          if(fromChannel.id == player.playerChannel.id)
            channelType = "player"
            fromGame = game
            fromPlayer = player
    if(channelType == "player" or channelType == "public")
      #Game Commands
      if(commandArgs[0] == "end" and commandArgs[1] == "game" and channelType == "player")
        fromGame.gameObservationChannel.sendMessage("Game Ended")
        exports.mahjongGames = (game for game in exports.mahjongGames when fromGame.gameObservationChannel.id != game.gameObservationChannel.id)
        for player in fromGame.players
          exports.parlors = (parlor for parlor in exports.parlors when parlor.id != player.playerChannel.id)
          player.playerChannel.delete()
        exports.parlors = (parlor for parlor in exports.parlors when parlor.id != fromGame.gameObservationChannel.id)
        fromGame.gameObservationChannel.delete()
      if(commandArgs[0] == "play" and commandArgs[1] == "again" and channelType = "player")
        if(fromGame.phase != "finished")
          message.channel.send("Game not finished.  Please finish your first game before starting another.")
        else
          fromGame.startNewGame()
      if(commandArgs[0] == "next" && channelType == "player")
        if(fromGame.phase != "finished")
          message.channel.send("Round is not yet finished.")
        else
          fromGame.newRound()
      if(commandArgs[0] == "turn")
        message.channel.send("It is player #{fromGame.turn}'s turn.")
      if(commandArgs[0] == "wall")
        message.channel.send("There are #{fromGame.wall.leftInWall()} tiles left in the the live wall.")
      if(commandArgs[0] == "sticks")
        message.channel.send("There are currently #{fromGame.riichiSticks.length} riichi sticks present.")
      if(commandArgs[0] == "counters")
        message.channel.send("There are currently #{fromGame.counter} counters built up.")
      if(commandArgs[0] == "phase")
        message.channel.send("It is the #{fromGame.phase} phase.")
      if(commandArgs[0] == "prevailing")
        message.channel.send("The prevailing wind is #{fromGame.prevailingWind}.")
      if(commandArgs[0] == "seat")
        if(commandArgs.length == 1 and channelType == "player")
          fromPlayer.sendMessage("Your seat wind is #{fromPlayer.wind}.")
        else if(commandArgs[1] in ["1","2","3","4"])
          message.channel.send("Player #{commandArgs[1]} is the #{fromGame.players[commandArgs[1]-1].wind} player.")
      if(commandArgs[0] == "dora")
        if(channelType == "player")
          message.channel.send("Dora Indicator(s): #{fromGame.wall.printDora(fromPlayer.namedTiles)}")
        else
          message.channel.send("Dora Indicator(s): #{fromGame.wall.printDora()}")
      if(commandArgs[0] == "hand" and channelType == "player")
        message.channel.send("Hand: #{fromPlayer.printHand()}")
      if(commandArgs[0] == "remaining" and channelType == "player")
        message.channel.send("Remaining: #{fromPlayer.printUncalled()}")
      if(commandArgs[0] == "melds")
        if(commandArgs.length == 1 and channelType == "player")
          fromPlayer.sendMessage("Your melds are: #{fromPlayer.printMelds(fromPlayer.namedTiles)}")
        else if (commandArgs[1] in ["1","2","3","4"])
          if(channelType == "player")
            fromPlayer.sendMessage("Player #{commandArgs[1]} has the following melds: #{fromGame.players[commandArgs[1]-1].printMelds(fromPlayer.namedTiles)}.")
          else
            message.channel.send("Player #{commandArgs[1]} has the following melds: #{fromGame.players[commandArgs[1]-1].printMelds()}.")
        else
          message.channel.send("Please select a real player.")
      if(commandArgs[0] == "tenpai" and channelType == "player")
        if(fromPlayer.hand.contains.length != 13)
          message.channel.send("Can only check for tenpai when your hand has 13 tiles.")
        else
          tenpaiTiles = mahjongScoring.tenpaiWith(fromPlayer.hand)
          if(tenpaiTiles.length == 0)
            message.channel.send("You are not in tenpai.")
          else
            message.channel.send("You are in tenpai, waiting on #{x.getName(fromPlayer.namedTiles) for x in tenpaiTiles}.")
      if(commandArgs[0] == "furiten" and channelType == "player")
        if(fromPlayer.hand.contains.length != 13)
          message.channel.send("Can only check for furiten when your hand has 13 tiles.")
        else
          furitenTiles = fromGame.furiten(fromPlayer)
          if(!furitenTiles)
            message.channel.send("You are not in furiten.")
          else
            message.channel.send("You are in furiten, because of the following tiles: #{x.getName(fromPlayer.namedTiles) for x in furitenTiles}")
      if(commandArgs[0] == "toggle" and channelType == "player")
        if(commandArgs[1] == "tiles")
          fromPlayer.toggleTiles()
        else if(commandArgs[1] == "help")
          fromPlayer.toggleHelp()
        else
          fromPlayer.sendMessage("You may toggle 'tiles' or 'help'.")
      if(commandArgs[0] == "draw" and channelType == "player")
        fromGame.drawTile(fromPlayer)
      if(commandArgs[0] == "discard" and channelType == "player")
        fromGame.discardTile(fromPlayer,commandArgs[1]+" "+commandArgs[2])
      if(commandArgs[0] == "riichi" and channelType == "player")
        fromGame.discardTile(fromPlayer,commandArgs[1]+" "+commandArgs[2],true)
      if(commandArgs[0] == "pon" and channelType == "player")
        fromGame.ponTile(fromPlayer)
      if(commandArgs[0] == "kan" and channelType == "player")
        if(fromGame.phase != "discard")
          fromGame.openKanTiles(fromPlayer)
        else if(fromGame.phase == "discard" && commandArgs.length == 3)
          fromGame.selfKanTiles(fromPlayer,new mahjongTiles.Tile(commandArgs[2],commandArgs[1]))
        else
          fromPlayer.sendMessage("Please specify which tile to Kan.")
      if(commandArgs[0] == "chi" and channelType == "player")
        if(commandArgs.length != 5)
          message.channel.send("Must specify which two tiles are to be used for meld.")
        else
          tile1 = new mahjongTiles.Tile(commandArgs[2],commandArgs[1])
          tile2 = new mahjongTiles.Tile(commandArgs[4],commandArgs[3])
          fromGame.chiTile(fromPlayer,tile1,tile2)
      if(commandArgs[0] == "tsumo" and channelType == "player")
        fromGame.tsumo(fromPlayer)
      if(commandArgs[0] == "ron" and channelType == "player")
        fromGame.ron(fromPlayer)
      if(commandArgs[0] == "pile")
        if(commandArgs.length == 1 and channelType == "player")
          fromPlayer.sendMessage("You have discarded #{fromPlayer.hand.discardPile.printDiscard(fromPlayer.namedTiles)}.")
        else if(commandArgs[1] in ["1","2","3","4"])
          if(channelType == "player")
            fromPlayer.sendMessage("Player #{commandArgs[1]} has discarded #{fromGame.players[commandArgs[1]-1].hand.discardPile.printDiscard(fromPlayer.namedTiles)}.")
          else
            message.channel.send("Player #{commandArgs[1]} has discarded #{fromGame.players[commandArgs[1]-1].hand.discardPile.printDiscard()}.")
        else
          message.channel.send("Please select a real discard pile.")
      if(commandArgs[0] == "points")
        for player in fromGame.players
          message.channel.send("Player #{player.playerNumber} has #{player.roundPoints} points.")

  #console.log(exports)
)
## Log our bot in
bot.login(token).catch(console.error("Couldn't log in to Discord.  Is the token correct?"))

## Keepalive loop for Heroku
http = require("http")
setInterval(
  () ->
    http.get("http://akagibot.herokuapp.com")
  300000
)
