CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
{ Promise } = __.require 'lib', 'promises'
{ customAuthReq } = require '../utils/request'
{ createEdition } = require './entities'
randomString = __.require 'lib', './utils/random_string'

editionsUrisPromise =
  en: createEdition({ lang: 'en' }).get 'uri'
  de: createEdition({ lang: 'de' }).get 'uri'

count = 0
getEditionUri = ->
  # Get 4/5 'en' editions, 1/5 'de' editions
  lang = if count % 4 is 0 then 'de' else 'en'
  count += 1
  return editionsUrisPromise[lang]

listings = [ 'private', 'network', 'public' ]
transactions = [ 'giving', 'lending', 'selling', 'inventorying' ]

module.exports = API =
  createItems: (userPromise, itemsData = {})->
    { entity } = itemsData[0]
    entityUriPromise = if entity then Promise.resolve(entity) else getEditionUri()

    entityUriPromise
    .then (entityUri)->
      items = itemsData.map addDefaultEntity(entityUri)
      customAuthReq userPromise, 'post', '/api/items', items

  createItem: (userPromise, itemData = {})->
    API.createItems userPromise, [ itemData ]
    .get '0'

  createRandomizedItems: (userPromise, itemsData)->
    return API.createItems userPromise, itemsData.map(randomizedItem)

randomizedItem = (itemData)->
  { entity, listing, transaction } = itemData
  itemData.listing or= _.sample(listings)
  itemData.transaction or= _.sample(transactions)
  itemData.details = randomString 10
  itemData.notes = randomString 10
  return itemData

addDefaultEntity = (entityUri)-> (item)->
  item.entity or= entityUri
  return item
