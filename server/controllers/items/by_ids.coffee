__ = require('config').universalPath
_ = __.require 'builders', 'utils'
items_ = __.require 'controllers', 'items/lib/items'
user_ = __.require 'controllers', 'user/lib/user'
relations_ = __.require 'controllers', 'relations/lib/queries'
error_ = __.require 'lib', 'error/error'
promises_ = __.require 'lib', 'promises'
{ validateQuery, addUsersData, listingIs, Paginate } = require './lib/queries_commons'
{ omitPrivateAttributes } = require './lib/filter_private_attributes'

module.exports = (req, res)->
  reqUserId = req.user?._id

  # By default, doesn't include users
  includeUsers = _.parseBooleanString req.query['include-users']

  validateQuery req.query, 'ids', _.isItemId
  .then (page)->
    { params:ids } = page
    promises_.all [
      items_.byIds ids
      getNetworkIds reqUserId
    ]
    .spread filterAuthorizedItems(reqUserId)
    # Paginating isn't really required when requesting items by ids
    # but it also handles sorting and the consistency of the API
    .then Paginate(page)
  .then addUsersData(reqUserId, includeUsers)
  .then res.json.bind(res)
  .catch error_.Handler(req, res)

getNetworkIds = (reqUserId)->
  if reqUserId? then return relations_.getUserFriendsAndCoGroupsMembers reqUserId
  else return []

filterAuthorizedItems = (reqUserId)-> (items, networkIds)->
  _.compact items
  .map filterByAuthorization(reqUserId, networkIds)
  # Keep non-nullified items
  .filter _.identity

filterByAuthorization = (reqUserId, networkIds)-> (item)->
  { owner:ownerId, listing } = item

  if ownerId is reqUserId then return item

  else if ownerId in networkIds
    # Filter-out private item for network users
    if listing isnt 'private' then return omitPrivateAttributes(item)

  else
    # Filter-out all non-public items for non-network users
    if listing is 'public' then return omitPrivateAttributes(item)
