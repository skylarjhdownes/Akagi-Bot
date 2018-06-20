gamePieces = require('./akagiTiles.coffee')
playerObject = require('./akagiPlayer.coffee')
score = require('./akagiScoring.coffee')
Promise = require('promise')
_ = require('lodash')

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerChannels, server, gameSettings) ->
    @wall = new gamePieces.Wall()
    @counter = 0 #Put down when east winds a round, increasing point values.
    @riichiSticks = [] #Used to keep track when a player calls riichi
    @pendingRiichiPoints = false #Keeps track of who just called riichi, so that once we are sure the next round has started, then they can have their stick added to the pile.
    @oneRoundTracker = [[],[],[],[]] #Keeps track of all the special things that can give points if done within one go around
    @winningPlayer = false
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

    @prevailingWind = "East"
    @dealer = @eastPlayer
    @startRound()

  startRound: ->
    @turn = @dealer.playerNumber
    @phase = 'discard'
    @wall.doraFlip()
    for player in @players
      player.hand.startDraw(@wall)
      player.roundStart(@wall)
      player.sendMessage("Prevailing wind is #{@prevailingWind}.")
      player.sendMessage("Dora is #{@wall.printDora()}.")
      if(player.wind == "East")
        player.sendMessage("You are the first player.  Please discard a tile.")
    @oneRoundTracker = [["First Round"],["First Round"],["First Round"],["First Round"]]

  newRound: ->
    if !@winningPlayer || @winningPlayer.wind == "East"
      @counter += 1
    else
      @counter = 0
      for player in @players
        player.rotateWind()
      if @eastPlayer.wind == "East"
        if(@prevailingWind == "East")
          @prevailingWind = "South"
        else
          @endGame() #TODO Implement game end.
    @wall = new gamePieces.Wall()
    @winningPlayer = false
    for player in @players
      player.resetHand()
      if player.wind == "East"
        @dealer = player
    @startRound()

  #Called when the round ends with no winner.
  @exaustiveDraw: ->
    return true #TODO Implement exaustive draw.

  #Put the stick into the pot, once the next turn has started.
  confirmNextTurn: ->
    if(@pendingRiichiPoints)
      @riichiSticks.append(@pendingRiichiPoints)
      for player in @players
        if player.playerNumber == @pendingRiichiPoints
          player.roundPoints -= 1000
      @pendingRiichiPoints = false

  #Used to empty the round tracker if someone makes a call
  interuptRound: ->
    @oneRoundTracker = [[],[],[],[]]

  #Removes all one round counters for one player once it gets back to them.
  endGoAround:(playerTurn) ->
    @oneRoundTracker[playerTurn.playerNumber-1] = []

  drawTile:(playerToDraw) ->
    if(@turn == playerToDraw.playerNumber)
      if(@phase != "draw")
        playerToDraw.sendMessage("It is not the draw phase.")
      else
        playerToDraw.wallDraw(@wall)
        @phase = "discard"
        @confirmNextTurn()
        if(@wall.wallFinished)
          @oneRoundTracker[playerToDraw.playerNumber - 1].push("Haitei")
        for player in @players
          if player.playerNumber != playerToDraw.playerNumber
            player.sendMessage("Player #{playerToDraw.playerNumber} has drawn a tile.")
          if(@wall.wallFinished)
            player.sendMessage("This is the last draw of the game.  The game will end after the discard.")
    else
      playerToDraw.sendMessage("It is not your turn.")

  #Calculates all the flags for non hand based points in the game.
  winFlagCalculator:(winningPlayer,winType) ->
    flags = []
    if(winningPlayer.riichiCalled())
      flags.push("Riichi")
      if(winningPlayer.daburu)
        flags.push("Daburu Riichi")
      if("Ippatsu" in @oneRoundTracker[winningPlayer.playerNumber - 1])
        flags.push("Ippatsu")
    if("First Round" in @oneRoundTracker[winningPlayer.playerNumber-1])
      if(winType == "Ron")
        flags.push("Renho")
      else
        if(winningPlayer.playerNumber == @dealer.playerNumber)
          flags.push("Tenho")
        else
          flags.push("Chiho")
    if("Rinshan Kaihou" in @oneRoundTracker[winningPlayer.playerNumber-1])
      flags.push("Rinshan Kaihou")
    if(winType == "Ron")
      if(@phase.isArray && @phase[0] == "extendKaning")
        flags.push("Chan Kan")
      if(@wall.wallFinished)
        flags.push("Houtei")
    if("Haitei" in @oneRoundTracker[winningPlayer.playerNumber-1])
      flags.push("Haitei")
    return new score.gameFlags(winningPlayer.wind,@prevailingWind,flags)

  tsumo:(playerToTsumo) ->
    if(@turn!=playerToTsumo.playerNumber)
      playerToTsumo.sendMessage("Not your turn.")
    else if(@phase!="discard")
      playerToTsumo.sendMessage("You don't have enough tiles.")
    else
      scoreMax = score.scoreMahjongHand(playerToTsumo.hand, @winFlagCalculator(playerToTsumo,"Tsumo"), [@wall.dora,@wall.urDora])
      if(scoreMax[0] == 0)
        playerToTsumo.sendMessage(scoreMax[1])
      else
        for player in @players
          #CalculatePoints
          if(playerToTsumo.wind == "East")
            if player.playerNumber != @turn
              pointsLost = _roundUpToClosestHundred(2*scoreMax[0])+@counter*100
            else
              pointsGained = _roundUpToClosestHundred(6*scoreMax[0])+@counter*300+@riichiSticks.length*1000
          else
            if player.wind == "East"
              pointsLost = _roundUpToClosestHundred(2*scoreMax[0])+@counter*100
            else if player.playerNumber != @turn
              pointsLost = _roundUpToClosestHundred(scoreMax[0])+@counter*100
            else
              pointsGained = _roundUpToClosestHundred(4*scoreMax[0])+@counter*300+@riichiSticks.length*1000
          @riichiSticks = []
          #Say points
          if(player.playerNumber != @turn)
            player.roundPoints -= pointsLost
            player.sendMessage("Player #{playerToTsumo.playerNumber} has won from self draw.")
            player.sendMessage("You pay out #{pointsLost} points.")
          else
            player.roundPoints += pointsGained
            player.sendMessage("You have won on self draw.")
            player.sendMessage("You receive #{pointsGained} points.")
          player.sendMessage("The winning hand contained the following yaku: #{scoreMax[1]}")
          player.sendMessage("The dora were: #{@wall.printDora(player.namedTiles)}")
          if(playerToTsumo.riichiCalled)
            player.sendMessage("The ur dora were: #{@wall.printUrDora(player.namedTiles)}")
          player.sendMessage("The round is over.  To start the next round, type next.")
        @winningPlayer = playerToTsumo
        @phase = "finished"


  chiTile:(playerToChi, tile1, tile2) ->
    if(@phase == "draw")
      if(playerToChi.playerNumber == @turn)
        if(playerToChi.riichiCalled())
          playerToChi.sendMessage("May not Chi after declaring Riichi.")
        else if(@wall.wallFinished)
          playerToChi.sendMessage("May not call Chi on the last turn.")
        else if(_.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile1, x)) != -1 && _.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile2, x)) != -1)
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
                      @confirmNextTurn()
                      @interuptRound()
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
    else if(@wall.wallFinished)
      playerToKan.sendMessage("May not call Kan on the last turn.")
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
              @interuptRound()
              @oneRoundTracker[@playerToKan.playerNumber-1].push("Rinshan Kaihou")
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
                @interuptRound()
                @oneRoundTracker[@playerToKan.playerNumber-1].push("Rinshan Kaihou")
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
    if(playerToKan.riichiCalled())
      playerToKan.sendMessage("You can't call tiles, except to win, after declaring Riichi.")
    else if(@phase.isArray && @phase[0] == "roning")
      playerToKan.sendMessage("Kan has lower priority than Ron.")
    else if(@wall.wallFinished)
      playerToKan.sendMessage("May not call Kan on the last turn.")
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
              @confirmNextTurn()
              @interuptRound()
              @oneRoundTracker[@playerToKan.playerNumber-1].push("Rinshan Kaihou")
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
    if(playerToPon.riichiCalled())
      playerToPon.sendMessage("You may not Pon after declaring Riichi.")
    else if(@wall.wallFinished)
      playerToPon.sendMessage("May not call Pon on the last turn.")
    else if(@phase in ["react","draw"] && @turn != playerToPon.nextPlayer)
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
                  @confirmNextTurn()
                  @interuptRound()
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
                    @confirmNextTurn()
                    @interuptRound()
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


  discardTile:(playerToDiscard,tileToDiscard,riichi = false) ->
    if(@turn == playerToDiscard.playerNumber)
      if(@phase != "discard")
        playerToDiscard.sendMessage("It is not the discard phase.")
      else if(riichi && playerToDiscard.hand.concealed() == false)
        playerToDiscard.sendMessage("You may only riichi with a concealed hand.")
      else if(playerToDiscard.riichiCalled() && tileToDiscard != playerToDiscard.hand.lastTileDrawn.getTextName())
        playerToDiscard.sendMessage("Once you have declared Riichi, you must always discard the drawn tile.")
      else
        discarded = playerToDiscard.discardTile(tileToDiscard)
        if(discarded)
          if(riichi)
            if("First Round" in @oneRoundTracker[playerToDiscard.playerNumber-1])
              playerToDiscard.daburu = true
              outtext = "declared daburu riichi with"
            else
              outtext = "declared riichi with"
            playerToDiscard.discardPile.declareRiichi()
            @pendingRiichiPoints = playerToDiscard.playerNumber
            @oneRoundTracker[@playerToDiscard.playerNumber-1].push("Ippatsu")
          else
            outtext = "discarded"
          @endGoAround(playerDiscard)
          @gameObservationChannel.send("Player #{playerToDiscard.playerNumber} #{outtext} a #{discarded.getName()}.")
          for player in @players
            if(player.playerNumber != playerToDiscard.playerNumber)
              player.sendMessage("Player #{playerToDiscard.playerNumber}  #{outtext} a #{discarded.getName(player.namedTiles)}.")
            else
              player.sendMessage("You  #{outtext} a #{discarded.getName(player.namedTiles)}.")
          @turn = playerToDiscard.nextPlayer
          @phase = "react"
          nextTurnAfterTen = new Promise((resolve, reject) =>
            setTimeout(->
              resolve("Time has Passed")
            ,1000))
          nextTurnAfterTen
            .then((message)=>
              if(@phase == "react")
                if(!@wall.wallFinished)
                  @phase = "draw"
                  for player in @players
                    if(@turn == player.playerNumber)
                      player.sendMessage("It is your turn.  You may draw a tile.")
              else
                @exaustiveDraw()
            )
            .catch(console.error)
        else
          playerToDiscard.sendMessage("You don't have that tile.")
    else
      playerToDiscard.sendMessage("It is not your turn.")

  _roundUpToClosestHundred = (inScore) ->
    if (inScore%100)!=0
      return (inScore//100+1)*100
    else
      inScore

module.exports = MahjongGame
