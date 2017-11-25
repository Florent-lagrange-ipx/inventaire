__ = require('config').universalPath
_ = __.require 'builders', 'utils'
buildInvertedClaimTree = require './build_inverted_claim_tree'

module.exports = (items)-> (entitiesData)->
  { works, editionWorkMap } = entitiesData
  worksTree = buildInvertedClaimTree works
  workUriItemsMap = items.reduce buildWorkUriItemsMap(editionWorkMap), {}
  itemsByDate = getItemsIdsByDate items
  worksByOwner = items.reduce aggregateOwnersWorks(editionWorkMap), {}
  worksTree.owner = worksByOwner
  return { worksTree, workUriItemsMap, itemsByDate }

buildWorkUriItemsMap = (editionWorkMap)-> (workUriItemsMap, item)->
  { _id:itemId, entity:itemEntityUri } = item
  itemWorksUris = editionWorkMap[itemEntityUri] or [ itemEntityUri ]
  for workUri in itemWorksUris
    workUriItemsMap[workUri] or= []
    workUriItemsMap[workUri].push itemId
  return workUriItemsMap

aggregateOwnersWorks = (editionWorkMap)-> (index, item)->
  { _id:itemId, owner:ownerId, entity:entityUri } = item
  workUri = editionWorkMap[entityUri] or entityUri
  index[ownerId] or= {}
  index[ownerId][workUri] or= []
  index[ownerId][workUri].push itemId
  return index

getItemsIdsByDate = (items)->
  items
  .sort sortByCreationDate
  .map getId

getId = _.property '_id'
sortByCreationDate = (a, b)-> b.created - a.created
