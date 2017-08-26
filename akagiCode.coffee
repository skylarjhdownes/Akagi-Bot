class Tile
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

  isLegal: ->
    if(@suit == "dragon")
      return @value in ["red","green","white"]
    else if (@suit == "wind")
      return @value in ["east","south","west","north"]
    else if (@suit in ["pin","sou","wan"])
      return @value in [1..9]
    else
      false

  getName: ->
    return "#{@value} #{@suit}"

class Wall
  constructor: ->
    @inWall = []
    @inWall.push(new Tile(x,y)) for x in ["pin","sou","wan"] for y in [1..9] for z in [0...4]
    @inWall.push(new Tile("wind",y)) for y in ["east","south","west","north"] for z in [0...4]
    @inWall.push(new Tile("dragon",y)) for y in ["red","white","green"] for z in [0...4]

  draw: ->
    take = Math.floor(Math.random()*@inWall.length)
    out = @inWall.splice(take,1)
    return out[0]

class Hand
  constructor: ->
    @contains = []

  draw: (drawSource, x=1) ->
    out = []
    for y in [0...x]
      @contains.push(drawSource.draw()) 
      out.push(@contains[@contains.length-1].getName())
    @contains.sort((x,y)->x.sortValue-y.sortValue)
    return out

  
  startDraw: (drawSource) ->
    @draw(drawSource, 13)

  discard: (whichTile) ->
    for x,i in @contains
      if(x.getName()==whichTile)
        return @contains.splice(i,1)
    return false

  printHand: ->
    return (x.getName() for x in @contains)




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
console.log(hand1.printHand())
console.log(hand2.printHand())
console.log(hand3.printHand())
console.log(hand4.printHand())