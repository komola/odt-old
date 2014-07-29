Handler = require "../app/handler"
agent = require "superagent"

describe "Handler", ->
  handler = null

  startHandler = (options) =>
    if options.queuePort is undefined
      options.queuePort = false

    handler = new Handler
      options: options
      logger:
        info: ->
        error: ->

    handler.start()

  afterEach (done) =>
    handler.shutdown done

  describe "#start", ->
    it "should start a handler instance on the specified port", (done) ->
      startHandler(handlerPort: 3500)

      agent.get("http://localhost:3500/status").end (res) =>
        res.ok.should.be.true
        done()

    it "should start worker interface if provided", (done) ->
      startHandler(handlerPort: 3500, queuePort: 4000)

      agent.get("http://localhost:4000").end (res) =>
        res.ok.should.be.true
        done()

    it "should not start worker if queuePort is set to false", (done) ->
      startHandler(handlerPort: 3500, queuePort: false)

      agent.get("http://localhost:4000")
        .on "error", =>
          done()
        .end (res) =>
          return done new Error "queue seems to be running"

  describe "running server", ->
    beforeEach =>
      startHandler(handlerPort: 5000)

    describe "GET /status", ->
      it "should return status", (done) ->
        agent.get("http://localhost:5000/status").end (res) =>
          res.body.status.should.equal "running"
          done()
