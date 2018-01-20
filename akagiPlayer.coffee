require(['./akagiTiles.coffee'], (gamePieces) ->

  class Player
    constructor: (@playerChannel, @playerNumber) ->
      @discardPile = new gamePieces.Pile()
      @hand = new gamePieces.Hand(@discardPile)
      @gamePoints = 0
      @roundPoints = 27000
      @namedTiles = true
    roundStart: ->
      @playerChannel.send("New Round Start")
      @playerChannel.send("Starting Hand : "+@hand.printHand())
    sendMessage:(message) ->
      @playerChannel.send(message)
    toggleTiles: ->
      @namedTiles = not @namedTiles
      if(@namedTiles)
        @playerChannel.send("Tile names visible")
      else
        @playerChannel.send("Tile names hidden")
    printHand: ->
      @hand.printHand(@namedTiles)
    wallDraw:(wall) ->
      tileDrawn = @hand.draw(wall)
      @playerChannel.send(tileDrawn[0].getName(@namedTiles))
    setNextPlayer:(nextPlayerNumber)->
      @nextPlayer = nextPlayerNumber
    discardTile:(tileToDiscard)->
      return @hand.discard(tileToDiscard)

  module.exports = Player
)
