## Import the discord.js module
Discord = require('discord.js');
mahjongTiles = require('./akagiTiles.coffee')
mahjongGame = require('./akagiGame.coffee')
mahjongPlayer = require('./akagiPlayer.coffee')
dice = require('./akagiDice.coffee')
_ = require('./node_modules/lodash/lodash.js')

## Create an instance of a Discord client
bot = new Discord.Client()

## The token of your bot - https://discordapp.com/developers/applications/me
token = process.env.BOT_TOKEN

## The ready event is vital, it means that your bot will only start reacting to information
## from Discord _after_ ready is emitted
bot.on('ready', =>
  console.log('Logged in as %s - %s\n', bot.user.username, bot.user.id)
  console.log('I am ready!')
  exports.floppyAngels = bot.guilds.first()
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
    messageParts = message.content.split(" ")
    command = messageParts[0].substring(1)
    subCommand = messageParts[1]
    ssubCommand = messageParts[2]

    if(command == "roll")
      message.channel.send(dice.rollDice(subCommand))

    if(command == "start")
      bot.user.setStatus('online','Mahjong')
      exports.mahjongGames.push(new mahjongGame)
      newGame = _.last(exports.mahjongGames)

      for player in newGame.players
        player.hand.startDraw(newGame.wall)
      newGame.wall.doraFlip()

      message.channel.send("Let the games begin!\nThe dora indicator is:
        #{newGame.wall.printDora(exports.writeTiles)}\nThe prevailing wind is: #{newGame.prevailingWind}")

    if(command == "forge")
      usersMentioned = message.mentions.members
      console.log(usersMentioned.array().length)
      exports.floppyAngels.createChannel(subCommand,"text")
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

    if(command == "yell")
      for x in exports.parlors
        x.send(messageParts[1..])

    if(command == "ragnarok")
      message.channel.send("Let's Ragnarok!!!!!")
      for x in exports.parlors
        x.delete()

    #TODO: make game commands work with game objects

    if(command == "end")
      if(not exports.gameStarted)
        message.channel.send("No game to end.")
      else
        exports.gameStarted = false
        message.channel.send("Game ended.")
        bot.user.setGame("")

    if(command == "turn")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send("It is player #{exports.turn}'s turn.")


    if(command == "phase")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send("It is the #{exports.phase} phase.")

    if(command == "wind")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send(exports.prevailingWind)

    if(command == "dora")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        message.channel.send(exports.wall.printDora(exports.writeTiles))

    if(command == "tiles")
      message.channel.send(mahjongTiles.allTilesGetter())

    if(command == "toggle")
      if(subCommand == "writing")
        exports.writeTiles = not exports.writeTiles
        message.channel.send("Tiles Toggled")

    if(command == "hand")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        if(subCommand not in ["1","2"])
          message.channel.send("Please select a real hand.")
        else if(subCommand is "1")
          message.channel.send(exports.hand1.printHand(exports.writeTiles))
        else if(subCommand is "2")
          message.channel.send(exports.hand2.printHand(exports.writeTiles))

    if(command == "pile")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else
        if(subCommand not in ["1","2"])
          message.channel.send("Please select a real discard pile.")
        else if(subCommand is "1")
          message.channel.send(exports.hand1.discardPile.printDiscard(exports.writeTiles))
        else if(subCommand is "2")
          message.channel.send(exports.hand2.discardPile.printDiscard(exports.writeTiles))

    if(command == "draw")
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

    if(command == "discard")
      if(not exports.gameStarted)
        message.channel.send("Please start game first.")
      else if(exports.phase != "discard")
        message.channel.send("It is not the discard phase.")
      else
        if(exports.turn == 1)
          checkDiscard = exports.hand1.discard(subCommand+" "+ssubCommand)
        else if (exports.turn == 2)
          checkDiscard = exports.hand2.discard(subCommand+" "+ssubCommand)
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
