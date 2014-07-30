_ = require "lodash"
cluster = require "cluster"
kue = require "kue"

LocalStorage = require "./storage/local"
SwiftStorage = require "./storage/swift"

class ODT
  constructor: (params) ->
    @options = params.options
    @logger = params.logger

  start: (callback) =>
    @setupQueue()
    @setupStorage()

  setupStorage: =>
    @originalStorage = originalStorage = @initOriginalStorage()
    @thumbnailStorage = thumbnailStorage = @initThumbnailStorage()

  setupQueue: =>
    @queue = kue.createQueue()

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
