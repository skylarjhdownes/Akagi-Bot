gamePieces = require('./akagiTiles.coffee')
player = require('./akagiPlayer.coffee')
Promise = require('promise')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerChannels, server, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [
      new player(playerChannels[1],1),
      new player(playerChannels[2],2),
      new player(playerChannels[3],3),
      new player(playerChannels[4],4)
    ]
    @gameObservationChannel = playerChannels[0]
    @startRoundOne()

  startRoundOne: ->
    #TODO: Randomize starting locations later
    @eastPlayer = @players[0]
    @southPlayer = @players[1]
    @westPlayer = @players[2]
    @northPlayer = @players[3]

    #Makes sure we know who plays after who
    @eastPlayer.setNextPlayer(@southPlayer.playerNumber)
    @southPlayer.setNextPlayer(@westPlayer.playerNumber)
    @westPlayer.setNextPlayer(@northPlayer.playerNumber)
    @northPlayer.setNextPlayer(@eastPlayer.playerNumber)

    @startRound("East",@eastPlayer)

  startRound:(prevailingWind,dealer) ->
    @prevailingWind = prevailingWind
    @dealer = dealer
    @turn = dealer.playerNumber
    @phase = 'draw'
    @wall.doraFlip()
    for player in @players
      player.hand.startDraw(@wall)
      player.roundStart()
      player.sendMessage("Prevailing wind is #{@prevailingWind}.")
      player.sendMessage("Dora is #{@wall.printDora()}.")

  drawTile:(playerToDraw) ->
    if(@turn == playerToDraw.playerNumber)
      if(@phase != "draw")
        playerToDraw.sendMessage("It is not the draw phase.")
      else
        playerToDraw.wallDraw(@wall)
        @phase = "discard"
    else
      playerToDraw.sendMessage("It is not your turn.")

  discardTile:(playerToDiscard,tileToDiscard) ->
    if(@turn == playerToDiscard.playerNumber)
      if(@phase == "discard")
        discarded = playerToDiscard.discardTile(tileToDiscard)
        if(discarded)
          @gameObservationChannel.send("Player #{playerToDiscard.playerNumber} discarded a #{discarded.getName()}.")
          for player in @players
            if(player.playerNumber != playerToDiscard.playerNumber)
              player.sendMessage("Player #{playerToDiscard.playerNumber} discarded a #{discarded.getName(player.namedTiles)}.")
          @turn = playerToDiscard.nextPlayer
          @phase = "react"
          waitTenSeconds = new Promise((resolve, reject) =>
            setTimeout(->
              resolve("Time has Passed")
            ,1000))
          waitTenSeconds
            .then((message)=>
              @phase = "draw"
              for player in @players
                if(@turn == player.playerNumber)
                  player.sendMessage("It is your turn.  You may draw a tile."))
            .catch(console.error)
        else
          playerToDiscard.sendMessage("You don't have that tile.")
      else
        playerToDiscard.sendMessage("Its not the discard phase.")
    else
      playerToDiscard.sendMessage("Its not your turn.")


module.exports = MahjongGame
