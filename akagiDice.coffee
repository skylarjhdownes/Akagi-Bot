#gets a random number between 1 and n
rollDN = (n) ->
  1 + Math.floor(Math.random()*n)

#gets m random numbers between 1 and n
rollMDN = (m,n) ->
  m = parseInt(m,10)
  n = parseInt(n,10)
  values = for x in [1..m]
    rollDN(n)

#adds all the numbers in a list together
sum = (inList) ->
  out = 0
  for x in inList
    out+=x
  return out

#parses an input string into seperate chunks
rollParse = (inputString) ->
  start = 0
  chunks = []
  for x,i in inputString
    if(x == '+')
      if(i>0)
        chunks.push(inputString[start..i-1])
      start = i+1
      chunks.push('+')
    else if(x == '-')
      if(i>0)
        chunks.push(inputString[start..i-1])
      start = i+1
      chunks.push('-')
  chunks.push(inputString[start..])
  return chunks

#interprets a chunk from parsed output
interpretChunk = (chunk) ->
  d = chunk.indexOf('d')
  if(d>=0)
    return rollMDN(chunk[0...d],chunk[d+1..])
  else
    return parseInt(chunk,10)

#takes rollParses output and gets all the rolls
getRolls = (chunks) ->
  added = []
  subbed = []
  areAdding = true
  for x in chunks
    if(x == '+')
      areAdding = true
    else if(x == '-')
      areAdding = false
    else
      out = interpretChunk(x)
      if(areAdding)
        added.push(out)
      else
        subbed.push(out)
  return [added, subbed]

#prints output in an aesthetic way
prettyPrintRolls = (rolls) ->
  output = "Roll: "
  addedPart = ""
  addSum = 0
  subbedPart = ""
  subSum = 0
  for x,i in rolls[0]
    if(i isnt 0)
      addedPart+=" + "
    if(x.length == undefined)
      addedPart+=x
      addSum+=x
    else
      localSum = sum(x)
      addedPart+=localSum
      addedPart+="("+x[0]
      for y in x[1..]
        addedPart+=", "+y
      addedPart+=")"
      addSum+=localSum
  for x,i in rolls[1]
    subbedPart+=" - "
    if(x.length == undefined)
      subbedPart+=x
      subSum+=x
    else
      localSum = sum(x)
      subbedPart+=localSum
      subbedPart+="("+x[0]
      for y in x[1..]
        subbedPart+=", "+y
      subbedPart+=")"
      subSum+=localSum
  total = addSum-subSum
  output+=total+" = "+addedPart+subbedPart
  return output

rollDice = (textInput) ->
  prettyPrintRolls(getRolls(rollParse(textInput)))

module.exports.rollDice = rollDice
