CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ nonAuthReq, authReq, undesiredRes, undesiredErr } = require '../utils/utils'
{ createWork } = require '../fixtures/entities'

describe 'entities:update-claims', ->
  it 'should reject an update with an inappropriate property', (done)->
    createWork()
    .then (work)->
      authReq 'put', '/api/entities?action=update-claim',
        id: work._id
        # A work entity should not have pages count
        property: 'wdt:P1104'
        'new-value': 124
      .then undesiredRes(done)
      .catch (err)->
        err.body.status_verbose.should.equal "works can't have a property wdt:P1104"
        err.statusCode.should.equal 400
        done()
    .catch undesiredErr(done)

    return
