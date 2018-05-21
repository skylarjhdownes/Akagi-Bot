_ = require('lodash')
gamePieces = require('./akagiTiles.coffee')

japaneseYaku = ["Riichi","Ippatsu","Daburu Riichi","Menzen Tsumo","Pinfu","Iipeikou","Tanyao Chuu","San Shoku Doujun","Concealed San Shoku Doujin","Itsu","Concealed Itsu","Dragon Fanpai/Yakuhai","Seat Fanpai/Yakuhai","Prevailing Fanpai/Yakuhai","Chanta","Concealed Chanta","Rinshan Kaihou","Chan Kan","Haitei","Houtai","Chi Toitsu","San Shoku Dokou","San Ankou","San Kan Tsu","Toi-Toi Hou","Honitsu","Concealed Honitsu","Shou Sangen","Honroutou","Junchan","Concealed Junchan","Ryan Peikou","Chinitsu","Concealed Chinitsu","Renho","Kokushi Musou","Chuuren Pooto","Tenho","Chiho","Suu Ankou","Suu Kan Tsu", "Ryuu Iisou","Chinrouto","Tsuu Iisou","Dai Sangen","Shou Suushii","Dai Suushii"]
englishYaku = ["Riichi","Quick Riichi","Double Riichi","Fully Concealed Hand","Pinfu","Pure Double Chow","All Simples","Mixed Triple Chow","Concealed Mixed Triple Chow","Pure Straight","Concealed Pure Straight","Dragon Point","Seat Point","Prevailing Point","Outside Hand","Concealed Outside Hand","After a Kong","Under the Sea","Underer the Sea","Seven Pairs","Triple Pung","Three Concealed Pungs","Three Kongs","All Pungs","Half Flush","Concealed Half Flush","Little Three Dragons","All Terminals and Honors","Terminals in All Sets","Concealed Terminals in All Sets","Twice Pure Double Chows","Full Flush","Concealed Full Flush","Blessing of Man","Thirteen Orphans","Nine Gates","Blessing of Heaven","Blessing of Earth","Four Concealed Pungs","Four Kongs","All Green","All Terminals","All Honors","Big Three Dragons","Little Four Winds","Big Four Winds"]

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
  possiblePatterns = []
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()
  handTiles = hand.contains
  if _.intersectionWith(handTiles, allTerminalsAndHonors,_.isEqual).length == 13 && _.xorWith(handTiles, allTerminalsAndHonors,_.isEqual).length == 0
    drawLocation = _.findIndex(handTiles,(x)->_.isEqual(hand.lastTileDrawn,x))
    if(drawLocation == 13 || !_.isEqual(handTiles[drawLocation],handTiles[drawLocation+1]))
      return(["thirteenorphans"]) #Normal 13 orphans
    else
      return(["thirteenorphans+"]) #13 way wait, 13 orphans

  if _.uniqWith(handTiles,_.isEqual).length == 7
    pairGroup = _.chunk(handTiles, 2)
    if _.every(pairGroup, (x) -> gamePieces.isMeld(x) == "Pair")
      possiblePatterns.push(_.map(pairGroup,(x)-> return new gamePieces.Meld(x)))

  #Any hands other than pairs/13 orphans
  _normalHandFinder = (melds, remaining) =>
    if(!remaining || remaining.length == 0)
      possiblePatterns.push(melds)
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
      normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],remaining[1]])),remaining[2..])
    if(remaining.length >= 3)
      if(_.isEqual(remaining[0],remaining[1]) && _.isEqual(remaining[1],remaining[2]))
        normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],remaining[1],remaining[2]])),remaining[3..])
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
        normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],nextInRun,afterThat])),pruned)

  _drawnTilePlacer = () =>
    for pattern in possiblePatterns
      for meld, i in pattern
        if(meld.containsTile(hand.lastTileDrawn))
          chosenOne = _.deepCopy(meld)
          chosenOne.lastTileDrawn = _.copy(hand.lastTileDrawn)
          chosenOne.takenFrom = hand.lastTileFrom
          existingHand = _.deepCopy(pattern)
          existingHand[i] = chosenOne
          possibleHands.push(existingHand)

  # uncalled = handTiles
  # for x in hand.calledMelds
  #   for y in x
  #     remove = uncalled.indexOf(y)
  #     uncalled.splice(remove,1)

  _normalHandFinder(hand.calledMelds,hand.uncalled())
  _drawnTilePlacer()

  return possibleHands


