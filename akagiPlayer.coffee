gamePieces = require('./akagiTiles.coffee')

# It's possible that this class should just extend the discord.js User class.
class Player
  constructor: (playerUserObject) ->
    @playerUserObject = playerUserObject
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)

module.exports = Player
