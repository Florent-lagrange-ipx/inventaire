__ = require('config').root
_ = __.require('builders', 'utils')

Promises = require './promises'
wd = __.require('sharedLibs', 'wikidata')(Promises, _)
wd.sitelinks = __.require 'sharedLibs','wiki_sitelinks'
module.exports = wd

breq = require 'breq'
wdProps = _.jsonFile('server/lib/wikidata-properties-fr.json').properties

API = wd.API
Q = wd.Q

module.exports.getBookEntities = (query)->
  searchEntities(query.search, query.language)
  .then (res)->
    _.success res, 'searchEntities res'
    if res.success and res.search.length > 0
      return res.search.map (el)-> el.id
    else throw 'not found'
  .then (ids)=>
    _.success ids, 'wd ids found'
    @getEntities(ids, [query.language])
  .then filterAndBrush

module.exports.getBookEntityByIsbn = (isbn, type, lang)->
    switch type
      when 10 then url = API.wmflabs.string 957, isbn
      when 13 then url = API.wmflabs.string 212, isbn
    return Promises.get(url)
    .then (res)=>
      if res.items.length > 0
        id = @normalizeId(res.items[0])
        return @getEntities(id, lang)
        .then(filterAndBrush)
        .then (resultArray)->
          result =
            items: resultArray
            source: 'wd'
            isbn: isbn
      else
        result =
          items: []
          source: 'wd'
          isbn: isbn
          status: 'no item found for this isbn'
    .catch (err)-> _.error err, 'err at getBookEntityByIsbn'


searchEntities = (search, language='en', limit='20', format='json')->
  url = API.wikidata.search(search, language).logIt('searchEntities')
  return Promises.get url

filterAndBrush = (res)->
  results = []
  for id,entity of res.entities
    rebaseClaimsValueToClaimsRoot entity
    if filterWhitelisted entity
      results.push entity
  return results

justBrush = (res)->
  results = []
  for id,entity of res.entities
    rebaseClaimsValueToClaimsRoot entity
    results.push entity
  return results

filterWhitelisted = (entity)->
  valid = false
  logs = [ ['title', entity.title], 'desc', entity.descriptions, ['label.en', entity.labels?.en]]
  if entity.claims? and entity.claims.P31?
    logs.push 'P31'
    logs.push entity.claims.P31
    valid = validIfIsABook(entity.claims, valid)
    valid = validIfIsAnAuthor(entity.claims, valid)
  if valid then _.logArray(logs, 'whitelisted', 'green')
  else _.logArray(logs, 'rejected', 'red')
  return valid

rebaseClaimsValueToClaimsRoot = (entity)->
  for id, claim of entity.claims
    if typeof claim is 'object'
      claim.forEach (statement)->
        switch statement.mainsnak.datatype
          when 'wikibase-item'
            id = statement.mainsnak.datavalue.value['numeric-id']
            statement._id = 'Q' + id
  return

validIfIsABook = (claims, valid)->
  claims.P31?.forEach (statement)->
    valid = true  if statement._id in Q.books
  return valid

validIfIsAnAuthor = (claims, valid)->
  claims.P31?.forEach (statement)->
    valid = true  if statement._id in Q.humans
  return valid

whitelistedEntity = (id)-> id in P31Whitelist
