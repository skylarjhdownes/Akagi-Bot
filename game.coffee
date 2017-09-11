gamePieces = require('./akagiCode.coffee')
player = require('./player.coffee')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerID0, playerID1, playerID2, playerID3, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [new player(playerID0), new player(playerID1), new player(playerID2), new player(playerID3)]

