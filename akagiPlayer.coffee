gamePieces = require('./akagiTiles.coffee')

class Player
  constructor: (playerID) ->
    @playerID = playerID
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)

module.exports = Player
