__ = require('config').universalPath
_ = __.require 'builders', 'utils'
getEntitiesByUris = __.require 'controllers', 'entities/lib/get_entities_by_uris'

module.exports = (entities)->
  { works, editions } = splitEntities entities
  worksUris = _.pluck works, 'uri'
  data = { editionsWorksUris: [], editionWorkMap: {} }
  { editionsWorksUris, editionWorkMap } = editions.reduce aggregateEditionsWorksUris, data
  # Do no refetch works already fetched
  editionsWorksUris = _.uniq _.difference(editionsWorksUris, worksUris)
  getEntitiesByUris editionsWorksUris
  .get 'entities'
  .then (editionsWorksEntities)->
    works = works.concat _.values(editionsWorksEntities)
    return { works, editionWorkMap }

splitEntities = (entities)->
  _.values(entities).reduce splitWorksAndEditions, { works: [], editions: [] }

splitWorksAndEditions = (results, entity)->
  switch entity.type
    when 'work' then results.works.push entity
    when 'edition' then results.editions.push entity
    else _.warn entity, 'invalid item entity type'
  return results

aggregateEditionsWorksUris = (data, edition)->
  worksUris = edition.claims['wdt:P629']
  if worksUris?
    data.editionWorkMap[edition.uri] = worksUris
    data.editionsWorksUris.push worksUris...
  else
    _.warn edition, 'edition without work'
  return data
