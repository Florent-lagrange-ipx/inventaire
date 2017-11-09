__ = require('config').universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
items_ = __.require 'controllers', 'items/lib/items'
bundleOwnersData = require './lib/bundle_owners_data'

module.exports = (req, res)->
  { query } = req
  { limit, offset } = query
  assertImage = query['assert-image'] is 'true'
  reqUserId = req.user?._id

  limit or= '15'
  offset or= '0'

  try
    limit = _.stringToInt limit
  catch err
    return error_.bundleInvalid req, res, 'limit', limit

  try
    offset = _.stringToInt offset
  catch err
    return error_.bundleInvalid req, res, 'offset', offset

  if limit > 100
    return error_.bundle req, res, "limit can't be over 100", 400, limit

  items_.publicByDate limit, offset, assertImage, reqUserId
  .then bundleOwnersData.bind(null, res, reqUserId)
  .catch error_.Handler(req, res)
