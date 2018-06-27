_ = require('lodash')
game = require('./akagiTiles.coffee')
score = require('./akagiScoring.coffee')

testH = (handText,calledTiles = [],gameFlags = new score.gameFlags("East","East"),lastTileFrom = "self",dora = [[],[]]) ->
  textChunks = handText.split(" ")
  testHand = new game.Hand(new game.Pile())
  for x in [0...textChunks.length/2]
    testHand.contains.push(new game.Tile(textChunks[2*x+1],textChunks[2*x]))
  testHand.draw(null,0)
  testHand.lastTileDrawn = new game.Tile(textChunks[textChunks.length-1],textChunks[textChunks.length-2])
  if lastTileFrom != "self"
    testHand.lastTileFrom = lastTileFrom

  for calledMeld in calledTiles
    tiles = (new game.Tile(x.split(" ")[1],x.split(" ")[0]) for x in calledMeld[1])
    testHand.calledMelds.push(new game.Meld(tiles,calledTiles[0]))

  return score.scoreMahjongHand(testHand,gameFlags,dora)

tester = (expected, input) ->
  if(_.isEqual(expected,input[0]))
    console.log("Test Passed")
  else
    console.log("Test Failed #{expected} != #{input[0]}")
    console.log(input)


tester(1280,testH("1 pin 2 pin 3 pin 5 pin 6 pin 7 pin 2 wan 3 wan 4 wan east wind east wind east wind 2 pin 2 pin"))
#10 Example Hands from the EMA Ruleset
tester(2000,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",[],new score.gameFlags("East","East",["Riichi"])))
tester(1920,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",[],new score.gameFlags("East","East",["Riichi"]),2))
tester(480,testH("3 sou 3 sou 1 pin 2 pin 3 pin 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",[[2,["4 pin","5 pin","6 pin"]]], new score.gameFlags("East","East"),2,[[new game.Tile("pin", 7)],[]]))
tester(8000,testH("3 sou 3 sou 3 sou 2 wan 2 wan 2 wan 4 wan 4 wan 4 wan 3 pin 3 pin 8 pin 8 pin 8 pin"))
tester(4000,testH("3 sou 3 sou 3 sou 2 wan 2 wan 2 wan 4 wan 4 wan 4 wan 3 pin 3 pin 8 pin 8 pin 8 pin",[],new score.gameFlags("East","East"),2,[[new game.Tile("wan", 3)],[]]))
tester(3000,testH("2 sou 2 sou 3 sou 3 sou 5 sou 5 sou 2 wan 2 wan 6 wan 6 wan 3 pin 3 pin 4 pin 4 pin",[],new score.gameFlags("East","East",["Riichi","Ippatsu"])))
tester(400,testH("green dragon green dragon 3 sou 3 sou 5 sou 5 sou 2 wan 2 wan 6 wan 6 wan 3 pin 3 pin 4 pin 4 pin",[],new score.gameFlags("East","East"),2))
tester(1920,testH("3 sou 3 sou 4 sou 4 sou 5 sou 5 sou 1 wan 1 wan 2 wan 2 wan 3 wan 3 wan red dragon red dragon"))
tester(3000,testH("1 pin 1 pin 1 pin 2 pin 3 pin 7 pin 8 pin 9 pin east wind east wind east wind west wind west wind west wind",[[2,["east wind","east wind","east wind"]]],new score.gameFlags("East","East"),2,[[new game.Tile("pin", 6)],[]]))
tester(2000,testH("north wind north wind north wind 1 wan 1 wan 2 wan 3 wan 4 wan 5 wan 6 wan 7 wan 8 wan 9 wan 7 wan"))
#Thirteen Orphans Test
tester(8000,testH("1 sou 9 sou 1 wan 9 wan 9 wan 1 pin 9 pin east wind north wind south wind west wind green dragon red dragon white dragon"))
#9 Gates Test
tester(8000,testH("1 sou 1 sou 1 sou 1 sou 2 sou 3 sou 4 sou 5 sou 6 sou 7 sou 8 sou 9 sou 9 sou 9 sou"))
#Four Concealed Pungs
tester(8000,testH("1 sou 1 sou 1 sou 2 sou 2 sou 2 sou 3 pin 3 pin 3 pin green dragon green dragon green dragon red dragon red dragon",[],new score.gameFlags("East","East"),2))
#All Green
tester(8000,testH("2 sou 3 sou 4 sou 2 sou 3 sou 4 sou 6 sou 6 sou 6 sou 8 sou 8 sou 8 sou green dragon green dragon"))
#All Honours
tester(8000,testH("green dragon green dragon red dragon red dragon white dragon white dragon east wind east wind west wind west wind south wind south wind north wind north wind"))
#All Terminals
tester(8000,testH("1 pin 1 pin 1 pin 9 pin 9 pin 9 pin 9 sou 9 sou 9 sou 9 wan 9 wan 9 wan 1 wan 1 wan"))
#Little 4 Winds
tester(8000,testH("east wind east wind east wind south wind south wind north wind north wind north wind west wind west wind west wind 1 pin 1 pin 1 pin"))
#Big 4 winds
tester(8000,testH("east wind east wind east wind south wind south wind north wind north wind north wind west wind west wind west wind 1 pin 1 pin south wind"))
#Big 3 dragons
tester(8000,testH("red dragon green dragon white dragon red dragon green dragon white dragon red dragon green dragon white dragon 1 pin 1 pin 1 pin 2 sou 2 sou"))
#4 Kongs
tester(8000,testH("1 pin 1 pin 1 pin 1 pin 2 pin 2 pin 2 pin 2 pin 3 pin 3 pin 3 pin 3 pin 4 pin 4 pin 4 pin 4 pin 5 pin 5 pin",[[1,["2 pin","2 pin","2 pin","2 pin"]],["self",["4 pin","4 pin","4 pin","4 pin"]],["self",["3 pin","3 pin","3 pin","3 pin"]],[2,["1 pin","1 pin","1 pin","1 pin"]]]))
#Blessing of Heaven
tester(8000,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",[],new score.gameFlags("East","East",["Tenho"])))
#Blessing of Earth
tester(8000,testH("3 sou 3 sou 1 sou 2 sou 3 sou 1 pin 2 pin 3 pin 4 pin 5 pin 6 pin 7 pin 8 pin 9 pin",[],new score.gameFlags("East","East",["Chiho"])))
