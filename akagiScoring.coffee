require(['./akagiTiles.coffee', 'lodash'], (gamePieces, _) ->

  scoreMahjongHand = (hand) ->
    #Takes a hand of mahajong tiles and finds the highest scoring way it can be interpreted, returning the score, and the melds which lead to that score
    possibleHands = getPossibleHands(hand)
    scores = getScore(x) for x in possibleHands
    maxScore = _.max(scores)
    maxLocation = _.indexOf(scores,maxScore)
    return true

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

  getScore = (melds) ->
    #Takes a set of melds and returns the score of that particular combination of getMelds and the yaku that made up that score
    yakuman = false
    yaku = 0
    dora = 0
    fu = 0
    if(melds == "thirteenorphans")
      yakuman = "thirteenorphans"
    #Check for yakuman
    # if(isYakuman)
    #   #Return yakuman score and name of isYakuman
    # #Check for yaku
    # if(yaku == 0)
    #   #Return 0 and "Not a winning hand, no Yaku"
    # #Check for dora
    # fan = yaku+dora
    # if(fan>=5)
      #Return scored points and yaku plus dora in hand
    #Check for fu
    #Return scored points and yaku + dora + fu in hand

  module.exports = scoreMahjongHand
)
