_ = require('lodash')
gamePieces = require('./akagiTiles.coffee')

scoreMahjongHand = (hand) ->

  melds = getMelds(hand)



getPossibleHands = (hand) ->
  possibleHands = []
  allTerminalsAndHonors = gamePieces.allTerminalsAndHonorsGetter()

  if _.intersection(hand, allTerminalsAndHonors).length == 13 && _.xor(hand, allTerminalsAndHonors).length == 0
    hands.push("thirteenorphans")

  return hands

getMelds = (hand) ->

  return [{runs: [], triplets: [], pairs: []}, {runs: [], triplets: [], pairs: []}]

module.exports = scoreMahjongHand
