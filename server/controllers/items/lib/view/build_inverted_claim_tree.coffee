module.exports = (entities)-> entities.reduce addToTree, {}

viewProperties = [ 'wdt:P50', 'wdt:P136', 'wdt:P921' ]

addToTree = (tree, entity)->
  { uri, claims } = entity
  for property in viewProperties
    tree[property] or= { unknown: [] }
    values = entity.claims[property]
    if values?
      for value in values
        tree[property][value] or= []
        tree[property][value].push uri
    else
      tree[property].unknown.push uri

  return tree
