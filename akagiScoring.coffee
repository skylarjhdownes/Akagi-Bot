_ = require('lodash')
gamePieces = require('./akagiTiles.coffee')

yakuList = {
            "Riichi":                       {jpn: "Riichi",eng: "Riichi",score: 1},
            "Ippatsu":                      {jpn: "Ippatsu",eng: "One Shot",score: 1},
            "Daburu Riichi":                {jpn: "Daburu Riichi",eng: "Double Riichi",score: 1},
            "Menzen Tsumo":                 {jpn: "Menzen Tsumo",eng: "Fully Concealed Hand",score: 1},
            "Pinfu":                        {jpn: "Pinfu",eng: "Pinfu",score: 1},
            "Iipeikou":                     {jpn: "Iipeikou",eng: "Pure Double Chow",score: 1},
            "Tanyao Chuu":                  {jpn: "Tanyao Chuu",eng: "All Simples",score: 1},
            "San Shoku Doujin":             {jpn: "San Shoku Doujin",eng: "Mixed Triple Chow",score: 1},
            "Concealed San Shoku Doujin":   {jpn: "Concealed San Shoku Doujin",eng: "Concealed Mixed Triple Chow",score: 2},
            "Itsu":                         {jpn: "Itsu",eng: "Pure Straight",score: 1},
            "Concealed Itsu":               {jpn: "Concealed Itsu",eng: "Concealed Pure Straight",score: 2},
            "Dragon Fanpai/Yakuhai":        {jpn: "Dragon Fanpai/Yakuhai",eng: "Dragon Pung/Kong",score: 1},
            "Seat Fanpai/Yakuhai":          {jpn: "Seat Fanpai/Yakuhai",eng: "Seat Pung/Kong",score: 1},
            "Prevailing Fanpai/Yakuhai":    {jpn: "Prevailing Fanpai/Yakuhai",eng: "Prevailing Pung/Kong",score: 1},
            "Chanta":                       {jpn: "Chanta",eng: "Outside Hand",score: 1},
            "Concealed Chanta":             {jpn: "Concealed Chanta",eng: "Concealed Outside Hand",score: 2},
            "Rinshan Kaihou":               {jpn: "Rinshan Kaihou",eng: "After a Kong",score: 1},
            "Chan Kan":                     {jpn: "Chan Kan",eng: "Robbing a Kong",score: 1},
            "Haitei":                       {jpn: "Haitei",eng: "Under the Sea",score: 1},
            "Houtei":                       {jpn: "Houtei",eng: "Bottom of the Sea",score: 1},
            "Chi Toitsu":                   {jpn: "Chi Toitsu",eng: "Seven Pairs",score: 2},
            "San Shoku Dokou":              {jpn: "San Shoku Dokou",eng: "Triple Pung",score: 2},
            "San Ankou":                    {jpn: "San Ankou",eng: "Three Concealed Pungs",score: 2},
            "San Kan Tsu":                  {jpn: "San Kan Tsu",eng: "Three Kongs",score: 2},
            "Toitoi Hou":                   {jpn: "Toitoi Hou",eng: "All Pungs",score: 2},
            "Honitsu":                      {jpn: "Honitsu",eng: "Half Flush",score: 2},
            "Concealed Honitsu":            {jpn: "Concealed Honitsu",eng: "Concealed Half Flush",score: 3},
            "Shou Sangen":                  {jpn: "Shou Sangen",eng: "Little Three Dragons",score: 2},
            "Honroutou":                    {jpn: "Honroutou",eng: "All Terminals and Honours",score: 2},
            "Junchan":                      {jpn: "Junchan",eng: "Terminals in All Sets",score: 2},
            "Concealed Junchan":            {jpn: "Concealed Junchan",eng: "Concealed Terminals in All Sets",score: 3},
            "Ryan Peikou":                  {jpn: "Ryan Peikou",eng: "Twice Pure Double Chow",score: 3},
            "Chinitsu":                     {jpn: "Chinitsu",eng: "Full Flush",score: 5},
            "Concealed Chinitsu":           {jpn: "Concealed Chinitsu",eng: "Concealed Full Flush",score: 6},
            "Renho":                        {jpn: "Renho",eng: "Blessing of Man",score: 5},
            "Kokushi Musou":                {jpn: "Kokushi Musou",eng: "Thirteen Orphans",score: "Y"},
            "Chuuren Pooto":                {jpn: "Chuuren Pooto",eng: "Nine Gates",score: "Y"},
            "Tenho":                        {jpn: "Tenho",eng: "Blessing of Heaven",score: "Y"},
            "Chiho":                        {jpn: "Chiho",eng: "Blessing of Earth",score: "Y"},
            "Suu Ankou":                    {jpn: "Suu Ankou",eng: "Four Concealed Pungs",score: "Y"},
            "Suu Kan Tsu":                  {jpn: "Suu Kan Tsu",eng: "Four Kongs",score: "Y"},
            "Ryuu Iisou":                   {jpn: "Ryuu Iisou",eng: "All Green",score: "Y"},
            "Chinrouto":                    {jpn: "Chinrouto",eng: "All Terminals",score: "Y"},
            "Tsuu Iisou":                   {jpn: "Tsuu Iisou",eng: "All Honours",score: "Y"},
            "Dai Sangen":                   {jpn: "Dai Sangen",eng: "Big Three Winds",score: "Y"},
            "Shou Suushi":                  {jpn: "Shou Suushi",eng: "Little Four Winds",score: "Y"},
            "Dai Suushi":                   {jpn: "Dai Suushi",eng: "Big Four Winds",score: "Y"}
          }




