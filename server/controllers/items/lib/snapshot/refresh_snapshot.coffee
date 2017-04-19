__ = require('config').universalPath
_ = __.require 'builders', 'utils'
entities_ = __.require 'controllers','entities/lib/entities'
getEntityByUri = __.require 'controllers', 'entities/lib/get_entity_by_uri'
getInvEntityCanonicalUri = __.require 'controllers', 'entities/lib/get_inv_entity_canonical_uri'
buildSnapshot = require './build_snapshot'
{ getWorkAuthorsAndSeries, getEditionGraphEntities } = require './get_entities'
{ getDocData, addSnapshot } = require './helpers'
items_ = require '../items'
user_ = __.require 'controllers', 'user/lib/user'

fromDoc = (changedEntityDoc)->
  [ uri, type ] = getDocData changedEntityDoc
  unless type in refreshTypes then return

  refresh[type](uri)
  .then (updatedItems)->
    _.log updatedItems, 'items updated after snapshot refresh'
    if updatedItems?.length > 0 then items_.db.bulk updatedItems

  .catch _.Error('refresh snapshot err')

fromUri = (changedEntityUri)->
  getEntityByUri changedEntityUri
  .then fromDoc

module.exports = { fromDoc, fromUri }

multiWorkRefresh = (relationProperty)-> (uri)->
  entities_.urisByClaim relationProperty, uri
  .map refresh.work
  .then _.flatten

refresh =
  edition: (uri)->
    # Get all the entities docs required to build the snapshot
    getEditionGraphEntities uri
    # Build common updated snapshot
    .spread getUpdatedEditionItems

  work: (uri)->
    getEntityByUri uri
    .then (work)->
      getWorkAuthorsAndSeries work
      .spread (authors, series)->
        Promise.all [
          getUpdatedWorkItems uri, work, authors, series
          getUpdatedEditionsItems uri, work, authors, series
        ]
        .then _.flatten

  human: multiWorkRefresh 'wdt:P50'
  serie: multiWorkRefresh 'wdt:P179'

refreshTypes = Object.keys refresh

getUpdatedWorkItems = (uri, work, authors, series)->
  items_.byEntity uri
  .map (item)->
    if item.lang then return item
    else addUserLang item, work
  .map (item)->
    { lang } = item
    updatedSnapshot = buildSnapshot.work lang, work, authors, series
    # Temporarly always returning an updated item
    # to be sure to update item.lang
    return addSnapshot item, updatedSnapshot
    # if _.objDiff item.snapshot, updatedSnapshot
    #   return addSnapshot item, updatedSnapshot
    # else
    #   return null
  # Filter out items without snapshot change
  .filter _.identity

addUserLang = (item, work)->
  workLang = Object.keys work.labels
  user_.byId item.owner
  .then (user)->
    userLang = _.shortLang(user.language)
    if userLang in workLang
      # _.log userLang, "using user lang (item: #{item._id})"
      item.lang = userLang
    else if 'en' in workLang
      # _.warn 'en', "defaulting to English (item: #{item._id})"
      item.lang = workLang[0]
    else
      pickedLang = workLang.filter(isShortLang)[0] or workLang[0]
      _.warn pickedLang, "using first available lang found (item: #{item._id})"
      item.lang = pickedLang
    return item

isShortLang = (str)-> str.length is 2

getUpdatedEditionsItems = (uri, work, authors, series)->
  entities_.byClaim 'wdt:P629', uri, true, true
  .map (edition)-> getUpdatedEditionItems edition, work, authors, series
  # Keep only items that had a change
  .filter _.identity
  .then _.flatten

getUpdatedEditionItems = (edition, work, authors, series)->
  [ uri ] = getInvEntityCanonicalUri edition
  updatedSnapshot = buildSnapshot.edition edition, work, authors, series
  # Find all edition items
  items_.byEntity uri
  .then (items)->
    unless items.length > 0 then return
    if _.objDiff items[0].snapshot, updatedSnapshot
      # Update snapshot
      return items.map (item)-> addSnapshot item, updatedSnapshot
