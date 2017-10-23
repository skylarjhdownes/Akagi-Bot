#Returns the unicode for a given tile
unicodeTileGetter = (suit,value) ->
  if(suit == "pin")
    pinTiles = ['🀙','🀚','🀛','🀜','🀝','🀞','🀟','🀠','🀡']
    return pinTiles[value-1]
  if(suit == "sou")
    souTiles = ['🀐','🀑','🀒','🀓','🀔','🀕','🀖','🀗','🀘']
    return souTiles[value-1]
  if(suit == "wan")
    wanTiles = ['🀇','🀈','🀉','🀊','🀋','🀌','🀍','🀎','🀏']
    return wanTiles[value-1]
  if(suit == "wind")
    #windTiles = ['🀀','🀁','🀂','🀃']
    return '🀀' if value == "east"
    return '🀁' if value == "south"
    return '🀂' if value == "west"
    return '🀃' if value == "north"
  if(suit == "dragon")
    #dragonTiles = ['🀄','🀅','🀆']
    return '🀄' if value == "red"
    return '🀅' if value == "green"
    return '🀆' if value == "white"

allTilesGetter = ->
  return ['🀙','🀚','🀛','🀜','🀝','🀞','🀟','🀠','🀡','🀐','🀑','🀒','🀓','🀔','🀕','🀖','🀗','🀘','🀇','🀈','🀉','🀊','🀋','🀌','🀍','🀎','🀏','🀀','🀁','🀂','🀃','🀄','🀅','🀆']

#returns type of tileset, or false if not a legal set.
isTileSet = (tiles) ->
  tiles.sort((x,y)->x.value-y.value)
  if(tiles.length == 2)
    if(tiles[0].getTextName() == tiles[1].getTextName())
      return "Pair"
    else
      return false
  else if(tiles.length == 4)
    if(tiles[0].getTextName() == tiles[1].getTextName() and tiles[0].getTextName() == tiles[2].getTextName() and tiles[0].getTextName() == tiles[3].getTextName())
      return "Kong"
    else
      return false
  else if(tiles.length == 3)
    if(tiles[0].suit == tiles[1].suit and tiles[0].suit == tiles[2].suit)
      if(tiles[0].value == tiles[1].value and tiles[0].suit == tiles[2].value)
        return "Pung"
      else if(tiles[0].value + 1 == tiles[1].value and tiles[1].value + 1 == tiles[2].value)
        return "Chow"
      else
        return false
    else
      return false
  else
    return false

class Tile
  #An individual tile in a game of mahjong
  constructor: (@suit, @value) ->
    #Generates a number that can be used for sorting in hands later on
    @sortValue = ["pin","sou","wan","wind","dragon"].indexOf(@suit)*16
    @sortValue += [1,2,3,4,5,6,7,8,9,"east","south","west","north","red","green","white"].indexOf(@value)
    @unicode = unicodeTileGetter(@suit,@value)

  isGreen: ->
    @suit in ["dragon","sou"] and @value in ["green",2,3,4,6,8]

  isHonor: ->
    @suit in ["dragon", "wind"]

  isTerminal: ->
    @value in [1,9]

  isSimple: ->
    not isHonor() and not isTerminal()

  #Determines if it is a real tile that can exist in the game
  isLegal: ->
    if(@suit == "dragon")
      return @value in ["red","green","white"]
    else if (@suit == "wind")
      return @value in ["east","south","west","north"]
    else if (@suit in ["pin","sou","wan"])
      return @value in [1..9]
    else
      false

  #gives a pretty printed name for the tile
  getName: (writtenName = true) ->
    if(writtenName)
      return "#{@value} #{@suit} #{@unicode}"
    else
      return @unicode

  getTextName: ->
    return "#{@value} #{@suit}"

