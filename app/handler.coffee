_ = require "lodash"
express = require "express"
cluster = require "cluster"
kue = require "kue"

ODT = require "./odt"

class Handler extends ODT
  start: (callback) =>
    super()
    @setupServer()
    @startQueueInterface()

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

      # pass along the options and logger
      app.use (req, res, next) =>
        req.options = @options
        req.logger = @logger
        req.originalStorage = @originalStorage
        req.thumbnailStorage = @thumbnailStorage
        req.queue = @queue

        next()

      app.get "/status", (req, res) =>
        res.json status: "running"

      app.use "/v1", require("./routes/v1/serve")

      @server = server = app.listen @options.handlerPort, =>
        @logger.info "Starting handler instances on ports", @options.handlerPort

  startQueueInterface: =>
    return if @options.queuePort is false
    return if cluster.isWorker

    @queueServer = kue.app.listen @options.queuePort
    kue.app.set "title", "ODT Handler Queue Interface"


  shutdown: (callback) =>
    super =>
      @server.close()
      callback() if callback

module.exports = Handler
