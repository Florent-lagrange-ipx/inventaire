module.exports = (entities)-> entities.reduce addToTree, {}

viewProperties =
  'wdt:P50': 'author'
  'wdt:P136': 'genre'
  'wdt:P921': 'subject'

addToTree = (tree, entity)->
  { uri, claims } = entity
  for property, name of viewProperties
    tree[name] or= { unknown: [] }
    values = entity.claims[property]
    if values?
      for value in values
        tree[name][value] or= []
        tree[name][value].push uri
    else
      tree[name].unknown.push uri

  return tree
