discord = require('discord.io');

bot = new discord.Client({
  token: "MzUxMTc2MzEzMTg2Mjg3NjE2.DIPFZw.88Ci5AcfXDU1u3wMPYcwugj5kcI",
  autorun: true
})

# When the bot starts
bot.on('ready', (event) ->
  console.log('Logged in as %s - %s\n', bot.username, bot.id);
)

# When chat messages are received
bot.on("message", (user, userID, channelID, message, rawEvent) ->
  console.log("ASDF")
  if (message.substring(0, 1) == "!")
    command = message.substring(1)
    if(command == "hey")
      bot.sendMessage({
          to: channelID,
          message: "Blood for the blood god!  Skulls for the skull throne!"
      });
)
