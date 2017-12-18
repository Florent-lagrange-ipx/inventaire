__ = require('config').universalPath
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
entities_ = __.require 'controllers', 'entities/lib/entities'
task_ = __.require 'controllers', 'tasks/lib/tasks'

getEntitiesByUris = __.require 'controllers', 'entities/lib/get_entities_by_uris'
checkEntities = __.require 'controllers', 'tasks/lib/check_entities'

urify = (entity)->
  "inv:#{entity['entity']}"

module.exports = (req, res)->
  entities_.byClaimsValue "wd:Q5"
  .then (results)->
    entitiesUris = _.map results, urify
    getEntitiesByUris entitiesUris
  .then (res)->
    checkEntities res.entities
  .then (tasks)->
    Promise.all tasks.map(task_.create)
  .catch error_.Handler(req, res)


