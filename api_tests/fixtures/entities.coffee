CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
{ authReq } = require '../utils/utils'
randomString = __.require 'lib', './utils/random_string'
isbn_ = __.require 'lib', 'isbn/isbn'

defaultEditionData = ->
  labels: {}
  claims:
    'wdt:P31': [ 'wd:Q3331189' ]
    'wdt:P1476': [ randomString(4) ]

module.exports = API =
  createEntity: (label)->
    authReq 'post', '/api/entities?action=create',
      labels: { fr: label }
      claims: { 'wdt:P31': [ 'wd:Q571' ] }

  createHuman: (label=randomString(6))->
    authReq 'post', '/api/entities?action=create',
      labels: { en: label }
      claims: { 'wdt:P31': [ 'wd:Q5' ] }

  createWork: ->
    authReq 'post', '/api/entities?action=create',
      labels: { en: randomString(6) }
      claims: { 'wdt:P31': [ 'wd:Q571' ] }

  createSerie: ->
    authReq 'post', '/api/entities?action=create',
      labels: { en: randomString(6) }
      claims: { 'wdt:P31': [ 'wd:Q277759' ] }

  createWorkWithAuthor: (human)->
    humanPromise = if human then Promise.resolve(human) else API.createHuman()

    humanPromise
    .then (human)->
      authReq 'post', '/api/entities?action=create',
        labels: { en: randomString(6) }
        claims:
          'wdt:P31': [ 'wd:Q571' ]
          'wdt:P50': [ human.uri ]

  createEdition: ->
    API.createWork()
    .then (work)->
      authReq 'post', '/api/entities?action=create',
        claims:
          'wdt:P31': [ 'wd:Q3331189' ]
          'wdt:P629': [ work.uri ]
          'wdt:P1476': [ work.labels.en ]

  createItemFromEntityUri: (uri, data={})->
    authReq 'post', '/api/items', _.extend({}, data, { entity: uri })

  addClaim: (uri, property, value)->
    authReq 'put', '/api/entities?action=update-claim',
      uri: uri
      property: property
      'new-value': value

  ensureEditionExists: (uri, workData, editionData)->
    authReq 'get', "/api/entities?action=by-uris&uris=#{uri}"
    .get 'entities'
    .then (entities)->
      if entities[uri]? then return entities[uri]
      workData or= {
        labels: { fr: 'bla' }
        claims: { 'wdt:P31': [ 'wd:Q571' ] }
      }
      authReq 'post', '/api/entities?action=create',
        labels: { de: 'Mr moin moin'}
        claims: { 'wdt:P31': [ 'wd:Q5' ] }
      .then (authorEntity)->
        workData.claims['wdt:P50'] = [ authorEntity.uri ]
        authReq 'post', '/api/entities?action=create', workData
      .then (workEntity)->
        editionData or= defaultEditionData()
        [ prefix, id ] = uri.split ':'
        if isbn_.isValidIsbn id
          editionData.claims['wdt:P212'] = [ isbn_.toIsbn13h(id) ]
        editionData.claims['wdt:P629'] = [ workEntity.uri ]
        authReq 'post', '/api/entities?action=create', editionData
