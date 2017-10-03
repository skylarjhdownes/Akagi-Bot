Express = require('express')

## For running a website as well
website = Express()
website.use(Express.static('publicWeb'))
website.get('/', (req, res) ->
  console.log(__dirname)
  res.sendFile('publicWeb/index.html', {root: __dirname})
  )
website.listen(process.env.PORT || 9000)