#Class used to send data about game state into scorer
class gameFlags
  constructor: (@playerWind, @roundWind, @flags = []) ->
    @riichi = "Riichi" in @flags
    @ippatsu = "Ippatsu" in @flags
    @daburuRiichi = "Daburu Riichi" in @flags
    @houtai = "Houtai" in @flags
    @haitai = "Haitai" in @flags
    @chanKan = "Chan Kan" in @flags
    @rinshanKaihou = "Rinshan Kaihou" in @flags
    @tenho = "Tenho" in @flags
    @chiho = "Chiho" in @flags
    @renho = "Renho" in @flags


#Finds which tiles could turn a hand into a winning hand
tenpaiWith = (hand) ->
  winningTiles = []
  possibleTiles = []
  possibleTiles.push(new gamePieces.Tile(x,y)) for x in ["pin","sou","wan"] for y in [1..9]
  possibleTiles.push(new gamePieces.Tile("dragon",x)) for x in ["red","green","white"]
  possibleTiles.push(new gamePieces.Tile("wind",x)) for x in ["east","south","west","north"]
  for tile in possibleTiles
    testHand = _.cloneDeep(hand)
    testHand.lastTileDrawn = tile
    testHand.contains.push(tile)
    if(getPossibleHands(testHand).length > 0)
      if(_.filter(testHand.contains,(x)->_.isEqual(x,tile)).length < 5)
        winningTiles.push(tile)
        console.log(getPossibleHands(testHand))
  return winningTiles

#Checks whether a hand is the thirteen orphans hand or not.
thirteenOrphans = (hand,lastTile) ->
  testHand = hand.contains
  testHand.push(lastTile)
  return _.xorWith(testHand, gamePieces.allTerminalsAndHonorsGetter(), _.isEqual).length == 0

scoreMahjongHand = (hand, gameDataFlags, dora) ->
  #Takes a hand of mahajong tiles and finds the highest scoring way it can be interpreted, returning the score, and the melds which lead to that score
  possibleHands = getPossibleHands(hand)
  console.log(possibleHands)
  if possibleHands.length == 0
    return([0, "Not a Scoring Hand"])
  doras = getDora(hand,gameDataFlags.riichi,dora)
  doraPoints = doras[0]
  urDoraPoints = doras[1]
  scores = getScore(getYaku(handPattern, gameDataFlags), doraPoints, urDoraPoints) for handPattern in possibleHands
  console.log(scores)
  maxScore = _.maxBy(scores, (x) -> x[0])
  #maxLocation = _.indexOf(scores,maxScore)
  console.log(maxScore)
  return(maxScore)

