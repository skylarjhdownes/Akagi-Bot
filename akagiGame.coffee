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
    #Randomize starting locations, then assign each player a seat.
    @players = _.shuffle(@players)
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
    @phase = 'discard'
    @wall.doraFlip()
    for player in @players
      player.hand.startDraw(@wall)
      player.roundStart(@wall)
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
      if(playerToChi.playerNumber == @turn)
        if(_.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile1, x)) != -1 && _.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile2, x)) != -1)
          for discarder in @players
            if(@turn == discarder.nextPlayer)
              toChi = discarder.discardPile.contains[-1..][0]
              _chiable = (t1,t2,t3) ->
                if(t1.suit!=t2.suit || t2.suit!=t3.suit)
                  return false
                sortedValues = [t1.value,t2.value,t3.value].sort()
                if(sortedValues[0]+1 == sortedValues[1] && sortedValues[1]+1 == sortedValues[2])
                  return true
                else
                  return false
              if(_chiable(toChi,tile1,tile2))
                @phase = ["chiing",playerToChi.playerNumber]
                for player in @players
                  if(player.playerNumber != playerToChi.playerNumber)
                    player.sendMessage("Player #{playerToChi.playerNumber} has declared Chi.")
                  else
                    player.sendMessage("You have declared Chi.")
                chiAfterTen = new Promise((resolve,reject) =>
                  setTimeout(->
                    resolve("Time has Passed")
                  ,1000))
                chiAfterTen
                  .then((message)=>
                    if(_.isEqual(@phase,["chiing",playerToChi.playerNumber]))
                      @phase = "discard"
                      for player in @players
                        if(@turn == player.nextPlayer)
                          playerToChi.hand.draw(player.discardPile)
                          playerToChi.hand.calledMelds.push(new gamePieces.Meld([toChi,tile1,tile2],player.playerNumber))
                          player.sendMessage("Player #{playerToChi.playerNumber}'s Chi has completed.'")
                        else if(player.playerNumber == playerToChi.playerNumber)
                          player.sendMessage("Your Chi has completed.  Please discard a tile.")
                        else
                          player.sendMessage("Player #{playerToChi.playerNumber}'s Chi has completed.'")
                  )
                  .catch(console.error)
              else
                playerToChi.sendMessage("Tiles specified do not create a legal meld.")
        else
          playerToChi.sendMessage("Hand doesn't contain tiles specified.")

      else
        playerToChi.sendMessage("May only Chi when you are next in turn order.")
    else if(@phase.isArray)
      playerToChi.sendMessage("Chi has lower priority than Pon, Kan, and Ron.")
    else
      playerToChi.sendMessage("Wrong time to Chi")

  selfKanTiles:(playerToKan,tileToKan) ->
    uncalledKanTiles = _.filter(playerToKan.hand.uncalled(),(x) -> _.isEqual(x,tileToKan)).length
    if(@turn != playerToKan.playerNumber)
      playerToKan.sendMessage("It is not your turn.")
    else if(@phase != "discard")
      playerToKan.sendMessage("One can only self Kan during one's own turn after one has drawn.")
    else if(uncalledKanTiles < 1)
      playerToKan.sendMessage("No tiles to Kan with.")
    else if(uncalledKanTiles in [2,3])
      playerToKan.sendMessage("Wrong number of tiles to Kan with.")
    else
      if(uncalledKanTiles == 4)
        @phase = ["concealedKaning",tileToKan]
        for player in @players
          if(player.playerNumber != playerToKan.playerNumber)
            player.sendMessage("Player #{playerToKan.playerNumber} has declared a concealed Kan on #{tileToKan.getName(player.namedTiles)}.")
          else
            player.sendMessage("You have declared a concealed Kan on #{tileToKan.getName(player.namedTiles)}.")
        concealAfterTen = new Promise((resolve,reject) =>
          setTimeout(->
            resolve("Time has Passed")
          ,1000))
        concealAfterTen
          .then(
            if(_.isEqual(@phase,["concealedKaning",tileToKan]))
              @phase = "discard"
              playerToKan.hand.calledMelds.push(new gamePieces.Meld([tileToKan,tileToKan,tileToKan,tileToKan]))
              drawnTile = playerToKan.hand.draw(@wall)
              @wall.doraFlip()
              for player in @players
                if(player.playerNumber!=playerToKan.playerNumber)
                  player.sendMessage("Player #{playerToKan.playerNumber} has completed their Kan.")
                else
                  player.sendMessage("You have completed your Kan.")
                  player.sendMessage("Your deadwall draw is #{drawnTile.getName(player.namedTiles)}.")
                player.sendMessage("The Dora Tiles are now: #{@wall.printDora(player.namedTiles)}")
              @turn = playerToKan.playerNumber
          )
          .catch(console.error)
      else
        pungToExtend = _.filter(playerToKan.hand.calledMelds,(x) -> x.type == "Pung" && x.suit() == tileToKan.suit && x.value() == tileToKan.value)
        if(pungToExtend.length == 1)
          pungToExtend = pungToExtend[0]
          @phase = ["extendKaning",tileToKan]
          for player in @players
            if(player.playerNumber != playerToKan.playerNumber)
              player.sendMessage("Player #{playerToKan.playerNumber} has declared an extended Kan on #{tileToKan.getName(player.namedTiles)}.")
            else
              player.sendMessage("You have declared an extended Kan on #{tileToKan.getName(player.namedTiles)}.")
          extendAfterTen = new Promise((resolve,reject) =>
            setTimeout(->
              resolve("Time has Passed")
            ,1000))
          extendAfterTen
            .then(
              if(_.isEqual(@phase,["extendKaning",tileToKan]))
                @phase = "discard"
                for meld in playerToKan.hand.calledMelds
                  if(meld.type == "Pung" && meld.suit() == tileToKan.suit && meld.value() == tileToKan.value)
                    playerToKan.hand.calledMelds.makeKong()
                drawnTile = playerToKan.hand.draw(@wall)
                @wall.doraFlip()
                for player in @players
                  if(player.playerNumber!=playerToKan.playerNumber)
                    player.sendMessage("Player #{playerToKan.playerNumber} has completed their Kan.")
                  else
                    player.sendMessage("You have completed your Kan.")
                    player.sendMessage("Your deadwall draw is #{drawnTile.getName(player.namedTiles)}.")
                  player.sendMessage("The Dora Tiles are now: #{@wall.printDora(player.namedTiles)}")
                @turn = playerToKan.playerNumber
            )
            .catch(console.error)
        else
          playerToKan.sendMessage("Don't have Pung to extend into Kong.")


  openKanTiles:(playerToKan) ->
    if(@phase.isArray && @phase[0] == "roning")
      playerToKan.sendMessage("Kan has lower priority than Ron.")
    else if(@phase.isArray && @phase[0] == "chiing" && playerToPon.playerNumber == @phase[1])
      playerToKan.sendMessage("One cannot Kan if one has already declared Chi.")
    else if((@phase.isArray && @phase[0] == "chiing") || @phase in ["react","draw"])
      discarder = _.find(@players,(x)-> @turn == x.nextPlayer)
      toKan = discarder.discardPile.contains[-1..][0]
      if(_.filter(playerToKan.hand.uncalled(),(x) -> _.isEqual(x,toKan)).length == 3)
        @phase = ["callKaning",playerToKan.playerNumber]
        for player in @players
          if(player.playerNumber!= playerToKan.playerNumber)
            player.sendMessage("Player #{playerToKan.playerNumber} has declared Kan.")
          else
            player.sendMessage("You have declared Kan.")
        kanAfterTen = new Promise((resolve,reject) =>
          setTimeout(->
            resolve("Time has Passed")
          ,1000))
        kanAfterTen
          .then(
            if(_.isEqual(@phase,["callKaning",playerToKan.playerNumber]))
              @phase = "discard"
              playerToKan.hand.draw(discarder.discardPile)
              playerToKan.hand.calledMelds.push(new gamePieces.Meld([toKan,toKan,toKan,toKan],discarder.playerNumber))
              drawnTile = playerToKan.hand.draw(@wall)
              @wall.doraFlip()
              for player in @players
                if(player.playerNumber!=playerToKan.playerNumber)
                  player.sendMessage("Player #{playerToKan.playerNumber} has completed their Kan.")
                else
                  player.sendMessage("You have completed your Kan.")
                  player.sendMessage("Your deadwall draw is #{drawnTile.getName(player.namedTiles)}.")
                player.sendMessage("The Dora Tiles are now: #{@wall.printDora(player.namedTiles)}")
              @turn = playerToKan.playerNumber
          )
          .catch(console.error)
      else
        playerToKan.sendMessage("You don't have correct tiles to Kan.")
    else
      playerToKan.sendMessage("Wrong time to Kan.")

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
                      player.sendMessage("Player #{playerToPon.playerNumber}'s Pon has completed.")
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
