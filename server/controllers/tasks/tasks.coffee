__ = require('config').universalPath
_ = __.require 'builders', 'utils'

ActionsControllers = __.require 'lib', 'actions_controllers'
module.exports =
  get: ActionsControllers
    public:
      'deduplicate-todo': require './deduplicate_todo'
      'deduplicates': require './deduplicates'

  post: ActionsControllers
    public:
      'create': require './create'