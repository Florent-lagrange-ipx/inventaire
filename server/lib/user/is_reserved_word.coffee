reservedWords = [
  'api'
  'entity'
  'entities'
  'inventory'
  'inventories'
  'wd'
  'wikidata'
  'isbn'
  'profil'
  'profile'
  'item'
  'items'
  'auth'
  'listings'
  'contacts'
  'contact'
  'user'
  'users'
  'friend'
  'friends'
  'welcome'
  'username'
  'email'
]

module.exports =  (username)->
  return username in reservedWords