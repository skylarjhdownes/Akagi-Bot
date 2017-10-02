## Import the discord.js module
Discord = require('discord.js');
mahjongTiles = require('./akagiTiles.coffee')
mahjongGame = require('./akagiGame.coffee')
mahjongPlayer = require('./akagiPlayer.coffee')
dice = require('./akagiDice.coffee')
_ = require('./node_modules/lodash/lodash.js')
Promise = require('promise')

## Create an instance of a Discord client
bot = new Discord.Client()

## The token of your bot - https://discordapp.com/developers/applications/me
token = process.env.BOT_TOKEN

## The ready event is vital, it means that your bot will only start reacting to information
## from Discord _after_ ready is emitted
bot.on('ready', =>
  console.log('Logged in as %s - %s\n', bot.user.username, bot.user.id)
  console.log('I am ready!')
  exports.floppyAngels = bot.guilds.first()  #TODO: track which server commands are coming from
  console.log(exports.floppyAngels.name)
  exports.mahjongGames = []
  exports.parlors = [] #Created channels
  exports.recentDiscard = false
  exports.phase = "draw"
  exports.writeTiles = true
)

# Create an event listener for messages
bot.on('message', (message) =>
  if (message.content.substring(0, 1) == "!")
    commandArgs = message.content.substring(1).split(" ")

    if(commandArgs[0] == "roll")
      message.channel.send(dice.rollDice(commandArgs[1]))

    if(commandArgs[0] == "start")
      playersToAddToGame = message.mentions.members.array()
      if (playersToAddToGame.length != 3)
        message.channel.send("Please @ mention 3 other players to play in your game.")
      else
        playersToAddToGame.push(message.author)
        exports.mahjongGames.push(new mahjongGame(playersToAddToGame, {}))
        newGame = _.last(exports.mahjongGames)
        bot.user.setStatus('online','Mahjong')

        for player in newGame.players
          player.hand.startDraw(newGame.wall)
        newGame.wall.doraFlip()

        message.channel.send("Let the games begin!\n
          The dora indicator is: #{newGame.wall.printDora(exports.writeTiles)}\n
          The prevailing wind is: #{newGame.prevailingWind}")

    if(commandArgs[0] == "forge")
      usersMentioned = message.mentions.members
      console.log(usersMentioned.array().length)
      exports.floppyAngels.createChannel(commandArgs[1],"text")
        .then((channel) ->
          channel.overwritePermissions(exports.floppyAngels.defaultRole, {READ_MESSAGES: false})
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

    if(commandArgs[0] == "parlorMaker")
      usersMentioned = message.mentions.members.array()
      if(usersMentioned.length < 3)
        message.channel.send("Not enough players.")
      else
        firstChan = exports.floppyAngels.createChannel(commandArgs[1]+"Player1","text")
          .then((channel) ->
            return channel)
          .catch(console.error)
        secondChan = exports.floppyAngels.createChannel(commandArgs[1]+"Player2","text")
          .then((channel) ->
            return channel)
            .catch(console.error)
        thirdChan = exports.floppyAngels.createChannel(commandArgs[1]+"Player3","text")
          .then((channel) ->
            return channel)
          .catch(console.error)
        forthChan = exports.floppyAngels.createChannel(commandArgs[1]+"Player4","text")
          .then((channel) ->
            return channel)
          .catch(console.error)
        fifthChan = exports.floppyAngels.createChannel(commandArgs[1]+"GroupChat","text")
          .then((channel) ->
            return channel)
          .catch(console.error)
        Promise.all([firstChan,secondChan,thirdChan,forthChan,fifthChan])
          .then((channels) ->
            console.log(channels)
            channels[0].overwritePermissions(message, {READ_MESSAGES: true, MANAGE_CHANNELS: true})
              .then(console.log("Revealed!!"))
              .catch(console.error)
            channels[1].overwritePermissions(usersMentioned[0], {READ_MESSAGES: true, MANAGE_CHANNELS: true})
              .then(console.log("Revealed!!"))
              .catch(console.error)
            channels[2].overwritePermissions(usersMentioned[0], {READ_MESSAGES: true, MANAGE_CHANNELS: true})
              .then(console.log("Revealed!!"))
              .catch(console.error)
            channels[3].overwritePermissions(usersMentioned[0], {READ_MESSAGES: true, MANAGE_CHANNELS: true})
              .then(console.log("Revealed!!"))
              .catch(console.error)
            channels[4].overwritePermissions(message, {READ_MESSAGES: true, MANAGE_CHANNELS: true})
              .then(console.log("Revealed!!"))
              .catch(console.error)
            for x in usersMentioned
              channels[4].overwritePermissions(x, {READ_MESSAGES: true})
                .then(console.log("Revealed!!"))
                .catch(console.error)
            for x in channels
              x.overwritePermissions(exports.floppyAngels.defaultRole, {READ_MESSAGES: false})
                .then(console.log("Hidden"))
                .catch(console.error)
              exports.parlors.push(x)
            )
            .catch(console.error)

    if(commandArgs[0] == "yell")
      for x in exports.parlors
        x.send(commandArgs[1..])

    if(commandArgs[0] == "ragnarok")
      message.channel.send("Let's Ragnarok!!!!!")
      for x in exports.parlors
        x.delete()
      exports.parlors = []

    #TODO: make game commands work with game objects

    if(commandArgs[0] == "end")
      if(not exports.gameStarted)
        message.channel.send("No game to end.")
      else
        exports.gameStarted = false
        message.channel.send("Game ended.")
        bot.user.setGame("")

    if(commandArgs[0] == "turn")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send("It is player #{exports.turn}'s turn.")


    if(commandArgs[0] == "phase")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send("It is the #{exports.phase} phase.")

    if(commandArgs[0] == "wind")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send(exports.prevailingWind)

    if(commandArgs[0] == "dora")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send(exports.wall.printDora(exports.writeTiles))

    if(commandArgs[0] == "tiles")
      message.channel.send(mahjongTiles.allTilesGetter())

    if(commandArgs[0] == "toggle")
      if(commandArgs[1] == "writing")
        exports.writeTiles = not exports.writeTiles
        message.channel.send("Tiles Toggled")

    if(commandArgs[0] == "hand")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        if(commandArgs[1] not in ["1","2"])
          message.channel.send("Please select a real hand.")
        else if(commandArgs[1] is "1")
          message.channel.send(exports.hand1.printHand(exports.writeTiles))
        else if(commandArgs[1] is "2")
          message.channel.send(exports.hand2.printHand(exports.writeTiles))

    if(commandArgs[0] == "pile")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        if(commandArgs[1] not in ["1","2"])
          message.channel.send("Please select a real discard pile.")
        else if(commandArgs[1] is "1")
          message.channel.send(exports.hand1.discardPile.printDiscard(exports.writeTiles))
        else if(commandArgs[1] is "2")
          message.channel.send(exports.hand2.discardPile.printDiscard(exports.writeTiles))

    if(commandArgs[0] == "draw")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else if(exports.phase != "draw")
        message.channel.send("It is not the draw phase.")
      else
        if(exports.turn == 1)
          message.channel.send(exports.hand1.draw(exports.wall))
        else if (exports.turn == 2)
          message.channel.send(exports.hand2.draw(exports.wall))
        exports.phase = "discard"

    if(commandArgs[0] == "discard")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else if(exports.phase != "discard")
        message.channel.send("It is not the discard phase.")
      else
        if(exports.turn == 1)
          checkDiscard = exports.hand1.discard(commandArgs[1]+" "+commandArgs[2])
        else if (exports.turn == 2)
          checkDiscard = exports.hand2.discard(commandArgs[1]+" "+commandArgs[2])
        if(checkDiscard)
          exports.phase = "draw"
          exports.turn = 3-exports.turn
          message.channel.send(checkDiscard)
        else
          message.channel.send("You do not have that tile.")

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
