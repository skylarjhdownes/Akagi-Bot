gamePieces = require('./akagiTiles.coffee')
player = require('./akagiPlayer.coffee')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerUserObjects, server, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [
      new player(playerUserObjects[0]),
      new player(playerUserObjects[1]),
      new player(playerUserObjects[2]),
      new player(playerUserObjects[3])
    ]
    @turn = 1
    @phase = 'draw'
    @prevailingWind = "East"
    @playerChannels = []
    @gameObservationChannel = {}

    #TODO: Convert permissions code to use
    # Discord.Permissions.FLAGS for readability
    userPermissions = [
      {type:'role', id:server.defaultRole.id, deny: 1024}
    ]
    for gameObserver in playerUserObjects
      userPermissions.push({type:'member', id:gameObserver.id, allow: 1275583681})

    server.createChannel("testGameChannel", "text", userPermissions)
      .then((channel) =>
          @gameObservationChannel = channel
          channel.send("Let the games begin!\n
          The dora indicator is: #{@wall.printDora(true)}\n
          The prevailing wind is: #{@prevailingWind}")
        )
      .catch(console.error)

    for player in playerUserObjects
      server.createChannel(
        "testGameChannel-#{player.username}", # This is breaking for users other than the game creator.
        "text",
        [
          {type:'role', id:server.defaultRole.id, deny: 1024},
          {type:'member', id:player.id, allow: 1275583681}
        ]
      ).then((channel) =>
          @playerChannels.push(channel)
        )
      .catch(console.error)

module.exports = MahjongGame
