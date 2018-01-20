describe 'determining hands-', ->
  describe 'thirteen orphans', ->
    allTerminalsAndHonors = "asdf"
    it 'should return thirteen orphans for any 14th honor tile', ->
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀄'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀅'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀆'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀀'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀁'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀂'))
      expect(hands).toEqual(["thirteenorphans"])
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀃'))
      expect(hands).toEqual(["thirteenorphans"])

    it 'should not return thirteen orphans for hands with a non terminal/honor tile', ->
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀚'))
      expect(hands).not.toEqual(jasmine.arrayContaining(["thirteenorphans"]))
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀕'))
      expect(hands).not.toEqual(jasmine.arrayContaining(["thirteenorphans"]))
      hands = getPossibleHands(allTerminalsAndHonors.concat('🀎'))
      expect(hands).not.toEqual(jasmine.arrayContaining(["thirteenorphans"]))

    it 'should return thirteen orphans even if the tiles are scrambled', ->
      hands = getPossibleHands(['🀄','🀅','🀆','🀀','🀁','🀂','🀃','🀙','🀡','🀐','🀘','🀇','🀏'])
      expect(hands).toEqual(jasmine.arrayContaining(["thirteenorphans"]))
      hands = getPossibleHands(['🀇','🀄','🀆','🀀','🀅','🀁','🀃','🀙','🀂','🀡','🀘','🀐','🀏'])
      expect(hands).toEqual(jasmine.arrayContaining(["thirteenorphans"]))
      hands = getPossibleHands(['🀄','🀀','🀡','🀅','🀁','🀙','🀂','🀘','🀐','🀏','🀆','🀇','🀃'])
      expect(hands).toEqual(jasmine.arrayContaining(["thirteenorphans"]))

  describe 'seven pairs', ->
    it 'should return seven pairs if it is the thing', ->
      hands = getPossibleHands(['🀄','🀄','🀆','🀆','🀁','🀁','🀃','🀃','🀡','🀡','🀘','🀘','🀏','🀏'])
      expect(hands).toEqual(["sevenpairs"])
