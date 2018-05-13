_ = require('lodash')
gamePieces = require('./akagiTiles.coffee')

scoreMahjongHand = (hand, winningPlayer) ->
  #Takes a hand of mahajong tiles and finds the highest scoring way it can be interpreted, returning the score, and the melds which lead to that score
  possibleHands = getPossibleHands(hand)
  if possibleHands == []
    return([0, "Not a Scoring Hand"])
  scores = getScore(hand, winningPlayer) for hand in possibleHands
  maxScore = _.maxBy(scores, (x) -> x[0])
  maxLocation = _.indexOf(scores,maxScore)
  return([maxScore,possibleHands[maxLocation]])

getPossibleHands = (hand) ->
  #Takes a hand of mahjong tiles and finds every possible way the hand could be interpreted to be a winning hand, returning each different meld combination
  possibleHands = []
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()
  handTiles = hand.contains
  if _.intersectionWith(handTiles, allTerminalsAndHonors,_.isEqual).length == 13 && _.xorWith(handTiles, allTerminalsAndHonors,_.isEqual).length == 0
    drawLocation = _.findIndex(handTiles,(x)->_.isEqual(hand.lastTileDrawn,x))
    if(drawLocation == 13 || !_.isEqual(handTiles[drawLocation],handTiles[drawLocation+1]))
      possibleHands.push("thirteenorphans") #Normal 13 orphans
    else
      possibleHands.push("thirteenorphans+") #13 way wait, 13 orphans

  if _.uniqWith(handTiles,_.isEqual).length == 7
    pairGroup = _.chunk(handTiles, 2)
    if _.every(pairGroup, (x) -> gamePieces.isTileSet(x) == "Pair")
      possibleHands.push(_.map(pairGroup,(x)-> return new gamePieces.TileSet(x)))

  #Any hands other than pairs/13 orphans
  normalHandFinder = (melds, remaining) =>
    if(!remaining || remaining.length == 0)
      possibleHands.push(melds)
      return "Yep"
    else if(remaining.length == 1)
      return "Nope"
    pairRemaining = true
    for x in melds
      if(x.type == "Pair")
        pairRemaining = false
    if(!pairRemaining && remaining.length == 2)
      return "Nope"
    if(pairRemaining && _.isEqual(remaining[0],remaining[1]))
      normalHandFinder(_.concat(melds,new gamePieces.TileSet([remaining[0],remaining[1]])),remaining[2..])
    if(remaining.length >= 3)
      if(_.isEqual(remaining[0],remaining[1]) && _.isEqual(remaining[1],remaining[2]))
        normalHandFinder(_.concat(melds,new gamePieces.TileSet([remaining[0],remaining[1],remaining[2]])),remaining[3..])
      nextInRun = new gamePieces.Tile(remaining[0].suit,remaining[0].value+1)
      nextAt = _.findIndex(remaining,(x)->_.isEqual(nextInRun,x))
      afterThat = new gamePieces.Tile(remaining[0].suit,remaining[0].value+2)
      afterAt = _.findIndex(remaining,(x)->_.isEqual(afterThat,x))
      if(nextAt != -1 && afterAt != -1)
        pruned = remaining[0..]
        pruned.splice(nextAt,1)
        afterAt = _.findIndex(pruned,(x)->_.isEqual(afterThat,x))
        pruned.splice(afterAt,1)
        pruned = pruned[1..]
        normalHandFinder(_.concat(melds,new gamePieces.TileSet([remaining[0],nextInRun,afterThat])),pruned)



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

  #Going to have to get this info in somehow.
  roundWind = ""
  playerWind = ""
  selfDraw = false

  isConcealedHand = melds.isConcealed()
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()

  if isConcealedHand
    if (winningPlayer.hand.discardPile.riichi != 0) # winning player has called riichi
      yaku++
    if selfDraw #Menzen Tsumo - Self draw on concaled hand
      yaku++
    #if #Pinfu - Concealed all chows hand with a valuless pair
      #todo
    #Iipeikou - Concealed hand with two completely identical chow.
    chowList = (meld for meld in melds when meld.type == "Chow")
    identicalChow = false
    for chow1, index1 in chowList
      for chow2, index2 in chowList
        if chow1 == chow2 && index1 != index2
          identicalChow = true
    if identicalChow
      yaku++
  #Tanyao Chuu - All simples (no terminals/honors)
  if _.intersectionWith(melds.hand, allTerminalsAndHonors, _.isEqual).length == 0
    yaku++
  #Fanpai/Yakuhai - Pung/kong of dragons.
  for meld in melds when meld.type == "Pung" || meld.type == "Kong"
    if meldContainsOnlyGivenTile(meld, new Tile("dragon", "red")) ||
        meldContainsOnlyGivenTile(meld, new Tile("dragon", "green")) ||
        meldContainsOnlyGivenTile(meld, new Tile("dragon", "white")) ||
        meldContainsOnlyGivenTile(meld, new Tile("wind", playerWind)) ||
        (playerWind != roundWind && meldContainsOnlyGivenTile(meld, new Tile("wind", roundWind)))
      yaku++
      break


  if(melds == "thirteenorphans")
    yakuman = "thirteenorphans"
  #Check for yakuman
  #if(yakuman)
    #Return yakuman score and name of isYakuman
  #Check for yaku
  #if(yaku == 0)
    #Return 0 and "Not a winning hand, no Yaku"
  #Check for dora
  fan = yaku+dora
  if fan >= 5
    console.log("not implemented yet.")
    #Return scored points and yaku plus dora in hand
  #Check for fu

  baseScore = math.pow(fu,2+fan)
  #Return scored points and yaku + dora + fu in hand

  meldContainsOnlyGivenTile = (meld, givenTile) ->
    allSameTile = true
    for tile in meld.tiles
      if tile != givenTile
        allSameTile = false
        break
    return allSameTile

  roundUpToClosestHundred = (inScore) ->
    if (inScore%100)!=0
      return (inScore//100+1)*100
    else
      inScore

module.exports = scoreMahjongHand
module.exports.getPossibleHands = getPossibleHands
