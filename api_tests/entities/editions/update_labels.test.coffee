CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ nonAuthReq, authReq, undesiredRes, undesiredErr } = require '../../utils/utils'
{ createEdition } = require '../../fixtures/entities'

describe 'entities:editions:update-labels', ->
  it 'should reject labels update', (done)->
    createEdition()
    .then (edition)->
      authReq 'put', '/api/entities?action=update-label',
        id: edition._id
        lang: 'fr'
        value: 'bla'
      .then undesiredRes(done)
      .catch (err)->
        err.body.status_verbose.should.equal "editions can't have labels"
        err.statusCode.should.equal 400
        done()
    .catch undesiredErr(done)

    return
