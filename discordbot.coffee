discord = require('discord.io');
mahjong = require('./akagiCode.coffee')

bot = new discord.Client({
  token: "MzUxMTc2MzEzMTg2Mjg3NjE2.DIPFZw.88Ci5AcfXDU1u3wMPYcwugj5kcI",
  autorun: true
})

# When the bot starts
bot.on('ready', (event) ->
  console.log('Logged in as %s - %s\n', bot.username, bot.id);
  exports.gameStarted = false
  exports.recentDiscard = false
  exports.turn = 1
  exports.phase = "draw"
  exports.writeTiles = true
)

# When chat messages are received
bot.on("message", (user, userID, channelID, message, rawEvent) ->
  console.log("ASDF")
  if (message.substring(0, 1) == "!")
    messageParts = message.split(" ")
    command = messageParts[0].substring(1)
    subCommand = messageParts[1]
    ssubCommand = messageParts[2]
    if(command == "hey")
      bot.sendMessage({
          to: channelID,
          message: "Blood for the blood god!  Skulls for the skull throne!"
      });
    if(command == "start")
      exports.gameStarted = true
      exports.wall = new mahjong.Wall()
      exports.pile1 = new mahjong.Pile()
      exports.pile2 = new mahjong.Pile()
      exports.hand1 = new mahjong.Hand(exports.pile1)
      exports.hand2 = new mahjong.Hand(exports.pile2)
      exports.hand1.startDraw(exports.wall)
      exports.hand2.startDraw(exports.wall)
      bot.sendMessage({
          to: channelID,
          message: "Let the games begin!"
      });
    if(command == "toggle")
      if(subCommand == "writing")
        exports.writeTiles = not exports.writeTiles
        bot.sendMessage({
          to: channelID,
          message: "Tiles Toggled"
        });
    if(command == "hand")
      if(not exports.gameStarted)
        bot.sendMessage({
          to: channelID,
          message: "Please start game first."
          })
      else
        if(subCommand not in ["1","2"])
          bot.sendMessage({
          to: channelID,
          message: "Please select a real hand."
          })
        else if(subCommand is "1")
          bot.sendMessage({
            to: channelID,
            message: exports.hand1.printHand(exports.writeTiles)
            })
        else if(subCommand is "2")
          bot.sendMessage({
            to: channelID,
            message: exports.hand2.printHand(exports.writeTiles)
            })
    if(command == "pile")
      if(not exports.gameStarted)
        bot.sendMessage({
          to: channelID,
          message: "Please start game first."
          })
      else
        if(subCommand not in ["1","2"])
          bot.sendMessage({
          to: channelID,
          message: "Please select a real discard pile."
          })
        else if(subCommand is "1")
          bot.sendMessage({
            to: channelID,
            message: exports.hand1.discardPile.printDiscard(exports.writeTiles)
            })
        else if(subCommand is "2")
          bot.sendMessage({
            to: channelID,
            message: exports.hand2.discardPile.printDiscard(exports.writeTiles)
            })
    if(command == "draw")
      if(not exports.gameStarted)
        bot.sendMessage({
          to: channelID,
          message: "Please start game first."
          })
      else if(exports.phase != "draw")
        bot.sendMessage({
          to: channelID,
          message: "It is not the draw phase."
          })
      else
        if(exports.turn == 1)
          bot.sendMessage({
            to: channelID,
            message: exports.hand1.draw(exports.wall)
          })
        else if (exports.turn == 2)
          bot.sendMessage({
            to: channelID,
            message: exports.hand2.draw(exports.wall)
          })
        exports.phase = "discard"
    if(command == "discard")
      if(not exports.gameStarted)
        bot.sendMessage({
          to: channelID,
          message: "Please start game first."
          })
      else if(exports.phase != "discard")
        bot.sendMessage({
          to: channelID,
          message: "It is not the discard phase."
          })
      else
        if(exports.turn == 1)
          checkDiscard = exports.hand1.discard(subCommand+" "+ssubCommand)
        else if (exports.turn == 2)
          checkDiscard = exports.hand2.discard(subCommand+" "+ssubCommand)
        if(checkDiscard)
          exports.phase = "draw"
          exports.turn = 3-exports.turn
          bot.sendMessage({
          to: channelID,
          message: checkDiscard
          })
        else
          bot.sendMessage({
          to: channelID,
          message: "You do not have that tile."
          })


)
