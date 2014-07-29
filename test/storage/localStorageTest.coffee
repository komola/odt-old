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