getDora = (hand, riichi, doraSets) ->
  nextValue = {1:2,2:3,3:4,4:5,5:6,6:7,7:8,8:9,9:1,"East":"South","South":"West","West":"North","North":"East","Red":"White","White":"Green","Green":"Red"}
  dora = doraSets[0]
  urDora = doraSets[1]
  doraPoints = 0
  urDoraPoints = 0
  for doraIndicator in dora
    for tile in hand.contains
      if(doraIndicator.suit == tile.suit && nextValue[doraIndicator.value] == tile.value)
        doraPoints += 1
  if(riichi)
    for urDoraIndicator in urDora
      for tile in hand.contains
        if(urDoraIndicator.suit == tile.suit && nextValue[urDoraIndicator.value] == tile.value)
          urDoraPoints += 1
  return [doraPoints, urDoraPoints]

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
      _normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],remaining[1]])),remaining[2..])
    if(remaining.length >= 3)
      if(_.isEqual(remaining[0],remaining[1]) && _.isEqual(remaining[1],remaining[2]))
        _normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],remaining[1],remaining[2]])),remaining[3..])
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
        _normalHandFinder(_.concat(melds,new gamePieces.Meld([remaining[0],nextInRun,afterThat])),pruned)

  _drawnTilePlacer = () =>
    for pattern in possiblePatterns
      for meld, i in pattern
        if(meld.containsTile(hand.lastTileDrawn) && meld.takenFrom == "self")
          chosenOne = _.cloneDeep(meld)
          chosenOne.lastDrawnTile = _.clone(hand.lastTileDrawn)
          chosenOne.takenFrom = hand.lastTileFrom
          existingHand = _.cloneDeep(pattern)
          existingHand[i] = chosenOne
          possibleHands.push(existingHand)

  _normalHandFinder(hand.calledMelds,hand.uncalled())
  _drawnTilePlacer()

  return possibleHands


getYaku = (melds, gameDataFlags) ->
  #Takes a set of melds and returns the yaku that made up that score

  if(melds in ["thirteenorphans","thirteenorphans+"])
    return({yaku:["Kokushi Musou"],fu:0,flags:gameDataFlags})

  for meld in melds
    if meld.lastDrawnTile
      selfDraw = meld.takenFrom == "self"

  fuArray = _calculateFu(melds, selfDraw, gameDataFlags)
  fu = fuArray[0]
  meldFu = fuArray[1]

  isConcealedHand = true
  for meld in melds
    if(!meld.lastTileDrawn && meld.takenFrom != "self")
      isConcealedHand = false

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
    if (gameDataFlags.riichi) # winning player has called riichi
      yakuModifiers.push("Riichi")
      if(gameDataFlags.ippatsu)
        yakuModifiers.push("Ippatsu") #Winning on first round after declaring riichi
      if(gameDataFlags.daburuRiichi)
        yakuModifiers.push("Daburu Riichi") #Calling riichi on first turn of game

    if selfDraw #Menzen Tsumo - Self draw on concaled hand
      yakuModifiers.push("Menzen Tsumo")

    #Pinfu - Concealed all chows hand with a valuless pair
    if(fu != 25 && meldFu == 0)
      yakuModifiers.push("Pinfu")

    #Iipeikou - Concealed hand with two completely identical chow.
    if identicalChow in [2,6]
      yakuModifiers.push("Iipeikou")

    #Ryan Peikou - Concealed hand with two sets of two identical chows
    if identicalChow in [4,12]
      yakumodifiers.push("Ryan Peikou")

    #Chii Toitsu - Concealed hand with 7 pairs
    if melds.length == 7
      yakuModifiers.push("Chii Toitsu")

    #Renho - Blessing of Man, Win in first go round on discard
    if(gameDataFlags.renho)
      yakuModifiers.push("Renho")

  #Tanyao Chuu - All simples (no terminals/honors)
  if (_.every(meld, (x) -> !_meldContainsAtLeastOneTerminalOrHonor(x)))
    yakuModifiers.push("Tanyao Chuu")

  #Rinshan Kaihou - Mahjong declared on replacementTile from Kong
  if(gameDataFlags.rinshanKaihou)
    yakuModifiers.push("Rinshan Kaihou")

  #Chan Kan - Robbing the Kong, Mahjong when pung is extended to kong
  if(gameDataFlags.chanKan)
    yakuModifiers.push("Chan Kan")

  #Haitei - Winning off last drawn tile of wall
  if(gameDataFlags.haitei)
    yakuModifiers.push("Haitei")

  #Houtei - Winning off last tile discard in game
  if(gameDataFlags.houtei)
    yakuModifiers.push("Houtei")

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
  for meld in pungList
    if meld.suit() == "dragon"
      yakuModifiers.push("Dragon Fanpai/Yahuhai")
    if meld.value() == gameDataFlags.playerWind.toLowerCase()
      yakuModifiers.push("Seat Fanpai/Yakuhai")
    if meld.value() == gameDataFlags.roundWind.toLowerCase()
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
  if(isConcealedHand)
    #Kokushi Musou - 13 Orphans
    if(melds in ["thirteenorphans","thirteenorphans+"])
      yakuModifiers.push("Kokushi Musou")

    #Chuuren Pooto - Nine Gates
    if("Concealed Chinitsu" in yakuModifiers)
      if(kongList.length == 0)
        valuePattern = _.flattenDeep((meld.tiles for meld in melds))
        valuePattern = _.map(valuePattern, (x) -> x.value)
        stringPattern = _.join(valuePattern, "")
        if stringPattern in ["11112345678999","11122345678999","11123345678999","11123445678999","11123455678999","11123456678999","11123456778999","11123456788999","11123456789999"]
          yakuModifiers.push("Chuuren Pooto")

    #Tenho - Blessing of Heaven, mahjong on starting hand
    if(gameDataFlags.tenho)
      yakuModifiers.push("Tenho")

    #Chiho - Blessing of Earth, mahjong on first draw
    if(gameDataFlags.chiho)
      yakuModifiers.push("Chiho")

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



  return({yaku:yakuModifiers,fu:fu,flags:gameDataFlags,selfDraw:selfDraw})

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

  _calculateFu = (melds, selfDraw, gameDataFlags) ->
    isConcealedHand = melds.isConcealed()

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
            if(meld.value() == gameDataFlags.playerWind)
              meldFu += 2
            if(meld.value() == gameDataFlags.roundWind)
              meldFu += 2
          if(meld.lastDrawnTile)
            meldFu += 2
        if(meld.type == "Chow")
          if(meld.lastDrawnTile)
            if(meld.lastDrawnTile.value*3 == meld.tiles[0].value+meld.tiles[1].value+meld.tiles[2].value)
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
    return [fu, meldFu]

