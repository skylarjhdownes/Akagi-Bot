gamePieces = require('./akagiTiles.coffee')

class Player
  constructor: (@playerChannel) ->
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)
    @gamePoints = 0
    @roundPoints = 27000
  roundStart: ->
    @playerChannel.send("New Round Start")
    @playerChannel.send("Starting Hand : "+@hand.printHand())
  sendMessage:(message) ->
    @playerChannel.send(message)
module.exports = Player
