__ = require('config').root
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
emailValidation = require './email_validation'

module.exports.get = (req, res, next)->
  {service} = req.query
  switch service
    when 'email-validation' then return emailValidation(req, res, next)
    else error_.bundle res, 'unknown service', 400, service