getScore = (values, dora, urDora) ->
  if(values.yaku.length == 0)
    return([0,["No Yaku"]])
  #Score the yakuModifiers list
  yakuman = false
  yakuPoints = 0
  printedYaku = []
  for yaku in values.yaku
    if(yakuList[yaku].score == "Y")
      yakuman = true
    else if(yaku != "Renho")
      yakuPoints += yakuList[yaku].score

  if(yakuman)
    printedYaku = (yaku for yaku in values.yaku when yakuList[yaku].score == "Y")
  else if("Renho" in values.yaku)
    if(yakuPoints > 0 && yakuPoints + dora > 5)
      printedYaku = (yaku for yaku in values.yaku when yaku != "Renho")
      fan = yakuPoints + dora + urDora
    else
      printedYaku = ["Renho"]
      fan = 5
  else
    printedYaku = values.yaku
    fan = yakuPoints + dora + urDora

  if "Renho" not in printedYaku
    if dora > 0
      printedYaku.push("Dora: #{dora}")
    if urDora > 0
      printedYaku.push("Ur Dora: #{urDora}")

  #Gives Base Score
  if yakuman
    baseScore = 8000
  else if fan >= 5
    if(fan == 5)
      baseScore = 2000
    else if(fan <= 7)
      baseScore = 3000
    else if(fan <= 10)
      baseScore = 4000
    else
      baseScore = 5000
  else
    baseScore = fu * math.pow(2,2+fan)
    if baseScore > 2000
      baseScore = 2000

#  #Takes base Score and multiplies it depending on seat wind and whether ron or tsumo
#  if(values.flags.playerWind == "east")
#    if(values.selfDraw)
#      score = _roundUpToClosestHundred(baseScore * 2)
#    else
#      score = _roundUpToClosestHundred(baseScore * 6)
#  else
#    if(values.selfDraw)
#      score = [_roundUpToClosestHundred(baseScore), _roundUpToClosestHundred(baseScore*2)]
#    else
#      score = _roundUpToClosestHundred(baseScore * 4)

  return [baseScore,printedYaku]


  _roundUpToClosestHundred = (inScore) ->
    if (inScore%100)!=0
      return (inScore//100+1)*100
    else
      inScore

module.exports.scoreMahjongHand = scoreMahjongHand
module.exports.getPossibleHands = getPossibleHands
module.exports.gameFlags = gameFlags
module.exports.tenpaiWith = tenpaiWith
module.exports.thirteenOrphans = thirteenOrphans
