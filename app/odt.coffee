_ = require "lodash"
cluster = require "cluster"
kue = require "kue"
StatsD = require("node-statsd").StatsD

LocalStorage = require "./storage/local"
SwiftStorage = require "./storage/swift"

class ODT
  constructor: (params) ->
    @options = params.options
    @logger = params.logger

  start: (callback) =>
    @setupQueue()
    @setupStorage()
    @setupStatsd()

  setupStorage: =>
    @originalStorage = originalStorage = @initOriginalStorage()
    @thumbnailStorage = thumbnailStorage = @initThumbnailStorage()

  setupQueue: =>
    @queue = kue.createQueue
      prefix: "odt"
      redis:
        port: @options.redisPort or 6379
        host: @options.redisHost or "localhost"
        auth: @options.redisAuth

  setupStatsd: =>
    if @options.statsdHost
      client = new StatsD
        host: @options.statsdHost
        port: @options.statsdPort or 8125
        cacheDns: true
        prefix: @options.statsdPrefix or ""

    @metrics =
      timing: => client?.timing.apply client, arguments
      increment: => client?.increment.apply client, arguments
      decrement: => client?.decrement.apply client, arguments
      histogram: => client?.histogram.apply client, arguments
      gauge: => client?.gauge.apply client, arguments

  initOriginalStorage: =>
    instance = @_initStorage @options.storage.original
    return instance

  initThumbnailStorage: =>
    instance = @_initStorage @options.storage.thumbnail
    return instance

  _initStorage: (options) =>
    klass = switch options.type
      when "local" then LocalStorage
      when "swift" then SwiftStorage
      else LocalStorage

    instance = new klass _.omit(options, "type")
    return instance

  shutdown: (callback) =>
    @queueServer?.close()
    callback() if callback

module.exports = ODT
