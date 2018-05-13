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
  exports.activeServer = bot.guilds.first()  #TODO: track which server commands are coming from
  console.log(exports.activeServer.name)
  exports.mahjongGames = []
  exports.parlors = [] #Created channels
)

# Create an event listener for messages
bot.on('message', (message) =>
  if (message.content.substring(0, 1) in ["!","/"])
    commandArgs = message.content.substring(1).split(" ")

    if(commandArgs[0] == "roll")
      message.channel.send("#{message.author.username} rolled: "+dice.rollDice(commandArgs[1..].join("")))

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

        chatChannel = message.channel.guild.createChannel(commandArgs[1]+"GroupChat","text",userPermissions)
          .then((channel) ->
            return channel)
          .catch(console.error)

        channelHolder = []
        for i in [0..3]
          temp = message.channel.guild.createChannel(
            commandArgs[1]+"Player"+(i+1),
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
            exports.mahjongGames.push(new mahjongGame(allChannels, message.channel.guild, {}))
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

    if(commandArgs[0] == "ragnarok")
      message.channel.send("Let's Ragnarok!!!!!")
      for x in exports.parlors
        x.delete()
      exports.parlors = []
      exports.mahjongGames = []

    if(commandArgs[0] == "tiles")
      message.channel.send(mahjongTiles.allTilesGetter())

    if(commandArgs[0] == "score")
      inputTiles = commandArgs[1..28]
      testHand = new mahjongTiles.Hand(new mahjongTiles.Pile())
      for x in [0...14]
        testHand.contains.push(new mahjongTiles.Tile(inputTiles[2*x],inputTiles[2*x+1]))
      testHand.draw(null,0)
      console.log(mahjongScoring.getPossibleHands(testHand))


    #TODO: make game commands work with game objects
  if(exports.mahjongGames.length > 0)
    commandArgs = message.content.split(" ")
    channelType = "none"
    fromChannel = message.channel
    for game in exports.mahjongGames
      if(fromChannel.id == game.gameObservationChannel.id)
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
      if(commandArgs[0] == "abort" and commandArgs[1] == "game" and channelType == "player")
        #TODO Delete game
        fromGame.gameObservationChannel.sendMessage("Game Ended")
      if(commandArgs[0] == "turn")
        message.channel.send("It is player #{fromGame.turn}'s turn.")
      if(commandArgs[0] == "phase")
        message.channel.send("It is the #{fromGame.phase} phase.")
      if(commandArgs[0] == "prevailing")
        message.channel.send("The prevailing wind is #{fromGame.prevailingWind}.")
      if(commandArgs[0] == "dora")
        if(channelType == "player")
          message.channel.send("Dora Indicator: #{fromGame.wall.printDora(fromPlayer.namedTiles)}")
        else
          message.channel.send("Dora Indicator: #{fromGame.wall.printDora()}")
      if(commandArgs[0] == "hand" and channelType == "player")
        message.channel.send("Hand: #{fromPlayer.printHand()}")
      if(commandArgs[0] == "toggle" and channelType == "player")
        fromPlayer.toggleTiles()
      if(commandArgs[0] == "draw" and channelType == "player")
        fromGame.drawTile(fromPlayer)
      if(commandArgs[0] == "discard" and channelType == "player")
        fromGame.discardTile(fromPlayer,commandArgs[1]+" "+commandArgs[2])
      if(commandArgs[0] == "pon" and channelType == "player")
        fromGame.ponTile(fromPlayer)
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

  #console.log(exports)
)
## Log our bot in
bot.login(token)

## Keepalive loop for Heroku
http = require("http")
setInterval(
  () ->
    http.get("http://akagibot.herokuapp.com")
  300000
)
