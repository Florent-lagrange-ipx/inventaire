CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'

deduplicates = '/api/tasks?action=deduplicates&limit=100'
deduplicateTodo = '/api/tasks?action=deduplicate-todo'
{ authReq, nonAuthReq, undesiredErr } = __.require 'apiTests', 'utils/utils'
{ createHuman } = require '../fixtures/entities'

describe 'tasks:create', ->
  it 'should create new tasks', (done)->
    authReq 'post', '/api/tasks?action=create',
      type: 'deduplicate'
      suspectUri: 'inv:089b1950b230556f6c2b22557104eb86'
    .then (res)->
      res._id.should.be.a.String()
      res._rev.should.be.a.String()
      done()
    .catch undesiredErr(done)


describe 'tasks:deduplicate-todo', ->
  it 'should create new tasks to deduplicate', (done)->
    createHuman('Stanislas Lem')
    .then (res)->
      nonAuthReq 'get', deduplicateTodo
    .then (res)->
      res.length.should.equal(1)
      done()
    .catch undesiredErr(done)

    return
