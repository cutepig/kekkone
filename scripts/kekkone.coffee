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
    for category, words of @vocabulary
      categories.push category
    categories

  fillWords: (msg, phrase) ->
    phrase?.replace /\{(\w+)\}/g, (match, category) =>
      @random msg, category

  count: ->
    count = 0
    for category, words of @vocabulary
      count += words.length
    count

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
    phrase = msg.random @phrases
    if phrase
      @vocabulary.fillWords msg, phrase
    else
      'Saatanan tunarit!'

  count: ->
    @phrases.length

class Answers

  constructor: (@robot, @vocabulary) ->
    @answers = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.answers
        @answers = @robot.brain.data.answers

  add: (keyword, answer) ->
    @answers[keyword] or= []
    @answers[keyword].push answer
    @robot.brain.data.answers = @answers
    answer

  random: (msg) ->
    for keyword, answers of @answers
      if msg.message.text.match ///#{keyword}///i
        return @vocabulary.fillWords msg, msg.random(answers)
    if @answers['general']
      @vocabulary.fillWords msg, msg.random(@answers['general'])
    else
      'En minä tiiä!'

  count: ->
    count = 0
    for keyword, answers of @answers
      count += answers.length
    count

module.exports = (robot) ->

  vocabulary = new Vocabulary robot
  phrases    = new Phrases robot, vocabulary
  answers    = new Answers robot, vocabulary

  sayCounter = null

  robot.respond /add word (.*): (.*)/i, (msg) ->
    category = msg.match[1]
    word = msg.match[2]
    vocabulary.add category, word
    msg.reply "Ok, osaan nyt sanan `#{word}` kategoriassa `#{category}`."
    msg.finish()

  robot.respond /add phrase: (.*)/i, (msg) ->
    phrase = msg.match[1]
    phrases.add phrase
    msg.reply "Ok, osaan nyt lauseen `#{phrase}`."
    msg.finish()

  robot.respond /add answer (.*): (.*)/i, (msg) ->
    keyword = msg.match[1]
    answer = msg.match[2]
    answers.add keyword, answer
    msg.reply "Ok, osaan nyt vastauksen `#{answer}` kysymykseen `#{keyword}`."
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

  robot.respond /show stats/i, (msg) ->
    msg.send "Osaan `#{phrases.count()}` lausetta, " +
             "`#{answers.count()}` vastausta kysymyksiin ja " +
             "`#{vocabulary.count()}` sanaa."
    msg.finish()

  robot.hear /(kekkone|kekkos)/i, (msg) ->
    if msg.message.text.match /\?/
      msg.send answers.random(msg)
    else
      msg.send phrases.random(msg)

  robot.catchAll (msg) ->
    if sayCounter is 0
      # TODO: Also answer to questions here
      msg.send phrases.random(msg)
    if sayCounter in [0, null]
      sayCounter = Math.floor(Math.random() * (50 - 10) + 10)
    sayCounter--

