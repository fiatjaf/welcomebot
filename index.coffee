settings   = require './settings'

Promise    = require 'bluebird'
NodeTrello = require 'node-trello'
express    = require 'express'
bodyParser = require 'body-parser'

trello = Promise.promisifyAll new NodeTrello settings.TRELLO_API_KEY, settings.TRELLO_BOT_TOKEN

app = express()
app.use '/static', express.static('static')
app.use bodyParser.json()

sendOk = (request, response) ->
  console.log 'trello checks this endpoint when creating a webhook'
  response.send 'ok'
app.get  '/webhooks/bot',  sendOk
app.get  '/webhooks/card', sendOk

app.post '/webhooks/bot', (request, response) ->
  payload = request.body

  console.log '- bot: ' + payload.action.type
  response.send 'ok'

  switch payload.action.type
    when 'addMemberToCard'
      # add webhook to this board
      trello.putAsync('/1/webhooks',
        callbackURL: settings.API_ROOT + '/webhooks/card'
        idModel: payload.action.data.card.id
        description: 'welcomebot webhook for this card.'
      ).then((data) ->
        console.log 'added to board', payload.action.data.board.name, 'webhook created'
      ).catch(console.log.bind console)

    when 'removeMemberFromCard'
      Promise.resolve().then(->
        trello.getAsync '/1/token/' + settings.TRELLO_BOT_TOKEN + '/webhooks'
      ).then((webhooks) ->
        for webhook in webhooks
          if webhook.idModel == payload.action.data.card.id
            trello.delAsync '/1/webhooks/' + webhook.id
      ).spread(->
        console.log 'webhook deleted'
      ).catch(console.log.bind console)

app.post '/webhooks/card', (request, response) ->
  payload = request.body
  action = payload.action
  data = action.data

  console.log 'card ' + payload.model.shortUrl + ': ' + payload.action.type
  console.log JSON.stringify payload.action, null, 2
  response.send 'ok'

  if action.memberCreator.id == settings.TRELLO_BOT_ID
    return

  if action.type not in [
    "commentCard"
  ]
    return

  Promise.resolve().then(->
    trello.putAsync "/1/boards/#{data.board.id}/members/#{action.memberCreator.id}"
      , type: 'normal'
  ).then(->
    console.log "#{action.memberCreator.id} added to board #{data.board.id}."
  ).catch(console.log.bind console)

port = process.env.PORT or 5000
app.listen port, '0.0.0.0', ->
  console.log 'running at 0.0.0.0:' + port
