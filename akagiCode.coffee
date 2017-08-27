class Tile
  #An individual tile in a game of mahjong
  constructor: (@suit, @value) ->
    #Generates a number that can be used for sorting in hands later on
    @sortValue = ["pin","sou","wan","wind","dragon"].indexOf(@suit)*17
    @sortValue += [1,2,3,4,5,6,7,8,9,"east","south","west","north","red","white","green"].indexOf(@value)


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
  getName: ->
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
  constructor: ->
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
      if(x.getName()==whichTile)
        return @contains.splice(i,1)
    return false

  #prints the hand, which should be sorted already
  printHand: ->
    return (x.getName() for x in @contains)



#Example Game Start
gameWall = new Wall
hand1 = new Hand
hand2 = new Hand
hand3 = new Hand
hand4 = new Hand
console.log(gameWall.inWall.length)
hand1.startDraw(gameWall)
hand2.startDraw(gameWall)
hand3.startDraw(gameWall)
hand4.startDraw(gameWall)
console.log(gameWall.inWall.length)
console.log("Player 1 Starting Hand")
console.log(hand1.printHand())
console.log("Player 2 Starting Hand")
console.log(hand2.printHand())
console.log("Player 3 Starting Hand")
console.log(hand3.printHand())
console.log("Player 4 Starting Hand")
console.log(hand4.printHand())
console.log("Player 1's First Draw")
console.log(hand1.draw(gameWall))
console.log("Player 1 Hand after first draw")
console.log(hand1.printHand())
console.log(hand1.discard(hand1.contains[0].getName()))
console.log("Player 1 Hand after first discard")
console.log(hand1.printHand())
