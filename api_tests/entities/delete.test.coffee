CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ Promise } = __.require 'lib', 'promises'
{ nonAuthReq, authReq, adminReq, undesiredRes, undesiredErr } = require '../utils/utils'
{ createHuman, createWork, createWorkWithAuthor, createEdition, ensureEditionExists } = require '../fixtures/entities'

describe 'entities:delete:by-uris', ->
  it 'should require admin rights', (done)->
    createHuman()
    .then (entity)-> authReq 'delete', "/api/entities?action=by-uris&uris=#{entity.uri}"
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 403
      done()

    return

  it 'should reject non-inv URIs', (done)->
    adminReq 'delete', "/api/entities?action=by-uris&uris=wd:Q535"
    .then undesiredRes(done)
    .catch (err)->
      err.body.status_verbose.should.equal 'invalid uri: wd:Q535'
      err.statusCode.should.equal 400
      done()
    .catch undesiredErr(done)

    return

  it 'should turn entity into removed:placeholder', (done)->
    createHuman()
    .then (entity)->
      { uri } = entity
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{uri}"
      .then -> nonAuthReq 'get', "/api/entities?action=by-uris&uris=#{uri}"
      .then (res)->
        should(res.entities[uri]._meta_type).equal 'removed:placeholder'
        done()
    .catch undesiredErr(done)

    return

  it 'should remove several entities', (done)->
    Promise.all [
      createHuman()
      createWork()
    ]
    .spread (entityA, entityB)->
      { uri:uriA } = entityA
      { uri:uriB } = entityB
      uris = "#{uriA}|#{uriB}"
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{uris}"
      .then -> nonAuthReq 'get', "/api/entities?action=by-uris&uris=#{uris}"
      .then (res)->
        for uri, entity in res.entities
          should(entity._meta_type).equal 'removed:placeholder'
        done()
    .catch undesiredErr(done)

    return

  it 'should delete the claims where this entity is the value', (done)->
    createWorkWithAuthor()
    .then (work)->
      { uri:workUri } = work
      authorUri = work.claims['wdt:P50'][0]
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{authorUri}"
      .then -> nonAuthReq 'get', "/api/entities?action=by-uris&uris=#{workUri}"
      .then (res)->
        updatedWork = res.entities[workUri]
        should(updatedWork.claims['wdt:P50']).not.be.ok()
        done()
    .catch undesiredErr(done)

    return

  # Entities with more than one claim should be turned into redirections
  it 'should refuse to delete entities that are values in more than one claim', (done)->
    createHuman()
    .then (author)->
      Promise.all [ createWorkWithAuthor(author), createWorkWithAuthor(author) ]
    .spread (workA, workB)->
      { uri:workUri } = workA
      authorUri = workA.claims['wdt:P50'][0]
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{authorUri}"
    .then undesiredRes(done)
    .catch (err)->
      err.body.status_verbose.should.equal 'this entity has too many claims to be removed'
      err.statusCode.should.equal 400
      done()
    .catch undesiredErr(done)
    return

  it 'should remove edition entities without an ISBN', (done)->
    createEdition()
    .then (edition)->
      invUri = 'inv:' + edition._id
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{invUri}"
    .then -> done()
    .catch undesiredErr(done)
    return

  it 'should remove edition entities with an ISBN', (done)->
    uri = 'isbn:9782298063264'
    ensureEditionExists uri
    .then (edition)->
      # Using the inv URI, as the isbn one would be rejected earlier
      invUri = 'inv:' + edition._id
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{invUri}"
    .then -> done()
    .catch undesiredErr(done)
    return

  it 'should refuse to delete a work that is depend on by an edition', (done)->
    createEdition()
    .then (edition)->
      workUri = edition.claims['wdt:P629'][0]
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{workUri}"
    .then undesiredRes(done)
    .catch (err)->
      err.body.status_verbose.should.equal "this entity is used in a critical claim"
      err.statusCode.should.equal 400
      done()
    .catch undesiredErr(done)
    return

  it 'should remove deleted entities from items snapshot', (done)->
    createHuman()
    .then (author)->
      createWorkWithAuthor author
      .then (work)->
        authReq 'post', '/api/items', { entity: work.uri, lang: 'en' }
        .then (item)->
          item.snapshot['entity:title'].should.equal work.labels.en
          item.snapshot['entity:authors'].should.equal author.labels.en
          adminReq 'delete', "/api/entities?action=by-uris&uris=#{author.uri}"
          .delay 100
          .then -> authReq 'get', "/api/items?action=by-ids&ids=#{item._id}"
          .then (res)->
            updatedItem = res.items[0]
            updatedItem.snapshot['entity:title'].should.equal work.labels.en
            should(updatedItem.snapshot['entity:authors']).not.be.ok()
            done()

    .catch undesiredErr(done)

    return

  it 'should ignore entities that where already turned into removed:placeholder', (done)->
    createHuman()
    .then (entity)->
      { uri } = entity
      adminReq 'delete', "/api/entities?action=by-uris&uris=#{uri}"
      .then -> nonAuthReq 'get', "/api/entities?action=by-uris&uris=#{uri}"
      .then (res)->
        should(res.entities[uri]._meta_type).equal 'removed:placeholder'
        adminReq 'delete', "/api/entities?action=by-uris&uris=#{uri}"
        .then -> done()
    .catch undesiredErr(done)

    return

  it 'should not deleted entities that are the entity of an item', (done)->
    createWork()
    .then (work)->
      authReq 'post', '/api/items', { entity: work.uri, lang: 'en' }
      .then -> adminReq 'delete', "/api/entities?action=by-uris&uris=#{work.uri}"
      .then undesiredRes(done)
      .catch (err)->
        err.body.status_verbose.should.equal "entities that are used by an item can't be removed"
        err.statusCode.should.equal 400
        done()
    .catch undesiredErr(done)
    return
