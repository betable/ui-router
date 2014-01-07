require "setimmediate"

module.exports = makePromise = (fn) ->
  state = undefined
  finalState = undefined
  deferreds = []
  
  resolved = (fn) -> 
    return fn undefined if state is undefined
    return fn finalState if finalState?
    return resolve state, (resolvedState) -> fn finalState = resolvedState
  handle = (deferred, state) ->
    if not state? then deferreds.push deferred else setImmediate -> call deferred, state
  call = (deferred, [kept, value]) ->
    cb = if kept then deferred.whenKept else deferred.whenBroken
    if typeof cb is "function"
      return try deferred.cb null, cb value catch err then deferred.cb err, null, true
    if kept then deferred.cb null, value else deferred.cb value, null, true
  resultCB = (err, result, forceError=false) ->
    return unless state is undefined
    state = if err or forceError then [false, err] else [true, result]
    resolved (state) -> call deferred, state while deferred = deferreds.shift() 
  try fn resultCB catch error then resultCB error, null, true
  then: (whenKept, whenBroken) -> 
    if whenKept? and typeof whenKept is "object" and (whenKept.onFulfilled or whenKept.onRejected)
      whenBroken = whenKept.onRejected
      whenKept = whenKept.onFulfilled
    makePromise (cb) -> resolved (state) -> handle {whenKept, whenBroken, cb}, state

resolve = ([kept, value], cb) ->
  return cb [false, value] unless kept
  return cb [true, value] if not value or typeof value.then isnt "function"
  return value.then ((value) -> resolve [true, value], cb), (err) -> cb [false, err]