_ = require('lodash')
game = require('./akagiTiles.coffee')
score = require('./akagiScoring.coffee')

testH = (handText,gameFlags = new score.gameFlags("East","East"),lastTileFrom = "self",dora = [[],[]]) ->
  textChunks = handText.split(" ")
  testHand = new game.Hand(new game.Pile())
  for x in [0...14]
    testHand.contains.push(new game.Tile(textChunks[2*x+1],textChunks[2*x]))
  testHand.draw(null,0)
  testHand.lastTileDrawn = new game.Tile(textChunks[27],textChunks[26])
  if lastTileFrom != "self"
    testHand.lastTileFrom = lastTileFrom

  return score.scoreMahjongHand(testHand,gameFlags,dora)

tester = (expected, input) ->
  if(_.isEqual(expected,input[0]))
    console.log("Test Passed")
  else
    console.log("Test Failed #{expected} != #{input[0]}")
    console.log(input)


tester(1280,testH("1 pin 2 pin 3 pin 5 pin 6 pin 7 pin 2 wan 3 wan 4 wan east wind east wind east wind 2 pin 2 pin"))
tester(2000,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",new score.gameFlags("East","East",["Riichi"])))
tester(1920,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",new score.gameFlags("East","East",["Riichi"]),2))
tester(480,testH("3 sou 3 sou 1 pin 2 pin 3 pin 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin", new score.gameFlags("East","East"),2,[[new game.Tile("pin", 7)],[]]))
#Need to add functionality to have tested hands have already called tiles in them.
