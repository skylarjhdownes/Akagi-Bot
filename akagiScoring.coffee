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

  if _.intersection(hand, allTerminalsAndHonors).length == 13 && _.xor(hand, allTerminalsAndHonors).length == 0
    possibleHands.push("thirteenorphans") #Potentially want to add a check to see if it was a 13 way wait to this.  Some rules have double yakuman for that.

  if _.uniq(hand).length == 7
    pairGroup = _.chunk(hand, 2)
    if _.every(pairGroup, (x) -> gamePieces.isTileSet(x) == "Pair")
      possibleHands.push({runs: [], triplets: [], pairs: pairGroup}) #I forget how objects work in js. If pairGroup is just a reference, maybe this will cause bugs.

  return possibleHands


#I don't know what this function does differently than getPossibleHands, unless its just a subfunction dealing with some of the logic for normal kinds of melds
#getMelds = (hand) ->

  #return [{runs: [], triplets: [], pairs: []}, {runs: [], triplets: [], pairs: []}]

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
