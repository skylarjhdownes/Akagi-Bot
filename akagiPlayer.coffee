gamePieces = require('./akagiTiles.coffee')

# It's possible that this class should just extend the discord.js User class.
class Player
  constructor: (playerID) ->
    @playerID = playerID
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)

module.exports = Player
