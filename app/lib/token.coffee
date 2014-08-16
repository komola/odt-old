_ = require "lodash"
crypto = require "crypto"

module.exports =
  create: (parameters, secret = "") =>
    keys = _.keys(parameters).sort()

    string = ""
    string += parameters[key] for key in keys

    string += secret

    return crypto.createHash("md5").update(string).digest "hex"