getScore = (melds, winningPlayer) ->
  #Takes a set of melds and returns the score of that particular combination of getMelds and the yaku that made up that score

  #Going to have to get this info in somehow.
  roundWind = ""
  playerWind = ""
  selfDraw = false

  isConcealedHand = melds.isConcealed()
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()

  yakuman = false
  yaku = 0
  dora = 0
  fu = _calculateFu(melds, isConcealedHand, selfDraw, playerWind, roundWind)


  yakuModifiers = []  #I think it could be more useful to calc out all of the yaku names,
                      #and then generate a score from that.  Plus we could print them all for the player.
                      #Romanji names used in the code, but output can use either romanji or english using translation lists up above.

  suitList = (meld.suit() for meld in melds)
  chowList = (meld for meld in melds when meld.type == "Chow")
  pungList = (meld for meld in melds when meld.type in ["Pung","Kong"])
  kongList = (meld for meld in melds when meld.type == "Kong")
  concealedPungs = 0 #Used for San Ankou
  identicalChow = 0 #Used for Iipeikou and Ryan Peikou
  similarChow = {} #Used for San Shoku Doujin
  similarPung = {} #Used for San Shoku Dokou
  possibleStaight = {} #Used for Itsu
  for chow1, index1 in chowList
    if(chow1.value() in ["1 - 2 - 3","4 - 5 - 6","7 - 8 - 9"])
      if chow1.suit() of possibleStraight
        possibleStraight[chow1.suit()].push(chow1.value())
      else
        possibleStraight[chow1.suit()] = [chow1.value()]
    for chow2, index2 in chowList
      if(index1 != index2)
        if _.isEqual(chow1,chow2)
          identicalChow += 1
        else if(chow1.value() == chow2.value())
          if chow1.value() of similarChow
            similarChow[chow1.value()].push(chow1.suit())
          else
            similarChow[chow1.value()] = [chow1.suit()]

  for pung in pungList
    if(pung.suit() in ["pin","sou","wan"])
      if pung.value() of similarPung
        similarPung[pung.value()].push(pung.suit())
      else
        similarPung[pung.value()] = [pung.suit()]
    if(pung.takenFrom == "self")
      concealedPungs += 1

  #These should probably all be wrapped up into their own functions.
  if isConcealedHand
    if (winningPlayer.hand.discardPile.riichi != -1) # winning player has called riichi
      yakuModifiers.push("Riichi")
    if selfDraw #Menzen Tsumo - Self draw on concaled hand
      yakuModifiers.push("Menzen Tsumo")

    #Pinfu - Concealed all chows hand with a valuless pair
    if(fu != 25 && meldFu == 0)
      yakuModifiers.push("Pinfu")

    #Iipeikou - Concealed hand with two completely identical chow.
    if identicalChow == 2
      yakuModifiers.push("Iipeikou")

    #Ryan Peikou - Concealed hand with two sets of two identical chows
    if identicalChow == 4
      yakumodifiers.push("Ryan Peikou")

    #Chii Toitsu - Concealed hand with 7 pairs
    if melds.length == 7
      yakuModifiers.push("Chii Toitsu")

  #Tanyao Chuu - All simples (no terminals/honors)
  if (_.every(meld, (x) -> !_meldContainsAtLeastOneTerminalOrHonor(x)))
    yakuModifiers.push("Tanyao Chuu")

  #San Shoku Doujin - Mixed Triple Chow
  for value,suit of similarChow
    if(_.uniq(suit).length == 3)
      if(isConcealed)
        yakuModifiers.push("Concealed San Shoku Doujin")
      else
        yakuModifiers.push("San Shoku Doujin")

  #San Shoku Dokou - Triple Pung in different suits
  for value, suit of similarPung
    if(_.uniq(suit).length == 3)
      yakuModifiers.push("San Shoku Dokou")

  #San Kan Tsu - Three Kongs
  if(kongList.length == 3)
    yakuModifiers.push("San Kan Tsu")

  #San Ankou - 3 Concealed Pungs
  if(concealedPungs == 3)
    yakuModifiers.push("San Ankou")

  #Itsu - Pure Straight
  for suit,value of possibleStaight
    if(_.uniq(value).length == 3)
      if(isConcealed)
        yakuModifiers.push("Concealed Itsu")
      else
        yakuModifiers.push("Itsu")

  #Fanpai/Yakuhai - Pung/kong of dragons, round wind, or player wind.
    # Can likely be drastically simplified since we know each pung/kong is 3/4 of a kind already
    # Will also need to be taken into account for higher value hands, 3 dragons etc.
  for meld in melds when meld.type == "Pung" || meld.type == "Kong"
    if meld.suit() == "dragon"
      yakuModifiers.push("Dragon Fanpai/Yahuhai")
    if _meldContainsOnlyGivenTile(meld, new Tile("wind", playerWind))
      yakuModifiers.push("Seat Fanpai/Yakuhai")
    if _meldContainsOnlyGivenTile(meld, new Tile("wind", roundWind))
      yakuModifiers.push("Prevailing Fanpai/Yakuhai")

  #Chanta - All sets contain terminals or honours, the pair is terminals or honours, and the hand contains at least one chow.
  if (meld for meld in melds when meld.type == "Chow").length > 0 &&
      meldContainsOnlyTerminalsOrHonors(meld for meld in melds when meld.type == "Pair")
    if _.filter((meld for meld in melds when meld.type != "Pair"), _meldContainsAtLeastOneTerminalOrHonor).length == 4
      if(isConcealedHand)
        yakuModifiers.push("Concealed Chanta")
      else
        yakuModifiers.push("Chanta")

  #Shou Sangen - Little Three Dragons, two pungs/kongs and a pair of Dragons
  if((pung for pung in pungList when pung.suit()=="dragon").length == 2)
    if((suit for suit in suitList when suit == "dragon").length == 3)
      yakuModifiers.push("Shou Sangen")

  #Honroutou - All Terminals and Honors
  if(_.intersection(suitList,["dragon","wind"]).length > 0 && _.xor(suitList,["dragon","wind"]).length > 0)
    if (meld for meld in melds when (meld.suit() in ["dragon","wind"] || meld.value() in [1,9])).length == melds.length
      yakuModifiers.push("Honroutou")

  #Junchan - Terminals in All Sets, but at least one Chow
  if(chowList.length > 0 && _.every(meld, _meldContainsAtLeastOneTerminalOrHonor))
    if(isConcealed)
      yakuModifiers.push("Concealed Junchan")
    else
      yakuModifiers.push("Junchan")

  #Honitsu - Half Flush - One suit plus honors
  if(_.intersection(suitList,["dragon","wind"]).length > 0 && _.xor(suitList,["dragon","wind"]).length == 1)
    if(isConcealed)
      yakuModifiers.push("Concealed Honitsu")
    else
      yakuModifiers.push("Honitsu")

  #Chinitsu - Full Flush - One Suit, no honors
  if(_.uniq(suitList).length == 1 and suitList[0] not in ["dragon", "wind"])
    if(isConcealed)
      yakuModifiers.push("Concealed Chinitsu")
    else
      yakuModifiers.push("Chinitsu")


  #Yakuman

  #Kokushi Musou - 13 Orphans
  if(melds == "thirteenorphans")
    yakuModifiers.push("Kokushi Musou")

  #Chuuren Pooto - Nine Gates
  if("Concealed Chinitsu" in yakuModifiers)
    if(kongList.length == 0)
      valuePattern = _.flattenDeep((meld.tiles for meld in melds))
      valuePattern = _.map(valuePattern, (x) -> x.value)
      stringPattern = _.join(valuePattern, "")
      if stringPattern in ["11112345678999","11122345678999","11123345678999","11123445678999","11123455678999","11123456678999","11123456778999","11123456788999","11123456789999"]
        yakuModifiers.push("Chuuren Pooto")
  #Suu Ankou - Four Concealed Pungs
  if(concealedPungs == 4)
    yakuModifiers.push("Suu Ankou")

  #Suu Kan Tsu - Four Kongs
  if(kongList.length == 4)
    yakuModifiers.push("Suu Kan Tsu")

  #Ryuu Iisou - All Green
  if(_.every(meld,_meldIsGreen))
    yakuModifiers.push("Ryuu Iisou")

  #Chinrouto - All Terminals
  if(_.every(meld,(x) -> meld.value() in [1,9]))
    yakuModifiers.push("Chinrouto")

  #Tsuu Iisou - All Honors
  if(_.every(meld,(x) -> meld.suit() in ["dragon", "wind"]))
    yakuModifiers.push("Tsuu Iisou")

  #Dai Sangan - Big Three Dragons
  if((pung for pung in pungList when pung.suit()=="dragon").length == 3)
    yakuModifiers.push("Dai Sangan")

  #Shou Suushii - Little Four Winds
  if((suit for suit in suitList when suit == "wind").length == 4)
    if((pung for pung in pungList when pung.suit() == "wind").length == 3)
      yakuModifiers.push("Shou Suushii")

  #Dai Suushii - Big Four Winds
  if((pung for pung in pungList when pung.suit() == "wind").length == 4)
    yakuModifiers.push("Dai Suushii")


  #Score the yakuModifier list
  #Check for dora
  fan = yaku+dora
  if fan >= 5
    console.log("not implemented yet.")
    #Return scored points and yaku plus dora in hand
  #Check for fu

  baseScore = math.pow(fu,2+fan)
  #Return scored points and yaku + dora + fu in hand

