class Phrases

  constructor: (@robot) ->
    @phrases = []
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.phrases
        @phrases = @robot.brain.data.phrases

  add: (phrase) ->
    @phrases.push phrase
    @robot.brain.data.phrases = @phrases
    phrase

  random: (msg) ->
    msg.random @phrases

module.exports = (robot) ->

  phrases = new Phrases robot

  robot.respond /add phrase (.*)/i, (msg) ->
    phrase = phrases.add msg.match[1]
    msg.send "Ok, nyt osaan sanoa \"#{phrase}\""

  robot.respond /sano jotain/i, (msg) ->
    msg.send phrases.random(msg)

