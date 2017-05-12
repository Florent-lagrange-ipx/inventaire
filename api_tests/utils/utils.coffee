CONFIG = require 'config'
__ = CONFIG.universalPath
_ = __.require 'builders', 'utils'
breq = require 'bluereq'
should = require 'should'
promises_ = __.require 'lib', 'promises'
host = CONFIG.fullHost()
authEndpoint = host + '/api/auth'
randomString = __.require 'lib', './utils/random_string'
{ makeUserAdmin } = __.require 'controllers', 'user/lib/user'

testUser =
  username: 'testuser'
  password: 'testpassword'
  email: 'a+testemail@inventaire.io'

testUserB =
  username: 'testuserb'
  password: 'testpassword'
  email: 'b+testemail@inventaire.io'

testAdmin =
  username: 'testadmin'
  password: 'testpassword'
  email: 'c+testemail@inventaire.io'

loginEndpoint = "#{authEndpoint}?action=login"
signupEndpoint = "#{authEndpoint}?action=signup"

parseCookies = (res) -> res.headers['set-cookie']

getUserCookies = (userData)->
  breq.post { url: loginEndpoint, body: userData }
  .catch (err)->
    if err.statusCode isnt 401 then throw err
    return breq.post { url: signupEndpoint, body: userData }
  .then parseCookies

userCookiesPromise = getUserCookies testUser
userBCookiesPromise = getUserCookies testUserB
adminCookiesPromise =  getUserCookies testAdmin

request = (method, endpoint, body, cookies = [])->
  url = host + endpoint
  headers = { cookie: cookies.join ';' }
  return breq[method]({ url, body, headers }).get 'body'

AuthentifiedRequest = (cookiesPromise)-> (method, endpoint, body)->
  cookiesPromise
  .then request.bind(null, method, endpoint, body)

authentifiedRequest = AuthentifiedRequest userCookiesPromise
bUserAuthentifiedRequest = AuthentifiedRequest userBCookiesPromise
_adminReq = AuthentifiedRequest adminCookiesPromise

GetUser = (authentifiedRequester)-> ()-> authentifiedRequester 'get', '/api/user'

getAdminUser = GetUser _adminReq

waitForAdminRights = getAdminUser().get('_id').then makeUserAdmin

adminReq = (args...)->
  waitForAdminRights
  .then -> _adminReq.apply null, args

userData = ->
  username: 'customuser' + randomString(2)
  password: 'testpassword'
  email: "#{randomString(2)}@inventaire.io"

customUser = ->
  customUserReq = AuthentifiedRequest getUserCookies(userData())
  getCustomUser = GetUser customUserReq
  return { customUserReq, getCustomUser }

module.exports =
  authReq: authentifiedRequest
  nonAuthReq: request
  adminReq: adminReq
  getUser: GetUser authentifiedRequest
  getUserB: GetUser bUserAuthentifiedRequest
  getAdminUser: getAdminUser
  customUser: customUser
  # A function to quickly fail when a test gets an undesired positive answer
  undesiredRes: (done)-> (res)->
    done new Error(".then function was expected not to be called")
    _.warn res, 'undesired positive res'

  undesiredErr: (done)-> (err)->
    done err
    _.warn err.body or err, 'undesired err body'
