gamePieces = require('./akagiTiles.coffee')
player = require('./akagiPlayer.coffee')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerIDs, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [new player(playerIDs[0]), new player(playerIDs[1]), new player(playerIDs[2]), new player(playerIDs[3])]
    @turn = 1
    @phase = 'draw'
    @prevailingWind = "East"
    @discordRoom = {}

module.exports = MahjongGame
