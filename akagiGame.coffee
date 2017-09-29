gamePieces = require('./akagiTiles.coffee')
player = require('./akagiPlayer.coffee')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerUserObjects, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [new player(playerUserObjects[0]), new player(playerUserObjects[1]), new player(playerUserObjects[2]), new player(playerUserObjects[3])]
    @turn = 1
    @phase = 'draw'
    @prevailingWind = "East"
    @discordRoom = {}

module.exports = MahjongGame
