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
    if @vocabulary[category]
      msg.random @vocabulary[category]
    else
      "{#{category}}"

  categories: ->
    categories = []
    for key, value of @vocabulary
      categories.push key
    categories

class Phrases

  constructor: (@robot, @vocabulary) ->
    @phrases = []
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.phrases
        @phrases = @robot.brain.data.phrases

  add: (phrase) ->
    @phrases.push phrase
    @robot.brain.data.phrases = @phrases
    phrase

  random: (msg) ->
    phrase = msg.random(@phrases)?.replace /\{(\w+)\}/g, (match, category) =>
      @vocabulary.random msg, category
    phrase or 'Saatanan tunarit!'

module.exports = (robot) ->

  vocabulary = new Vocabulary robot
  phrases = new Phrases robot, vocabulary
  sayCounter = null

  robot.respond /add phrase (.*)/i, (msg) ->
    phrase = msg.match[1]
    phrases.add phrase
    msg.reply "Ok, osaan nyt lauseen `#{phrase}`."
    msg.finish()

  robot.respond /add word (\w+) (.*)/i, (msg) ->
    category = msg.match[1]
    word = msg.match[2]
    vocabulary.add category, word
    msg.reply "Ok, osaan nyt sanan `#{word}` kategoriassa `#{category}`."
    msg.finish()

  robot.respond /show categories/i, (msg) ->
    text = 'Osaan seuraavat sanakategoriat: '
    first = true
    for category in vocabulary.categories()
      text += ', ' unless first
      text += "`#{category}`"
      first = false
    msg.send text
    msg.finish()

  robot.hear /(kekkone|kekkos)/i, (msg) ->
    msg.send phrases.random(msg)

  robot.catchAll (msg) ->
    if sayCounter is 0
      msg.send phrases.random(msg)
    if sayCounter in [0, null]
      sayCounter = Math.floor(Math.random() * (50 - 10) + 10)
    sayCounter--

