parser = require "../../app/lib/parametersParser"

describe "Parameters Parser", ->
  describe "#tokenize", ->
    it "should not crash on empty parameters", ->
      result = parser.tokenize("")

      should.not.exist result

    it "should detect filters", ->
      result = parser.tokenize("filters:watermark(foo.jpg, 0, 0, 0)")

      result.filters.length.should.equal 1
      result.filters[0].should.equal "watermark(foo.jpg, 0, 0, 0)"

    it "should detect multiple filters", ->
      result = parser.tokenize("filters:watermark(foo.jpg, 0, 0, 0),watermark(asd.jpg,0,0,0)")

      result.filters.length.should.equal 2

  describe "#parseFilters", ->
    it "should normalize attributes", ->
      a = parser.parseFilter("watermark(foo.jpg, 0, 0, 0)")
      b = parser.parseFilter("watermark(foo.jpg,0,0,0)")

      a.should.eql b

    it "should parse the filter attributes", ->
      a = parser.parseFilter("watermark(foo.jpg, 0, 0, 0)")

      a.should.eql
        type: "watermark"
        attributes: ["foo.jpg", "0", "0", "0"]

  describe "#parse", ->
    it "should ignore unknown filters", ->
      a = parser.parse("filters:foobar(foo.jpg, 0, 0, 0)")

      a.should.eql
        filters: []

    describe "watermark", ->
      it "should resolve watermark attributes", ->
        a = parser.parse("filters:watermark(foo.jpg, 0, 0, 0)")

        a.should.eql
          filters: [
            {
              type: "watermark"
              attributes: ["foo.jpg", "0", "0", "0"]
              file: "foo.jpg"
              x: 0
              y: 0
              opacity: 0
            }
          ]

      it "should detect watermark(foo.jpg, 0, cover)", ->
        a = parser.parse("filters:watermark(foo.jpg, 0, cover)")

        a.should.eql
          filters: [
            {
              type: "watermark"
              attributes: ["foo.jpg", "0", "cover"]
              file: "foo.jpg"
              opacity: 0
              behavior: "cover"
            }
          ]

      it "should detect watermark(foo.jpg, 0, center)", ->
        a = parser.parse("filters:watermark(foo.jpg, 0, center)")

        a.should.eql
          filters: [
            {
              type: "watermark"
              attributes: ["foo.jpg", "0", "center"]
              file: "foo.jpg"
              opacity: 0
              behavior: "center"
            }
          ]

      it "should detect watermark(foo.jpg, 0, tile)", ->
        a = parser.parse("filters:watermark(foo.jpg, 0, tile)")

        a.should.eql
          filters: [
            {
              type: "watermark"
              attributes: ["foo.jpg", "0", "tile"]
              file: "foo.jpg"
              opacity: 0
              behavior: "tile"
            }
          ]

      it "should only allow valid behaviors", ->
        a = parser.parse("filters:watermark(foo.jpg, 0, foobar)")

        a.should.eql
          filters: []