_calculateFu = (melds, isConcealedHand, selfDraw, playerWind, roundWind) ->
  baseFu = 0
  if(melds.length == 7)
    baseFu = 25
  else if(isConcealedHand && !selfDraw)
    baseFu = 30
  else
    baseFu = 20

  meldFu = 0
  if(melds.length != 7)
    for meld in melds
      if(meld.type == "Pung")
        if(meld.suit() in ["dragon","wind"] || meld.value() in [1,9])
          if(meld.takenFrom == "self")
            meldFu += 8
          else
            meldFu += 4
        else
          if(meld.takenFrom == "self")
            meldFu += 4
          else
            meldFu += 2
      if(meld.type == "Kong")
        if(meld.suit() in ["dragon","wind"] || meld.value() in [1,9])
          if(meld.takenFrom == "self")
            meldFu += 32
          else
            meldFu += 16
        else
          if(meld.takenFrom == "self")
            meldFu += 16
          else
            meldFu += 8
      if(meld.type == "Pair")
        if(meld.suit() == "dragon")
          meldFu += 2
        else if(meld.suit() == "wind")
          if(meld.value() == playerWind)
            meldFu += 2
          if(meld.value() == roundWind)
            meldFu += 2
        if(meld.lastDrawnTile)
          meldFu += 2
      if(meld.type == "Chow")
        if(meld.lastDrawnTile)
          if(meld.lastDrawnTile.value == (meld.tiles[0].value+meld.tiles[1].value+meld.tiles[2].value)/3)
            meldFu += 2
          if(meld.value() == "1 - 2 - 3" && meld.lastDrawnTile.value == 3)
            meldFu += 2
          if(meld.value() == "7 - 8 - 9" && meld.lastDrawnTile.value == 7)
            meldFu += 2
    if(!(meldFu == 0 && isConcealedHand) && selfDraw)
      meldFu += 2
    if(meldFu == 0 && !isConcealedHand)
      meldFu += 2

  fu = baseFu + meldFu
  if(fu != 25)
    fu = _roundUpToClosestHundred(fu)
  return fu


_meldContainsAtLeastOneTerminalOrHonor = (meld) ->
  for tile in meld.tiles
    if tile.isHonor() || tile.isTerminal()
      return true
  return false

_meldIsGreen = (meld) ->
  for tile in meld.tiles
    if !tile.isGreen()
      return false
  return true

_meldContainsOnlyGivenTile = (meld, givenTile) ->
  allSameTile = true
  for tile in meld.tiles
    if tile != givenTile
      allSameTile = false
      break
  return allSameTile

_roundUpToClosestHundred = (inScore) ->
  if (inScore%100)!=0
    return (inScore//100+1)*100
  else
    inScore

module.exports = scoreMahjongHand
module.exports.getPossibleHands = getPossibleHands
