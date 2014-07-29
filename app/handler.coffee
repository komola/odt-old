_ = require "lodash"
express = require "express"
cluster = require "cluster"
kue = require "kue"

class Handler
  constructor: (params) ->
    @options = params.options
    @logger = params.logger

  start: (callback) =>
    @setupServer()
    @setupQueue()

  setupServer: =>
    if cluster.isMaster and process.env.NODE_ENV isnt "test"
      for port in [1..@options.instances]
        cluster.fork()

      cluster.on "exit", (worker) =>
        logger.error "Worker #{worker.id} died"
        cluster.fork()

    else
      # start the app
      @app = app = express()

      app.get "/status", (req, res) =>
        res.json status: "running"

      @server = server = app.listen @options.handlerPort, =>
        @logger.info "Starting handler instances on ports", @options.handlerPort

  setupQueue: =>
    return if cluster.isWorker or process.env.NODE_ENV isnt "test"

    kue.createQueue()

    @startQueueInterface()

  startQueueInterface: =>
    return if @options.queuePort is false

    @queueServer = kue.app.listen @options.queuePort
    kue.app.set "title", "ODT Handler Queue Interface"

  shutdown: (callback) =>
    @server.close()
    @queueServer?.close()

    callback() if callback

module.exports = Handler
