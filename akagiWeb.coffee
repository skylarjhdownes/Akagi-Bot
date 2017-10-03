Express = require('express')

## For running a website as well
website = Express()
website.use(Express.static('public'))
website.get('/', (req, res) ->
  console.log(__dirname)
  res.sendFile('Public/index.html', {root: __dirname})
  )
website.listen(process.env.PORT || 9000)
