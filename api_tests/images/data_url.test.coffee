CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
should = require 'should'
{ authReq, undesiredRes, undesiredErr } = require '../utils/utils'

imageUrl = encodeURIComponent 'https://raw.githubusercontent.com/inventaire/inventaire-client/master/app/assets/icon/32.png'
dataUrlStart = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYA'

describe 'images:data-url', ->
  it 'should reject a request without URL', (done)->
    authReq 'get', "/api/images?action=data-url"
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'missing parameter in query: url'
      done()
    .catch undesiredErr(done)

    return

  it 'should reject a request with an invalid URL', (done)->
    authReq 'get', "/api/images?action=data-url&url=bla"
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'invalid url: bla'
      done()
    .catch undesiredErr(done)

    return

  it 'should reject a request with an invalid content type', (done)->
    invalidContentTypeUrl = encodeURIComponent 'http://maxlath.eu/data.json'
    authReq 'get', "/api/images?action=data-url&url=#{invalidContentTypeUrl}"
    .then undesiredRes(done)
    .catch (err)->
      err.statusCode.should.equal 400
      err.body.status_verbose.should.equal 'invalid content type'
      done()
    .catch undesiredErr(done)

    return
  it 'should return a data-url', (done)->
    authReq 'get', "/api/images?action=data-url&url=#{imageUrl}"
    .then (res)->
      res['data-url'].should.be.a.String()
      res['data-url'].should.startWith dataUrlStart
      done()
    .catch undesiredErr(done)

    return
