CONFIG = require 'config'
__ = CONFIG.universalPath
{ Promise } = __.require 'lib', 'promises'
{ hashPasswords } = CONFIG

if hashPasswords
  module.exports = require('credential')()
else
  # Disabling password hashing can be convenient in test environment
  # to run tests faster
  # Disabling hashing is done by mimicking 'credential' API
  # while not hashing anything, thus storing the password in plain text
  # in the database: the good old way! \o/
  module.exports =
    # Disabling hashing by returning a promise that resolves to the input password
    hash: Promise.resolve
    # Thus verifying the password is simply comparing the input password
    # with the password set in the database
    verify: (hash, password)-> Promise.resolve hash is password
    # In this mode, tokens never expire
    expired: -> false
