_ = require "lodash"
express = require "express"
cluster = require "cluster"
kue = require "kue"

LocalStorage = require "./storage/local"

class Handler
  constructor: (params) ->
    @options = params.options
    @logger = params.logger

  start: (callback) =>
    @setupQueue()
    @setupServer()

  setupServer: =>
    if cluster.isMaster and process.env.NODE_ENV isnt "test"
      for port in [1..@options.instances]
        cluster.fork()

      cluster.on "exit", (worker) =>
        logger.error "Worker #{worker.id} died"
        cluster.fork()

    else
      @originalStorage = originalStorage = @initOriginalStorage()
      @thumbnailStorage = thumbnailStorage = @initThumbnailStorage()

      # start the app
      @app = app = express()

      # pass along the options and logger
      app.use (req, res, next) =>
        req.options = @options
        req.logger = @logger
        req.originalStorage = originalStorage
        req.thumbnailStorage = thumbnailStorage
        req.queue = @queue

        next()

      app.get "/status", (req, res) =>
        res.json status: "running"

      app.use "/v1", require("./routes/v1/serve")

      @server = server = app.listen @options.handlerPort, =>
        @logger.info "Starting handler instances on ports", @options.handlerPort

  setupQueue: =>
    @queue = kue.createQueue()

    return if cluster.isWorker or process.env.NODE_ENV isnt "test"

    @startQueueInterface()

  startQueueInterface: =>
    return if @options.queuePort is false

    @queueServer = kue.app.listen @options.queuePort
    kue.app.set "title", "ODT Handler Queue Interface"

  initOriginalStorage: =>
    instance = @_initStorage @options.storage.original
    return instance

  initThumbnailStorage: =>
    instance = @_initStorage @options.storage.thumbnail
    return instance

  _initStorage: (options) =>
    klass = switch options.type
      when "local" then LocalStorage
      else LocalStorage

    instance = new klass _.omit(options, "type")
    return instance

  shutdown: (callback) =>
    @server.close()
    @queueServer?.close()

    callback() if callback

module.exports = Handler
