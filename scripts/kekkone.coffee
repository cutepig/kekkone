# Description:
#   Urho Kaleva Kekkone. The president of Finland 1956-1982 and a chat bot.

class Vocabulary

  constructor: (@robot) ->
    @vocabulary = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.vocabulary
        @vocabulary = @robot.brain.data.vocabulary

  add: (category, word) ->
    @vocabulary[category] or= []
    @vocabulary[category].push word
    @robot.brain.data.vocabulary = @vocabulary
    word

  random: (msg, category) ->
    msg.random @vocabulary[category]

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

  vocabulary = new Vocabulary robot
  phrases = new Phrases robot

  robot.respond /add phrase (.*)/i, (msg) ->
    phrase = msg.match[1]
    phrases.add phrase
    msg.reply "Ok, osaan nyt lauseen \"#{phrase}\"."

  robot.respond /add word (\w+) (.*)/i, (msg) ->
    category = msg.match[1]
    word = msg.match[2]
    vocabulary.add category, word
    msg.reply "Ok, osaan nyt sanan \"#{word}\" kategoriassa \"#{category}\"."

  robot.respond /sano jotain/i, (msg) ->
    phrase = phrases.random(msg).replace /\{(\w+)\}/g, (match, category) ->
      vocabulary.random msg, category
    msg.send phrase

