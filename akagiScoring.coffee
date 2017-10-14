
scoreMahjongHand = (hand) ->
  melds = getMelds(hand)


getMelds = (hand) ->

  return [{runs: [], triplets: [], pairs: []}, {runs: [], triplets: [], pairs: []}]

module.exports = scoreMahjongHand
