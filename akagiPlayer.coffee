gamePieces = require('./akagiTiles.coffee')

class Player
  constructor: (@playerChannel, @playerNumber) ->
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)
    @gamePoints = 0
    @roundPoints = 30000
    @namedTiles = true #Tells whether you want the names written out, or just the symbol.
    @daburu = false #Activated if a player calls riichi on their first turn
    @liablePlayer = false #Who fed the last dragon or wind tile to someone who already had 2/3 of them.
  roundStart:(wall) ->
    @daburu = false
    @liablePlayer = false
    @playerChannel.send("New Round Start")
    @playerChannel.send("Seat Wind: #{@wind}")
    if(@wind == "East")
      @hand.draw(wall)
    @playerChannel.send("Starting Hand : "+@hand.printHand())
  resetHand: ->
    @discardPile = new gamePieces.Pile()
    @hand = new gamePieces.Hand(@discardPile)
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
  printUncalled: ->
    @hand.printUncalled(@namedTiles)
  printMelds:(tileNames = true) ->
    @hand.printMelds(tileNames)
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
    @playerChannel.send("The winds have rotated.")
  discardTile:(tileToDiscard)->
    return @hand.discard(tileToDiscard)
  riichiCalled: ->
    return @discardPile.riichi != -1

module.exports = Player
