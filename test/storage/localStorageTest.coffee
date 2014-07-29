LocalStorage = require "../../app/storage/local"
storage = new LocalStorage
  sourcePath: __dirname + "/fixtures"

describe "LocalStorage", ->
  describe "#exists", ->
    it "should return true for existing images", (done) ->
      storage.exists "image.jpg", (err, exists) =>
        exists.should.equal true
        done()

    it "should return false for non-existent images", (done) ->
      storage.exists "non-existent.jpg", (err, exists) =>
        exists.should.equal false
        done()

  describe "#createReadStream", ->
    it "should return a read stream", (done) ->
      storage.createReadStream "image.jpg", (err, stream) =>
        should.exist stream
        should.not.exist err
        done()

    it.skip "should throw error on read stream on invalid files", (done) ->
      storage.createReadStream "non-existent.jpg", (err, stream) =>
        done()

  describe "#createWriteStream", ->
    it "should create a write stream", (done) ->
      storage.createWriteStream "foo.jpg", (err, stream) =>
        should.exist stream
        should.not.exist err

        done()

    it "should pipe data", (done) =>
      storage.createReadStream "image.jpg", (err, readStream) =>
        storage.createWriteStream "foo.jpg", (err, writeStream) =>
          readStream.pipe writeStream

          readStream.on "close", =>
            require("fs").unlinkSync __dirname + "/fixtures/foo.jpg"
            done()
