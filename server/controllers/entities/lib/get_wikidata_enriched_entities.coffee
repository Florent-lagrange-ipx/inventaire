# # How to merge Wikidata and Inv entities?

# ## Problems
# - How to set priority in data?
# Properties on Wikidata should be set in Wikidata
# Other properties can be set in Inventaire

# - What happens when an entity in Inventaire is created in Wikidata?
#   => properties are suggested to Wikidata to get back to the above scheme

__ = require('config').universalPath
_ = __.require 'builders', 'utils'
{ Promise } = __.require 'lib', 'promises'
wdk = require 'wikidata-sdk'
{ getOriginalLang } = __.require 'lib', 'wikidata/wikidata'
formatClaims = __.require 'lib', 'wikidata/format_claims'
{ simplify } = wdk
getEntityType = require './get_entity_type'
prefixify = __.require 'lib', 'wikidata/prefixify'
entities_ = require './entities'
cache_ = __.require 'lib', 'cache'
promises_ = __.require 'lib', 'promises'
getWdEntity = __.require 'data', 'wikidata/get_entity'
getInvEntityByWdId = require './get_inv_entity_by_wd_id'
addImageData = require './add_image_data'
radio = __.require 'lib', 'radio'
propagateRedirection = require './propagate_redirection'
{ _id:hookUserId } = __.require('couch', 'hard_coded_documents').users.hook

module.exports = (ids, refresh)->
  promises_.all ids.map(getCachedEnrichedEntity(refresh))
  .then (entities)-> { entities }

getCachedEnrichedEntity = (refresh)-> (wdId)->
  key = "wd:enriched:#{wdId}"
  timespan = if refresh then 0 else null
  cache_.get key, getEnrichedEntity.bind(null, wdId), timespan

getEnrichedEntity = (wdId)->
  Promise.all [
    getWdEntity wdId
    getInvEntityByWdId wdId
  ]
  .spread mergeWdAndInvData

mergeWdAndInvData = (entity, invEntity)->
  if entity.missing? then return formatEmpty 'missing', entity
  { P31 } = entity.claims
  if P31
    simplifiedP31 = wdk.simplifyPropertyClaims P31
    entity.type = getEntityType simplifiedP31.map(prefixify)
    radio.emit 'wikidata:entity:cache:miss', entity.id, entity.type
  else
    # Make sure to override the type as Wikidata entities have a type with
    # another role in Wikibase, and we need this absence of known type to
    # filter-out entities that aren't in our focus (i.e. not works, author, etc)
    entity.type = null

  entity.claims = omitUndesiredPropertiesPerType entity.type, entity.claims

  if entity.type is 'meta' then return formatEmpty 'meta', entity
  else return format entity, invEntity

format = (entity, invEntity)->
  { id:wdId } = entity
  entity.uri = "wd:#{wdId}"
  entity.labels = simplify.labels entity.labels
  entity.descriptions = simplify.descriptions entity.descriptions
  entity.sitelinks = simplify.sitelinks entity.sitelinks
  entity.claims = formatClaims entity.claims, wdId
  entity.originalLang = getOriginalLang entity.claims

  formatAndPropagateRedirection entity

  # Deleting unnecessary attributes
  delete entity.id
  delete entity.modified
  delete entity.pageid
  delete entity.ns
  delete entity.title
  delete entity.lastrevid
  # Testing without aliases: the only use would be for local entity search(?)
  delete entity.aliases

  if invEntity?
    # Purposedly not doing a deep merge so that it's all or nothing:
    # If a property has a value in Inventaire, it overrides Wikidata
    # But the responsability of properties available in Wikidata
    # should be let as much as possible to Wikidata
    _.extend entity.labels, invEntity.labels
    _.extend entity.claims, invEntity.claims
    # Attach inv database id to allow direct edit
    entity._id = invEntity._id

  else
    # Manually add the property that would link the Wikidata entity
    # to the to-be-created-when-needed local inv entity
    entity.claims['invp:P1'] = [ wdId ]

  return addImageData entity

formatAndPropagateRedirection = (entity)->
  if entity.redirects?
    { from, to } = entity.redirects
    entity.redirects =
      from: prefixify from
      to: prefixify to

    # Take advantage of this request for a Wikidata entity to check
    # if there is a redirection we are not aware of, and propagate it:
    # if the redirected entity is used in Inventaire claims, redirect claims
    # to their new entity
    propagateRedirection hookUserId, entity.redirects.from, entity.redirects.to

  return

formatEmpty = (type, entity)->
  # Keeping just enough data to filter-out while not cluttering the cache
  id: entity.id
  uri: "wd:#{entity.id}"
  type: type

omitUndesiredPropertiesPerType = (type, claims)->
  propertiesToOmit = undesiredPropertiesPerType[type]
  if propertiesToOmit? then _.omit claims, propertiesToOmit
  else claims

undesiredPropertiesPerType =
  # Ignoring ISBN data set on work entities, as those should be the responsability
  # of edition entities
  work: [ 'P212', 'P957' ]

# Not really related, out of the fact that it listen for
# 'wikidata:entity:cache:miss', but that needed to be initialized somewhere
require('./update_search_engine')()
