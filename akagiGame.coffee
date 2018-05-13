gamePieces = require('./akagiTiles.coffee')
player = require('./akagiPlayer.coffee')
Promise = require('promise')
_ = require('lodash')

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

  ponTile:(playerToPon) ->
    if(@phase in ["react","draw"] && @turn != playerToPon.playerNumber)
      for player in @players
        if(@turn == player.nextPlayer)
          toPon = player.discardPile.contains[-1..][0]
          if(_.findIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x))!=_.findLastIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x)))
            @phase = ["poning",playerToPon.playerNumber]
            for player in @players
              if(player.playerNumber != playerToPon.playerNumber)
                player.sendMessage("Player #{playerToPon.playerNumber} has declared Pon.")
              else
                player.sendMessage("You have declared Pon.")
            waitTenSeconds = new Promise((resolve,reject) =>
              setTimeout(->
                resolve("Time has Passed")
              ,1000))
            waitTenSeconds
              .then((message)=>
                if(_.isEqual(@phase,["poning",playerToPon.playerNumber]))
                  @phase = "discard"
                  for player in @players
                    if(@turn == player.nextPlayer)
                      playerToPon.hand.draw(player.discardPile)
                      playerToPon.hand.calledMelds.push(new gamePieces.Meld([toPon,toPon,toPon],player.playerNumber))
                    if(player.playerNumber == playerToPon.playerNumber)
                      player.message("Your Pon has completed. Please discard a tile.")
                    else
                      player.message("Player #{playerToPon.playerNumber}'s Pon has completed.")
                  @turn = playerToPon.playerNumber
              )
              .catch(console.error)
          else
            playerToPon.sendMessage("Don't have correct tiles.")
    else if(@phase.isArray && @phase[0] == "poning")
      for player in @players
        if(@turn == player.nextPlayer)
          toPon = player.discardPile.contains[-1..][0]
          if(_.findIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x))!=_.findLastIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x)))
            if(player.nextPlayer == playerToPon.playerNumber || playerToPon.nextPlayer == @phase[1])
              @phase = ["poning",playerToPon.playerNumber]
              for player in @players
                if(player.playerNumber != playerToPon.playerNumber)
                  player.sendMessage("Player #{playerToPon.playerNumber} has declared Pon.")
                else
                  player.sendMessage("You have declared Pon.")
              waitTenSeconds = new Promise((resolve,reject) =>
                setTimeout(->
                  resolve("Time has Passed")
                ,1000))
              waitTenSeconds
                .then((message) =>
                  if(_.isEqual(@phase,["poning",playerToPon.playerNumber]))
                    @phase = "discard"
                    for player in @players
                      if(@turn == player.nextPlayer)
                        playerToPon.hand.draw(player.discardPile)
                        playerToPon.hand.calledMelds.push(new gamePieces.Meld([toPon,toPon,toPon],player.playerNumber))
                      if(player.playerNumber == playerToPon.playerNumber)
                        player.message("Your Pon has completed. Please discard a tile.")
                      else
                        player.message("Player #{playerToPon.playerNumber}'s Pon has completed.")
                    @turn = playerToPon.playerNumber
                  )
                  .catch(console.error)
            else
              playerToPon.message("Other player's Pon has higher priority.")
          else
            playerToPon.sendMessage("Don't have correct tiles.")
    else
      playerToPon.sendMessage("Wrong time to Pon.")



  discardTile:(playerToDiscard,tileToDiscard) ->
    if(@turn == playerToDiscard.playerNumber)
      if(@phase == "discard")
        discarded = playerToDiscard.discardTile(tileToDiscard)
        if(discarded)
          @gameObservationChannel.send("Player #{playerToDiscard.playerNumber} discarded a #{discarded.getName()}.")
          for player in @players
            if(player.playerNumber != playerToDiscard.playerNumber)
              player.sendMessage("Player #{playerToDiscard.playerNumber} discarded a #{discarded.getName(player.namedTiles)}.")
            else
              player.sendMessage("You discarded a #{discarded.getName(player.namedTiles)}.")
          @turn = playerToDiscard.nextPlayer
          @phase = "react"
          waitTenSeconds = new Promise((resolve, reject) =>
            setTimeout(->
              resolve("Time has Passed")
            ,1000))
          waitTenSeconds
            .then((message)=>
              if(@phase == "react")
                @phase = "draw"
                for player in @players
                  if(@turn == player.playerNumber)
                    player.sendMessage("It is your turn.  You may draw a tile."))
            .catch(console.error)
        else
          playerToDiscard.sendMessage("You don't have that tile.")
      else
        playerToDiscard.sendMessage("It is not the discard phase.")
    else
      playerToDiscard.sendMessage("It is not your turn.")


module.exports = MahjongGame
