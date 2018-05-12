_ = require('lodash')
gamePieces = require('./akagiTiles.coffee')

scoreMahjongHand = (hand, winningPlayer) ->
  #Takes a hand of mahajong tiles and finds the highest scoring way it can be interpreted, returning the score, and the melds which lead to that score
  possibleHands = getPossibleHands(hand)
  if possibleHands == []
    return(0, "Not a Scoring Hand")
  scores = getScore(hand, winningPlayer) for hand in possibleHands
  maxScore = _.maxBy(scores, (x) -> x[0])
  maxLocation = _.indexOf(scores,maxScore)
  return(maxScore,possibleHands[maxLocation])

getPossibleHands = (hand) ->
  #Takes a hand of mahjong tiles and finds every possible way the hand could be interpreted to be a winning hand, returning each different meld combination
  possibleHands = []
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()
  handTiles = hand.contains
  if _.intersection(handTiles, allTerminalsAndHonors).length == 13 && _.xor(hand, allTerminalsAndHonors).length == 0
    drawLocation = _.indexOf(handTiles,hand.lastTileDrawn)
    if(drawLocation == 13 || handTiles[drawLocation] != handTiles[drawLocation+1])
      possibleHands.push("thirteenorphans") #Normal 13 orphans
    else
      possibleHands.push("thirteenorphans+") #13 way wait, 13 orphans

  if _.uniq(handTiles).length == 7
    pairGroup = _.chunk(handTiles, 2)
    if _.every(pairGroup, (x) -> gamePieces.isTileSet(x) == "Pair")
      possibleHands.push(_.map(pairGroup,gamePieces.TileSet)) #I forget how objects work in js. If pairGroup is just a reference, maybe this will cause bugs.

  #Any hands other than pairs/13 orphans
  normalHandFinder = (melds, remaining) =>
    if(remaining.length == 0)
      possibleHands.push(melds)
    else if(remaining.length == 1)
      return "Nope"
    pairRemaining = true
    for x in melds
      if(x.type == "Pair")
        pairRemaining = false
    if(!pairRemaining && remaining.length == 2)
      return "Nope"
    if(pairRemaining && remaining[0]==remaining[1])
      normalHandFinder(_.concat(melds,gamePieces.TileSet([remaining[0],remaining[1]])),remaining[2..])
    if(remaining[0]==remaining[1] && remaining[1]==remaining[2])
      normalHandFinder(_.concat(melds,gamePieces.TileSet([remaining[0],remaining[1],remaining[2]])),remaining[3..])
    nextInRun = gamePieces.Tile(remaining[0].type,remaining[0].value+1)
    nextAt = remaining.indexOf(nextInRun)
    afterThat = gamePieces.Tile(remaining[0].type,remaining[0].value+2)
    afterAt = remaining.indexOf(afterThat)
    if(nextAt != -1 && afterAt != -1)
      pruned = remaining.slice[0]
      pruned.splice(nextAt,1)
      afterAt = remaining.indexOf(afterThat)
      pruned.splice(afterAt,1)
      pruned = pruned.slice[1]
      normalHandFinder(_.concat(melds,remaining[0],nextInRun,afterThat),pruned)



  uncalled = handTiles
  for x in hand.calledTileSets
    for y in x
      remove = uncalled.indexOf(y)
      uncalled.splice(remove,1)

  normalHandFinder(hand.calledTileSets,uncalled)

  return possibleHands


getScore = (melds, winningPlayer) -> # melds will be a TileSet object, the winning player's hand
  #Takes a set of melds and returns the score of that particular combination of getMelds and the yaku that made up that score
  yakuman = false
  yaku = 0
  dora = 0
  fu = 0
  playerEast = false #Going to have to get this info in somehow.
  selfDraw = false #Going to have to get this info in somehow.

  if melds.hand.isConcealed()
    if (melds.discardPile.riichi != 0) # winning player has called riichi
      yaku++
    if selfDraw #Menzen Tsumo - Self draw on concaled hand
      yaku++
    if #Pinfu - Concealed all chows hand with a valuless pair
      #todo
    if #Iipeikou - Concealed hand with two completely identical chow.
      chowList = meld in melds.hand when meld.type == "Chow"
      identicalChow = false
      for chow1, index1 in chowList
        for chow2, index2 in chowList
          if chow1 == chow2 && index1 != index2
            identicalChow = true
      if identicalChow
        yaku++




  if(melds == "thirteenorphans")
    yakuman = "thirteenorphans"
  #Check for yakuman
  if(yakuman)
    #Return yakuman score and name of isYakuman
  #Check for yaku
  if(yaku == 0)
    #Return 0 and "Not a winning hand, no Yaku"
  #Check for dora
  fan = yaku+dora
  if(fan>=5)
    #Return scored points and yaku plus dora in hand
  #Check for fu

  baseScore = math.pow(fu,2+fan)
  #Return scored points and yaku + dora + fu in hand

  roundUpToClosestHundred = (inScore) ->
    if (inScore%100)!=0
      return (inScore//100+1)*100
    else
      inScore

module.exports = scoreMahjongHand
