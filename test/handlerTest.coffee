Handler = require "../app/handler"
agent = require "superagent"

describe "Handler", ->
  handler = null

  startHandler = (options) =>
    if options.queuePort is undefined
      options.queuePort = false

    options.storage =
      original:
        type: "local"
        sourcePath: __dirname + "/storage/original"
      thumbnail:
        type: "local"
        sourcePath: __dirname + "/storage/thumbnail"

    handler = new Handler
      options: options
      logger:
        info: ->
        error: ->
        debug: ->

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
    beforeEach (done) =>
      startHandler(handlerPort: 5000)
      handler.queue.client.flushdb done

    describe "GET /status", ->
      it "should return status", (done) ->
        agent.get("http://localhost:5000/status").end (res) =>
          res.body.status.should.equal "running"
          done()

    describe "v1", ->
      describe "GET /v1/:width/:height/:path", (done) ->
        it "should queue the thumbnail generation", (done) ->
          agent.get("http://localhost:5000/v1/400/300/image.jpg").end (res) =>

          fun = =>
            queue = handler.queue
            queue.inactive (err, jobs) =>
              jobs.length.should.equal 1

              require("kue").Job.get jobs[0], (err, job) =>
                job.data.payload.width.should.equal "400"
                job.data.payload.height.should.equal "300"
                job.data.payload.path.should.equal "image.jpg"

                done()

          setTimeout fun, 200

        it "should return 404 if file does not exist", (done) ->
          agent.get("http://localhost:5000/v1/400/300/foo.jpg").end (res) =>
            res.status.should.equal 404

            done()

        it "should return pre-generated thumbnails", (done) ->
          hash = handler.thumbnailStorage.calculateHash "image.jpg", width: 400, height: 300

          handler.originalStorage.createReadStream "image.jpg", (err, readStream) =>
            handler.thumbnailStorage.createWriteStream hash, (err, writeStream) =>
              readStream.pipe writeStream

              writeStream.on "close", =>
                agent.get("http://localhost:5000/v1/400/300/image.jpg").end (res) =>
                  res.ok.should.equal true

                  require("fs").unlinkSync handler.thumbnailStorage.options.sourcePath + "/#{hash}"
                  done()

      describe "GET /v1/:width/:height/:parameters/:path", (done) ->
        it "should queue the thumbnail generation", (done) ->
          agent.get("http://localhost:5000/v1/400/300/filters:watermark(watermark.jpg,0,0,0)/image.jpg").end (res) =>

          fun = =>
            queue = handler.queue
            queue.inactive (err, jobs) =>
              jobs.length.should.equal 1

              require("kue").Job.get jobs[0], (err, job) =>
                job.data.payload.width.should.equal "400"
                job.data.payload.height.should.equal "300"
                job.data.payload.filters.length.should.equal 1
                job.data.payload.filters[0].type.should.equal "watermark"
                job.data.payload.filters[0].file.should.equal "watermark.jpg"
                job.data.payload.filters[0].x.should.equal 0
                job.data.payload.filters[0].y.should.equal 0
                job.data.payload.filters[0].opacity.should.equal 0
                job.data.payload.path.should.equal "image.jpg"

                done()

          setTimeout fun, 200
