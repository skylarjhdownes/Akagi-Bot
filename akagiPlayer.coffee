gamePieces = require('./akagiTiles.coffee')

class Player
  constructor: (@playerChannel, @playerNumber) ->
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)
    @gamePoints = 0
    @roundPoints = 27000
    @namedTiles = true
  roundStart: ->
    @playerChannel.send("New Round Start")
    @playerChannel.send("Seat Wind: #{@wind}")
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
  setWind:(wind)->
    @wind = wind
  rotateWind: ->
    winds = ["East","South","West","North"]
    @wind = winds[(winds.indexOf(@wind)+1)%4]
  discardTile:(tileToDiscard)->
    return @hand.discard(tileToDiscard)

module.exports = Player
