gamePieces = require('./akagiTiles.coffee')
playerObject = require('./akagiPlayer.coffee')
Promise = require('promise')
_ = require('lodash')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerChannels, server, gameSettings) ->
    @wall = new gamePieces.Wall()
    @players = [
      new playerObject(playerChannels[1],1),
      new playerObject(playerChannels[2],2),
      new playerObject(playerChannels[3],3),
      new playerObject(playerChannels[4],4)
    ]
    @gameObservationChannel = playerChannels[0]
    @startRoundOne()

  startRoundOne: ->
    #TODO: Randomize starting locations later
    @eastPlayer = @players[0]
    @southPlayer = @players[1]
    @westPlayer = @players[2]
    @northPlayer = @players[3]

    #Make player know own winds
    @eastPlayer.setWind("East")
    @southPlayer.setWind("South")
    @westPlayer.setWind("West")
    @northPlayer.setWind("North")

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

  chiTile:(playerToChi, tile1, tile2) ->
    if(@phase == "draw")
      if(@playerToChi.playerNumber == @turn)
        #Chi Logic Here
        return(true)
      else
        playerToChi.sendMessage("May only Chi when you are next in turn order.")
    else if(@phase.isArray)
      playerToChi.sendMessage("Chi has lower priority than Pon and Ron.")
    else
      playerToChi.sendMessage("Wrong time to Chi")

  ponTile:(playerToPon) ->
    if(@phase in ["react","draw"] && @turn != playerToPon.nextPlayer)
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
                      player.sendMessage("Your Pon has completed. Please discard a tile.")
                    else
                      player.sendMessage("Player #{playerToPon.playerNumber}'s Pon has completed.")
                  @turn = playerToPon.playerNumber
              )
              .catch(console.error)
          else
            playerToPon.sendMessage("Don't have correct tiles.")
    else if(@phase.isArray && @phase[0] == "chiing")
      for player in @players
        if(@turn == player.nextPlayer)
          toPon = player.discardPile.contains[-1..][0]
          if(_.findIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x))!=_.findLastIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x)))
            if(@playerToPon.playerNumber != @phase[1])
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
                        player.sendMessage("Your Pon has completed. Please discard a tile.")
                      else
                        player.sendMessage("Player #{playerToPon.playerNumber}'s Pon has completed.")
                    @turn = playerToPon.playerNumber
                  )
                  .catch(console.error)
            else
              playerToPon.sendMessage("Can't pon if you already called chi.")
          else
            playerToPon.sendMessage("Don't have correct tiles.")
    else if(@phase.isArray && @phase[0] == "roning")
      playerToPon.sendMessage("Pon has lower priorty than Ron.")
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
