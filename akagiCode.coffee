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

  drawFrom: ->
    #removes a random tile from the wall and returns it
    take = Math.floor(Math.random()*@inWall.length)
    out = @inWall.splice(take,1)
    return out[0]

  doraFlip: ->
    #Exactly the same as draw right now, but uses a different method because it might need to be different later
    take = Math.floor(Math.random()*@inWall.length)
    out = @inWall.splice(take,1)
    return out[0]

class Hand
  #A Hand of tiles
  constructor: (@discardPile) ->
    @contains = []

  #Draws x tiles from anything with a drawFrom() function, then sorts the hand and returns the drawn tiles
  draw: (drawSource, x=1) ->
    out = []
    for y in [0...x]
      @contains.push(drawSource.drawFrom())
      out.push(@contains[@contains.length-1].getName())
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
        return out[0].getName()
    return false

  #prints the hand, which should be sorted already
  printHand: (writtenName = true) ->
    return (x.getName(writtenName) for x in @contains)

class Pile
  #The tiles discarded by a given hand
  constructor: ->
    @contains = []
    @riichi = -1

  discardTo: (x) ->
    @contains.push(x)

  drawFrom: ->
    out = @contains.splice(@contains.length-1,1)
    return out

  printDiscard: (writtenName = true) ->
    out = []
    for x,i in @contains
      if i is @riichi
        out.push("r:"+x.getName(writtenName))
      else
        out.push(x.getName(writtenName))
    return out



module.exports.Tile = Tile
module.exports.Hand = Hand
module.exports.Wall = Wall
module.exports.Pile = Pile