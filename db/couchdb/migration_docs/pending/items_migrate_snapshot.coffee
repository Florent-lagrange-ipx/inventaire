__ = require('config').universalPath
_ = __.require 'builders', 'utils'
items_ = __.require 'controllers', 'items/lib/items'
refreshSnapshot = __.require 'controllers', 'items/lib/snapshot/refresh_snapshot'

levelBase = __.require 'level', 'base'
migrationDone = levelBase.simpleAPI 'migration'
{ writeFileSync } = require 'fs'

getAllItemsEntitiesUris = ->
  items_.db.view 'items', 'byEntity', {}
  .then (res)->
    uris = res.rows.map (row)-> row.key[0]
    return _.uniq uris

failedUris = []

refreshByUris = (uris)->
  refreshNext = ->
    console.log('uris', uris.length)
    if uris.length is 0
      _.inspect failedUris, 'failedUris'
      writeFileSync './failed_uris', failedUris.join('\n')
      _.success 'DONE'
      process.exit 0
      return

    nextUri = uris.pop()
    console.log('nextUri', nextUri)

    refreshSnapshot.fromUri nextUri
    .then -> migrationDone.put nextUri, true
    .catch (err)->
      console.error err.message
      failedUris.push nextUri
    # Free the memory allocated to this promise chain
    # by starting the next refresh out of this chain
    .then -> setTimeout refreshNext, 0

  return refreshNext()

removeAlreadyDone = (uri)->
  migrationDone.get uri
  .then (alreadyDone)-> unless alreadyDone then return uri

getAllItemsEntitiesUris()
.map removeAlreadyDone
.filter _.identity
.then refreshByUris

# refreshByUris [ 'inv:bafaf4da2bcac0d8746c4ff1c9326b7e' ]
