makePromise = require "./make-promise"

module.exports = 
  pending: ->
    pending = {}
    pending.promise = makePromise (cb) ->
      pending.fulfill = (value) -> cb null, value
      pending.reject = (error) -> cb error, null, true
    pending
