agent = require "superagent"
crypto = require "crypto"
async = require "async"

class SwiftClient
  originalhost: ""
  host: ""
  user: ""
  pass: ""
  passhmac: ""
  passbase64: ""
  publicContainer: ""
  privateContainer: ""

  constructor: (options = {}) ->
    @options = options

    unless options.user
      throw new Error "No swift user specified"

    unless options.pass
      throw new Error "No swift password specified"

    unless options.host
      throw new Error "No swift host specified"

    unless options.container
      throw new Error "No swift container specified"

    @user = options.user
    @originalhost = options.host
    @pass = options.pass
    @passbase64 = new Buffer(@pass).toString('base64')
    @passhmac = crypto.createHmac("sha1", @pass).update(@pass).digest("base64")
    @container = options.container

  #The request object has a method "pipe" aswell, but is no real stream (no .on("data") etc.), its response object on the other hand is
  read: (name, callback) =>
    @exists name, (err, exists) =>
      if not err and not exists
        err = new Error "File #{name} does not exist!"

      return callback err if err

      container = @container
      url = [@host, container, name].join "/"

      request = agent.get(url)
        .set("Authorization", "S3 "+@user+"\:"+@passhmac)
        .set("x-auth-token", @passbase64)

      return callback null, request

  write: (name, callback) ->
    container = @container
    url = [@host, container, name].join "/"
    request = agent.put(url)
      .set("Authorization", "S3 "+@user+"\:"+@passhmac)
      .set("x-auth-token", @passbase64)
      .on "error", ->
        console.log "Error", arguments
    stream = request
    callback null, stream

  exists: (name, callback) =>
    container = @container
    url = [@host, container, name].join "/"
    agent.head(url)
      .set("Authorization", "S3 "+@user+"\:"+@passhmac)
      .set("x-auth-token", @passbase64)
      .end (err, res) =>
        if err
          console.error "Error HEAD: #{url}",
            url: url
            headers:
              "Authorization": "S3 "+@user+"\:"+@passhmac
              "x-auth-token": @passbase64

          return callback err

        if res?.ok
          callback null, true
        else if res.status is 404
          callback null, false
        else
          callback res.status, null

  size: (name, callback) ->
    container = @container
    url = [@host, container, name].join "/"
    req = agent.head(url)
      .set("Authorization", "S3 "+@user+"\:"+@passhmac)
      .set("x-auth-token", @passbase64)
      .on "error", (err) ->
        console.error "Authentication Error"
      .end (err, res)->
        if res?.ok
          size = parseInt res.header["content-length"], 10
          callback null, size
        else
          callback res.status, null

  destroy: (name, callback) ->
    container = @container
    url = [@host, container, name].join "/"
    agent.del(url)
      .set("Authorization", "S3 "+@user+"\:"+@passhmac)
      .set("x-auth-token", @passbase64)
      .end (err, res)->
        if res?.ok
          callback null
        else
          callback res.status

  fingerprint: (name, callback) ->
    container = @container
    url = [@host, container, name].join "/"

    req = agent.head(url)
      .set("Authorization", "S3 "+@user+"\:"+@passhmac)
      .set("x-auth-token", @passbase64)
      .end (err, res) ->
        if res?.ok
          callback null, res.header["etag"]
        else
          callback res.status, null

  #callback when the request is done, not when the readStream is done draining its data
  pipe: (name, readStream, callback) ->
    @write name, (err, writeStream) ->
      readStream.pipe writeStream

      writeStream.on "response", (res) ->
        callback()

  init: (cb) ->
    agent.get(@originalhost+"/auth/v1.0/")
      .set("X-Auth-User",@user)
      .set("X-Auth-Key",@pass)
      .end (err, res) =>
        if not res?.ok and res.header["x-auth-token"] and res.header["x-storage-url"]
          throw new Error "Could not authenticate"

        @host = res.header["x-storage-url"]

        cb() if cb
module.exports = SwiftClient
