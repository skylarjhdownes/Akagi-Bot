gamePieces = require('./akagiCode.coffee')

class Player
  constructor: (playerID) ->
    @playerID = playerID
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand()

module.exports = Player
