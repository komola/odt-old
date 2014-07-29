BaseStorage = require "../app/storage/base"
storage = new BaseStorage

describe "BaseStorage", ->
  describe "#calculateHash", ->
    it "should generate a hash for a filename", ->
      hash = storage.calculateHash "foo.jpg"

      hash.should.equal "d271cbfe95ae3584ade8cac317193995"
