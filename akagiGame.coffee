gamePieces = require('./akagiTiles.coffee')
playerObject = require('./akagiPlayer.coffee')
score = require('./akagiScoring.coffee')
Promise = require('promise')
_ = require('lodash')

class messageSender
  #Way to make sending messages to both players and the observation channel easier.
  constuctor:(@playerOrObserver,whichType) ->
    if whichType == "player"
      @player = true
    else
      @player = false

  sendMessage:(text) ->
    if(@player)
      @playerOrObserver.sendMessage(text)
    else
      @playerOrObserver.send(text)

  namedTiles:->
    if(@player)
      return @playerOrObserver.namedTiles
    else
      return true

class MahjongGame
  #A four player game of Mahjong
  constructor: (playerChannels, server, gameSettings) ->
    @wall = new gamePieces.Wall()
    @counter = 0 #Put down when east winds a round, increasing point values.
    @riichiSticks = [] #Used to keep track when a player calls riichi
    @pendingRiichiPoints = false #Keeps track of who just called riichi, so that once we are sure the next round has started, then they can have their stick added to the pile.
    @oneRoundTracker = [[],[],[],[]] #Keeps track of all the special things that can give points if done within one go around
    @kuikae = [] #Keeps track of what tiles cannot be discarded after calling chi or pon.
    @lastDiscard = false #Keeps track of the last tile discarded this game.
    @winningPlayer = []
    @players = [
      new playerObject(playerChannels[1],1),
      new playerObject(playerChannels[2],2),
      new playerObject(playerChannels[3],3),
      new playerObject(playerChannels[4],4)
    ]
    @gameObservationChannel = playerChannels[0]
    @messageRecievers = []
    @messageRecievers.push(new messageSender(@gameObservationChannel,"observer"))
    for player in @players
      @messageRecievers.push(new messageSender(player,"player"))
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
    @kuikae = []
    @pendingRiichiPoints = false
    @lastDiscard = false
    for player in @players
      player.hand.startDraw(@wall)
      player.roundStart(@wall)
      player.sendMessage("Prevailing wind is #{@prevailingWind}.")
      player.sendMessage("Dora is #{@wall.printDora()}.")
      if(player.wind == "East")
        player.sendMessage("You are the first player.  Please discard a tile.")
    @oneRoundTracker = [["First Round"],["First Round"],["First Round"],["First Round"]]

  newRound: ->
    if @winningPlayer = [] || "East" in _.map(@winningPlayer,(x)->x.wind)
      @counter += 1
    else
      @counter = 0
    if("East" not in _.map(@winningPlayer,(x)->x.wind))
      for player in @players
        player.rotateWind()
      if @eastPlayer.wind == "East"
        if(@prevailingWind == "East")
          @prevailingWind = "South"
        else
          @endGame() #TODO Implement game end.
    @wall = new gamePieces.Wall()
    @winningPlayer = []
    for player in @players
      player.resetHand()
      if player.wind == "East"
        @dealer = player
    @startRound()


  #Sends out all the appropriate messages when the game ends
  endGame: ->
    winOrder = _.sortBy(@players, (x) -> -1*x.roundPoints)
    @phase = "GameOver"
    placements = {"First":[],"Second":[],"Third":[],"Fourth":[]}
    ranks = ["First","Second","Third","Fourth"]
    for player in winOrder
      for rank in ranks
        if(placements[rank].length == 0 || placements[rank][0].roundPoints == player.roundPoints)
          placements[rank].push(player)
          break

    for winner in placements["First"]
      winner.sendMessage("You win!")
      if(@riichiSticks.length > 0)
        winner.roundPoints += 1000*@riichiSticks.length/placements["First"].length
        winner.sendMessage("As the winner, you recieve the remaining riichi sticks and thus gain #{1000*@riichiSticks.length/placements["First"].length} points.")
    @riichiSticks = []
    for player in @messageRecievers
      player.sendMessage("The game has ended.")
      if(placements["First"].length == 1)
        player.sendMessage("First place was player #{placements["First"][0].playerNumber} with #{placements["First"][0].roundPoints} points.")
      else
        player.sendMessage("The following players tied for first with #{placements["First"][0].roundPoints}: #{_.map(placements["First"],(x)->x.playerNumber)}")
      if(placements["Second"].length == 1)
        player.sendMessage("Second place was player #{placements["Second"][0].playerNumber} with #{placements["Second"][0].roundPoints} points.")
      else if(placements["Second"].length > 1)
        player.sendMessage("The following players tied for second with #{placements["Second"][0].roundPoints}: #{_.map(placements["Second"],(x)->x.playerNumber)}")
      if(placements["Third"].length == 1)
        player.sendMessage("Third place was player #{placements["Third"][0].playerNumber} with #{placements["Third"][0].roundPoints} points.")
      else if(placements["Third"].length > 1)
        player.sendMessage("The following players tied for third with #{placements["Third"][0].roundPoints}: #{_.map(placements["Third"],(x)->x.playerNumber)}")
      if(placements["Fourth"].length == 1)
        player.sendMessage("Fourth place was player #{placements["Fourth"][0].playerNumber} with #{placements["Fourth"][0].roundPoints} points.")

    #Uma calculations
    umaPoints = [15000,5000,-5000,-15000]
    for rank in ranks
      accumulatedPoints = 0
      for x in placements[rank]
        accumulatedPoints += umaPoints.shift()
      for x in placements[rank]
        x.roundPoints += accumulatedPoints/placements[rank].length

    for player in @messageRecievers
      player.sendMessage("After factoring in uma, here are the final point values.")
      if(placements["First"].length == 1)
        player.sendMessage("First place was player #{placements["First"][0].playerNumber} with #{placements["First"][0].roundPoints} points.")
      else
        player.sendMessage("The following players tied for first with #{placements["First"][0].roundPoints}: #{_.map(placements["First"],(x)->x.playerNumber)}")
      if(placements["Second"].length == 1)
        player.sendMessage("Second place was player #{placements["Second"][0].playerNumber} with #{placements["Second"][0].roundPoints} points.")
      else if(placements["Second"].length > 1)
        player.sendMessage("The following players tied for second with #{placements["Second"][0].roundPoints}: #{_.map(placements["Second"],(x)->x.playerNumber)}")
      if(placements["Third"].length == 1)
        player.sendMessage("Third place was player #{placements["Third"][0].playerNumber} with #{placements["Third"][0].roundPoints} points.")
      else if(placements["Third"].length > 1)
        player.sendMessage("The following players tied for third with #{placements["Third"][0].roundPoints}: #{_.map(placements["Third"],(x)->x.playerNumber)}")
      if(placements["Fourth"].length == 1)
        player.sendMessage("Fourth place was player #{placements["Fourth"][0].playerNumber} with #{placements["Fourth"][0].roundPoints} points.")
      player.sendMessage("Congratulations to the winning player(s)!")
      if(player.player)
        player.sendMessage("Type 'end game' to remove all game channels, or 'play again' to start a new game with the same players.")

  #Called when the round ends with no winner.
  exaustiveDraw: ->
    @winningPlayer = _.filter(@players,(x)->scoreMahjongHand.tenpaiWith(x.hand) != [])
    for player in @players
      player.sendMessage("The round has ended in an exaustive draw.")
      if(@winningPlayer.length == 0)
        player.sendMessage("No players were in tenpai.")
      else
        player.sendMessage("The following players were in tenpai: #{x.playerNumber for x in @winningPlayer}")
        player.sendMessage("The tenpai hands looked like this: #{"#{x.playerNumber} - #{x.hand.printHand(player.tileNames)}" for x in @winningPlayer}")
        if(player.playerNumber in _.map(@winningPlayer,(x)->x.playerNumber))
          player.roundPoints += 3000/@winningPlayer.length
          player.sendMessage("Because you were in tenpai, you gain #{3000/@winningPlayer.length} points.")
        else
          player.roundPoints -= 3000/(4-@winningPlayer.length)
          player.sendMessage("Because you were not in tenpai, you pay #{3000/(4-@winningPlayer.length)} points.")
      player.sendMessage("The round is over.  To start the next round, type next.")
    @phase = "finished"

  #Put the stick into the pot, once the next turn has started. Also, adds discarded tile, to possible temporary furiten list.
  confirmNextTurn: ->
    if(@pendingRiichiPoints)
      @riichiSticks.push(@pendingRiichiPoints)
      for player in @players
        if player.playerNumber == @pendingRiichiPoints
          player.roundPoints -= 1000
      @pendingRiichiPoints = false
    for player in @players
      player.tilesSinceLastDraw.push(@lastDiscard)

  #Used to empty the round tracker if someone makes a call
  interuptRound: ->
    @oneRoundTracker = [[],[],[],[]]

  #Removes all one round counters for one player once it gets back to them, and removes list of temporary furiten tiles if they are not in riichi
  endGoAround:(playerTurn) ->
    @oneRoundTracker[playerTurn.playerNumber-1] = []
    if(!playerTurn.riichiCalled())
      playerTurn.tilesSinceLastDraw = []

  drawTile:(playerToDraw) ->
    if(@turn == playerToDraw.playerNumber)
      if(@phase != "draw")
        playerToDraw.sendMessage("It is not the draw phase.")
      else
        playerToDraw.wallDraw(@wall)
        @phase = "discard"
        @confirmNextTurn()
        if(playerToDraw.wantsHelp)
          tenpaiDiscards = score.tenpaiWithout(playerToDraw.hand)
          if(score.getPossibleHands(playerToDraw.hand).length > 0)
            playerToDraw.sendMessage("You have a completed hand.  You may call Tsumo if you have any yaku.")
          else if(tenpaiDiscards.length > 0)
            playerToDraw.sendMessage("You can be in tenpai by discarding any of the following tiles:")
            playerToDraw.sendMessage((tile.getName(playerToDraw.namedTiles) for tile in tenpaiDiscards))
        if(@wall.wallFinished)
          @oneRoundTracker[playerToDraw.playerNumber - 1].push("Haitei")
        for player in @players
          if player.playerNumber != playerToDraw.playerNumber
            player.sendMessage("Player #{playerToDraw.playerNumber} has drawn a tile.")
          if(@wall.wallFinished)
            player.sendMessage("This is the last draw of the game.  The game will end after the discard.")
    else
      playerToDraw.sendMessage("It is not your turn.")

  #checks whether someone is furiten or not
  furiten:(player) ->
    tenpai = score.tenpaiWith(player.hand)
    furitenBecause = []
    for tile in tenpai
      for discard in player.discardPile.contains
        if(tile.getTextName() == discard.getTextName())
          furitenBecause.push(tile)
      for discard in player.tilesSinceLastDraw
        if(tile.getTextName() == discard.getTextName())
          furitenBecause.push(tile)
    if(furitenBecause.length == 0)
      return false
    else
      return furitenBecause

  #checks and sets liability for 4 winds/3 dragon hands
  liabilityChecker:(playerCalling,playerLiable) ->
    if(_.filter(playerCalling.hand.calledMelds,(x)->x.suit() == "dragon").length == 3 || _.filter(playerCalling.hand.calledMelds,(x)->x.suit() == "wind").length == 4)
      playerCalling.liablePlayer = playerLiable.playerNumber

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

  ron:(playerToRon) ->
    if(@turn == playerToRon.nextPlayer && (@phase in ["draw","react"] || (@phase.isArray && @phase[0] not in ["concealedKaning","extendKaning","concealedRon","extendRon"])))
      playerToRon.sendMessage("Cannot Ron off of own discard.")
    else if(@turn == playerToRon.playerNumber && (@phase == "discard"||(@phase.isArray && @phase[0] in ["concealedKaning","extendKaning","concealedRon","extendRon"])))
      playerToRon.sendMessage("During your turn, use Tsumo, instead of Ron.")
    else if(@furiten(playerToRon))
      playerToRon.sendMessage("You may not Ron, because you are in furiten.")
    else if(@phase.isArray && @phase[0] in ["concealedKaning","concealedRon"] && !score.thirteenOrphans(playerToRon.hand,@phase[1]))
      playerToRon.sendMessage("You may only call Ron off of a concealed Kan, if you are winning via the thirteen orphans hand.")
    else if(@phase.isArray && @phase[0] in ["concealedRon","extendRon","roning"] && playerToRon.playerNumber in @phase[2])
      playerToRon.sendMessage("You have already declared Ron.")
    else
      if(@phase.isArray && @phase[0] in ["concealedKaning","concealedRon","extendKaning","extendRon"])
        discarder = _.find(@players,(x)=> @turn == x.playerNumber)
        discardedTile = @phase[1]
      else
        discarder = _.find(@players,(x)=> @turn == x.nextPlayer)
        discardedTile = discarder.discardPile.contains[-1..][0]
      testHand = _.cloneDeep(playerToRon.hand)
      testHand.contains.push(discardedTile)
      testHand.lastTileDrawn = discardedTile
      testHand.draw(null,0)
      testHand.lastTileFrom = discarder.playerNumber
      scoreMax = score.scoreMahjongHand(testHand,@winFlagCalculator(playerToRon,"Ron"),[@wall.dora,@wall.urDora])
      if(scoreMax[0] == 0)
        playerToRon.sendMessage(scoreMax[1])
      else
        playerToRon.hand = testHand
        for player in @players
          if(player.playerNumber == playerToRon.playerNumber)
            player.sendMessage("You have declared Ron.")
          else
            player.sendMessage("Player #{playerToRon.playerNumber} has declared Ron.")
        if(@phase.isArray)
          if(@phase[0] in ["concealedKaning","concealedRon"])
            state = "concealedRon"
          else if(@phase[0] in ["extendKaning","extendRon"])
            state = "extendRon"
          else
            state = "roning"
          #Figure out who all has declared ron thus far.
          if(@phase[0] in ["concealedRon","extendRon","roning"])
            ronGroup = @phase[2].concat(playerToRon.playerNumber)
          else
            ronGroup = [playerToRon.playerNumber]
        else
          state = "roning"
          ronGroup = [playerToRon.playerNumber]
        @phase = [state,discardedTile,ronGroup]
        ronAfterTen = new Promise((resolve,reject) =>
          setTimeout(->
            resolve("Time has Passed")
          ,1000))
        ronAfterTen
        .then((message)=>
          if(_.isEqual(@phase,[state,discardedTile,ronGroup]))
            riichiBet = @riichiSticks.length
            winnerOrder = []
            winnerOrder.push(_.find(@players,(x)->discarder.nextPlayer == x.playerNumber)
            winnerOrder.push(_.find(@players,(x)->winnerOrder[0].nextPlayer==x.playerNumber))
            winnerOrder.push(_.find(@players,(x)->winnerOrder[1].nextPlayer==x.playerNumber))
            winnerOrder = _.filter(winnerOrder,(x)->x.playerNumber in @phase[2]))
            for winner in winnerOrder
              if(winner.riichiCalled())
                winner.roundPoints+=1000
                winner.sendMessage("Riichi bet returned to you.")
                riichiBet -= 1
            if(riichiBet>0)
              winnerOrder[0].roundPoints+=1000*riichiBet
              winner.sendMessage("Remaining riichi bets give you #{1000*riichiBet} points.")
            @riichiSticks = []
            for winner in winnerOrder
              scoreMax = score.scoreMahjongHand(winner.hand,@winFlagCalculator(playerToRon,"Ron"),[@wall.dora,@wall.urDora])
              if(playerToRon.wind == "East")
                pointsGained = _roundUpToClosestHundred(6*scoreMax[0])+@counter*300
                pointsLost = _roundUpToClosestHundred(6*scoreMax[0])
              else
                pointsGained = _roundUpToClosestHundred(4*scoreMax[0])+@counter*300
                pointsLost = _roundUpToClosestHundred(4*scoreMax[0])
              for player in @players
                if(player.playerNumber == winner.playerNumber)
                  player.roundPoints += pointsGained
                  player.sendMessage("You have won from Ron.")
                  player.sendMessage("You receive #{pointsGained} points.")
                else
                  player.sendMessage("Player #{winner.playerNumber} has won via Ron.")
                  if(winner.liablePlayer && winner.liablePlayer != discarder.playerNumber)
                    pointsLost = pointsLost/2
                    if(player.playerNumber == winner.liablePlayer)
                      player.roundPoints -= pointsLost
                      player.sendMessage("Because you were liable for this hand, you pay #{pointsLost} points.")
                  if(discarder.playerNumber == player.playerNumber)
                    player.roundPoints -= pointsLost+300*@counter
                    player.sendMessage("Because you discarded the winning tile, you pay #{pointsLost+300*@counter} points.")
                player.sendMessage("The winning hand contained the following yaku: #{scoreMax[1]}")
                player.sendMessage("The winning hand was: #{winner.hand.printHand(player.namedTiles)}")
                player.sendMessage("The dora indicators were: #{@wall.printDora(player.namedTiles)}")
                if(playerToTsumo.riichiCalled)
                  player.sendMessage("The ur dora indicators were: #{@wall.printUrDora(player.namedTiles)}")
            for player in @players
              player.sendMessage("The round is over.  To start the next round, type next.")
            @winningPlayer = winnerOrder
            @phase = "finished"
        )
        .catch(console.error)




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
            if(playerToTsumo.liablePlayer)
              if player.playerNumber = playerToTsumo.liablePlayer
                pointsLost = _roundUpToClosestHundred(6*scoreMax[0])+@counter*100
              else if player.playerNumber == playerToTsumo.playerNumber
                pointsGained = _roundUpToClosestHundred(6*scoreMax[0])+@counter*100+@riichiSticks.length*1000
              else
                pointsLost = 0
            else
              if player.playerNumber != @turn
                pointsLost = _roundUpToClosestHundred(2*scoreMax[0])+@counter*100
              else
                pointsGained = 3*_roundUpToClosestHundred(2*scoreMax[0])+@counter*300+@riichiSticks.length*1000
          else
            if(playerToTsumo.liablePlayer)
              if player.playerNumber = playerToTsumo.liablePlayer
                pointsLost = _roundUpToClosestHundred(4*scoreMax[0])+@counter*100
              else if player.playerNumber == playerToTsumo.playerNumber
                pointsGained = _roundUpToClosestHundred(4*scoreMax[0])+@counter*100+@riichiSticks.length*1000
              else
                pointsLost = 0
            else
              if player.wind == "East"
                pointsLost = _roundUpToClosestHundred(2*scoreMax[0])+@counter*100
              else if player.playerNumber != @turn
                pointsLost = _roundUpToClosestHundred(scoreMax[0])+@counter*100
              else
                pointsGained = _roundUpToClosestHundred(2*scoreMax[0])+2*_roundUpToClosestHundred(scoreMax[0])+@counter*300+@riichiSticks.length*1000
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
          player.sendMessage("The winning hand was: #{winner.hand.printHand(player.namedTiles)}")
          player.sendMessage("The dora indicators were: #{@wall.printDora(player.namedTiles)}")
          if(playerToTsumo.riichiCalled)
            player.sendMessage("The ur dora indicators were: #{@wall.printUrDora(player.namedTiles)}")
          player.sendMessage("The round is over.  To start the next round, type next.")
        @winningPlayer = [playerToTsumo]
        @phase = "finished"


  chiTile:(playerToChi, tile1, tile2) ->
    if(playerToChi.playerNumber != @turn)
      playerToChi.sendMessage("May only Chi when you are next in turn order.")
    else if(playerToChi.riichiCalled())
      playerToChi.sendMessage("May not Chi after declaring Riichi.")
    else if(@wall.wallFinished)
      playerToChi.sendMessage("May not call Chi on the last turn.")
    else if(@phase in ["draw","react"])
      if(_.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile1, x)) != -1 && _.findIndex(playerToChi.hand.uncalled(),(x) -> _.isEqual(tile2, x)) != -1)
        discarder = _.find(@players,(x)=> @turn == x.nextPlayer)
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
                @kuikae.push(toChi)
                if(tile1.value > toChi.value && tile2.value > toChi.value)
                  @kuikae.push(new gamePieces.Tile(toChi.suit,toChi.value+3))
                else if(tile1.value < toChi.value && tile2.value < toChi.value)
                  @kuikae.push(new gamePieces.Tile(toChi.suit,toChi.value-3))
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
    else if(@phase.isArray)
      playerToChi.sendMessage("Chi has lower priority than Pon, Kan, and Ron.")
    else
      playerToChi.sendMessage("Wrong time to Chi")

  #Finds out if the tiles in a concealed pung
  onlyPung:(hand,tile) ->
    withoutDraw = _.cloneDeep(hand)
    withoutDraw.discard(tile.getTextName())
    waits = score.tenpaiWith(withoutDraw)
    for win in waits
      testHand = _.cloneDeep(withoutDraw)
      testHand.lastTileDrawn = win
      testHand.contains.push(win)
      melds = score.getPossibleHands(testHand)
      for meld in melds
        if(meld.type == "Chow" && meld.containsTile(tile))
          return false
    return true


  selfKanTiles:(playerToKan,tileToKan) ->
    uncalledKanTiles = _.filter(playerToKan.hand.uncalled(),(x) -> _.isEqual(x,tileToKan)).length
    if(@turn != playerToKan.playerNumber)
      playerToKan.sendMessage("It is not your turn.")
    else if(@phase != "discard")
      playerToKan.sendMessage("One can only self Kan during one's own turn after one has drawn.")
    else if(@wall.dora.length == 5)
      playerToKan.sendMessage("There can only be 4 Kans per game.")
    else if(@wall.wallFinished)
      playerToKan.sendMessage("May not call Kan on the last turn.")
    else if(uncalledKanTiles < 1)
      playerToKan.sendMessage("No tiles to Kan with.")
    else if(uncalledKanTiles in [2,3])
      playerToKan.sendMessage("Wrong number of tiles to Kan with.")
    else if(uncalledKanTiles == 4 && playerToKan.riichiCalled() && !@onlyPung(playerToKan.hand,tileToKan))
      playerToKan.sendMessage("You can't call Kan with this tile, because it changes the structure of the hand.")
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
    else if(@wall.dora.length == 5)
      playerToKan.sendMessage("There can only be 4 Kans per game.")
    else if(@wall.wallFinished)
      playerToKan.sendMessage("May not call Kan on the last turn.")
    else if(@phase.isArray && @phase[0] == "chiing" && playerToPon.playerNumber == @phase[1])
      playerToKan.sendMessage("One cannot Kan if one has already declared Chi.")
    else if((@phase.isArray && @phase[0] == "chiing") || @phase in ["react","draw"])
      discarder = _.find(@players,(x)=> @turn == x.nextPlayer)
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
              if(toKan.isHonor())
                @liabilityChecker(playerToKan,discarder)
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
    else if(@phase.isArray && @phase[0] == "Chi" && @phase[1] == playerToPon.playerNumber)
      playerToPon.sendMessage("Can't call Pon if you already called Chi.")
    else if((@phase in ["react","draw"] || (@phase.isArray && @phase[0] == "chiing")) && @turn != playerToPon.nextPlayer)
      discarder = _.find(@players,(x)=> @turn == x.nextPlayer)
      toPon = discarder.discardPile.contains[-1..][0]
      if(_.findIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x))!=_.findLastIndex(playerToPon.hand.uncalled(),(x)->_.isEqual(toPon,x)))
        @phase = ["poning",playerToPon.playerNumber]
        for player in @players
          if(player.playerNumber != playerToPon.playerNumber)
            player.sendMessage("Player #{playerToPon.playerNumber} has declared Pon.")
          else
            player.sendMessage("You have declared Pon.")
        tenSecondsToPon = new Promise((resolve,reject) =>
          setTimeout(->
            resolve("Time has Passed")
          ,1000))
        tenSecondsToPon
          .then((message)=>
            if(_.isEqual(@phase,["poning",playerToPon.playerNumber]))
              @phase = "discard"
              @confirmNextTurn()
              @interuptRound()
              @kuikae.push(toPon)
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
              if(toPon.isHonor())
                @liabilityChecker(playerToPon,discarder)
          )
          .catch(console.error)
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
      else if(riichi && playerToDiscard.hand.isConcealed() == false)
        playerToDiscard.sendMessage("You may only riichi with a concealed hand.")
      else if(playerToDiscard.riichiCalled() && tileToDiscard != playerToDiscard.hand.lastTileDrawn.getTextName())
        playerToDiscard.sendMessage("Once you have declared Riichi, you must always discard the drawn tile.")
      else if(riichi && @wall.leftInWall() < 4)
        playerToDiscard.sendMessage("You can't call riichi if there are less than four tiles remaining in the wall.")
      else if(riichi && !_.some(score.tenpaiWithout(playerToDiscard.hand),(x)->x.getTextName()==tileToDiscard))
        playerToDiscard.sendMessage("You would not be in tenpai if you discarded that tile to call Riichi.")
      else if(_.some(@kuikae,(x)->x.getTextName()==tileToDiscard))
        playerToDiscard.sendMessage("May not discard the same tile just called, or the opposite end of the chow just called.")
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
          @lastDiscard = discarded
          @endGoAround(playerToDiscard)
          @gameObservationChannel.send("Player #{playerToDiscard.playerNumber} #{outtext} a #{discarded.getName()}.")
          for player in @players
            if(player.playerNumber != playerToDiscard.playerNumber)
              player.sendMessage("Player #{playerToDiscard.playerNumber}  #{outtext} a #{discarded.getName(player.namedTiles)}.")
            else
              player.sendMessage("You  #{outtext} a #{discarded.getName(player.namedTiles)}.")
          @turn = playerToDiscard.nextPlayer
          @phase = "react"
          @kuikae = []
          for player in @players
            if(player.wantsHelp)
              calls = player.hand.whichCalls(@lastDiscard)
              if(calls.length > 0)
                player.sendMessage("You may call #{calls} on this tile.")
              if(_.some(score.tenpaiWith(player.hand),(x)->_.isEqual(x,discarded)))
                player.sendMessage("You may Ron off of this discard, as long as you are not furiten.")
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