class Wall
  #The deck from which all things are drawn
  constructor: ->
    #Fills it up with 4 copies of each normal tile
    @inWall = []
    @inWall.push(new Tile(x,y)) for x in ["pin","sou","wan"] for y in [1..9] for z in [0...4]
    @inWall.push(new Tile("wind",y)) for y in ["east","south","west","north"] for z in [0...4]
    @inWall.push(new Tile("dragon",y)) for y in ["red","white","green"] for z in [0...4]
    @dora = []

  drawFrom: ->
    #removes a random tile from the wall and returns it
    take = Math.floor(Math.random()*@inWall.length)
    out = @inWall.splice(take,1)
    return out[0]

  doraFlip: ->
    #Draws a random tile and sets it to be the dora
    take = Math.floor(Math.random()*@inWall.length)
    out = @inWall.splice(take,1)
    @dora.push(out[0])
    return out[0]

  printDora: (writtenName = true) ->
    if(@dora.length == 0)
      return "No Dora"
    else
      return (x.getName(writtenName) for x in @dora)

class Hand
  #A Hand of tiles
  constructor: (@discardPile) ->
    @contains = []
    @calledTileSets = {}
    @lastTileDrawn = false

  #Draws x tiles from anything with a drawFrom() function, then sorts the hand and returns the drawn tiles
  draw: (drawSource, x=1) ->
    out = []
    for y in [0...x]
      @contains.push(drawSource.drawFrom())
      out.push(@contains[@contains.length-1])
    if(x == 1)
      @lastTileDrawn = @contains[@contains.length-1]
    @contains.sort((x,y)->x.sortValue-y.sortValue)
    return out

  #Draws 13 tiles, the normal starting hand size
  startDraw: (drawSource) ->
    @draw(drawSource, 13)

  #discards a specific card from the hand
  discard: (whichTile) ->
    for x,i in @contains
      if(x.getTextName()==whichTile)
        out = @contains.splice(i,1)
        console.log(out[0])
        @discardPile.discardTo(out[0])
        return out[0]
    return false

  #prints the hand, which should be sorted already
  printHand: (writtenName = true) ->
    if(@contains.length == 0)
      return "Empty"
    else
      return (x.getName(writtenName) for x in @contains)


  #returns true if there are no calledTileSets, or if they are all self-called Kongs
  isConcealed: ->
    if(_.isEmpty(@calledTileSets))
      return true
    else
      return _.every(@calledTileSets, (x) -> x.takenFrom == "self" and x.type == "Kong")

#This class assumes that a legal tileSet has been passed to it.
class TileSet
  #A set of two, three or four tiles
  constructor: (@tiles, @takenFrom = "self")
    if(@tiles.length == 4)
      @type = "Kong"
    else if(@tiles.length == 2)
      @type = "Pair"
    else if(@tiles[0].getTextName() == @tiles[1].getTextName())
      @type = "Pung"
    else
      @type = "Chow"

  printTileSet: (writtenName = true) ->
    return (x.getName(writtenName) for x in @tiles)

class Pile
  #The tiles discarded by a given hand
  constructor: ->
    @contains = [] #Contains all tiles ever discarded by this player
    @riichi = -1 #Tells which tile is turned sideways for riichi
    @stolenTiles = [] #Tells indexs of tiles that have been stolen so they are not displayed when printing

  discardTo: (x) ->
    @contains.push(x)

  #Returns the most recent tile, adds that tile to @stolenTiles, and makes next tile riichi if the stolen tile was.
  drawFrom: ->
    out = @contains[@contains.length-1]
    stolenTiles.push[@contains.length-1]
    if(@riichi == @contains.length-1)
      @riichi+=1
    return out

  #Prints all non stolen tiles, and tells which, if any, are turned sideways for riichi.
  printDiscard: (writtenName = true) ->
    out = []
    for x,i in @contains
      if(not i in @stolenTiles)
        if i is @riichi
          out.push("r:"+x.getName(writtenName))
        else
          out.push(x.getName(writtenName))
    if(@contains.length == 0)
      out = "Empty"
    return out



module.exports.Tile = Tile
module.exports.Hand = Hand
module.exports.Wall = Wall
module.exports.Pile = Pile
module.exports.allTilesGetter = allTilesGetter
module.exports.isTileSet = isTileSet
