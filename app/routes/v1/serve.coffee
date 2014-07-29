express = require "express"
router = express.Router()

router.get "/:width/:height/:path", (req, res, next) =>
  res.send "Yes!"

module.exports = router
