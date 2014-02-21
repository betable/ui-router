path = require "path"
exec = require "../"
assert = require "assert"

coffee = path.resolve __dirname, "../node_modules/.bin/coffee"
failureScript = path.resolve __dirname, "../scripts/failure.coffee"
successScript = path.resolve __dirname, "../scripts/success.coffee"

describe "exec", ->
  describe "when program executing fails", ->
    it "fails while making both stdout and stderr available", (next) ->
      exec("#{coffee} #{failureScript}")
        .then ->
          next new Error "Exec shouldn't have succeeded."
        .then null, (err) ->
          assert.equal err.stdout, "Output on stdout.\n"
          assert.equal err.stderr, "Output on stderr.\n"
          assert.equal err.code, 1
          assert.equal err.killed, false
          next null
        .then null, (err) ->
          next err
  
  describe "when program executing succeeds", ->
    it "succeeds while making both stdout and stderr available", (next) ->
      exec("#{coffee} #{successScript}")
        .then (result) ->
          assert.equal result.stdout, "Output on stdout.\n"
          assert.equal result.stderr, "Output on stderr.\n"
          next null
        .then null, (err) ->
          next err