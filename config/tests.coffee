# Use by setting NODE_ENV=tests
# Will be overriden by local.coffee

module.exports =
  env: 'tests'
  protocol: 'http'
  name: "inventaire"
  host: 'localhost'
  port: 3009
  verbosity: 0
  fullHost: -> "#{@protocol}://#{@host}:#{@port}"
  db:
    suffix: 'tests'
    # debug: true
    follow:
      # Follow is always reset as tests run LevelDB in memory thank to level-test
      reset: true
      freeze: false
      # Give 1000 delay so that tests relying on follow don't have to wait
      delay: 1000
  graph:
    social: undefined
  godMode: false
  piwik:
    enabled: false
  dataseed:
    enabled: false
  deduplicateRequests: false
  mailer:
    disabled: true
