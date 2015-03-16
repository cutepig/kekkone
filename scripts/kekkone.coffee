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

  delete: (category, word) ->
    for w in @vocabulary[category] or []
      if w is word
        @vocabulary[category].splice w, 1
        delete @vocabulary[category] unless @vocabulary[category].length
        return word
    null

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

  delete: (phrase) ->
    for p in @phrases
      if p is phrase
        @phrases.splice p, 1
        return phrase
    null

  random: (msg) ->
    phrase = msg.random @phrases
    if phrase
      @vocabulary.fillWords msg, phrase
    else
      'Morons!'

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

  delete: (keyword, answer) ->
    for a in @answers[keyword] or []
      if a is answer
        @answers[keyword].splice a, 1
        delete @answers[keyword] unless @answers[keyword].length
        return answer
    null

  random: (msg) ->
    for keyword, answers of @answers
      if msg.message.text.match ///#{keyword}///i
        return @vocabulary.fillWords msg, msg.random(answers)
    if @answers['general']
      @vocabulary.fillWords msg, msg.random(@answers['general'])
    else
      'Beats me?'

  count: ->
    count = 0
    for keyword, answers of @answers
      count += answers.length
    count

class Kekkone

  constructor: (@robot) ->
    @vocabulary = new Vocabulary @robot
    @phrases = new Phrases @robot, @vocabulary
    @answers = new Answers @robot, @vocabulary
    @talkInterval = null

  start: ->
    @robot.respond /add word (.*): (.*)/i, (msg) =>
      @addWord msg, msg.match[1], msg.match[2]
    @robot.respond /add phrase: (.*)/i, (msg) =>
      @addPhrase msg, msg.match[1]
    @robot.respond /add answer (.*): (.*)/i, (msg) =>
      @addAnswer msg, msg.match[1], msg.match[2]

    @robot.respond /delete word (.*): (.*)/i, (msg) =>
      @deleteWord msg, msg.match[1], msg.match[2]
    @robot.respond /delete phrase: (.*)/i, (msg) =>
      @deletePhrase msg, msg.match[1]
    @robot.respond /delete answer (.*): (.*)/i, (msg) =>
      @deleteAnswer msg, msg.match[1], msg.match[2]

    @robot.respond /show categories/i, (msg) =>
      @showCategories msg
    @robot.respond /show stats/i, (msg) =>
      @showStats msg

    @robot.hear /(kekkone|kekkos)/i, (msg) =>
      @talk msg

    @robot.catchAll (msg) =>
      if @talkInterval is 0
        @talk msg
      if @talkInterval in [0, null]
        @talkInterval = Math.floor(Math.random() * (50 - 10) + 10)
      @talkInterval--

  talk: (msg) ->
    if msg.message.text.match /\?/
      msg.send @answers.random(msg)
    else
      msg.send @phrases.random(msg)
    msg.finish()

  addWord: (msg, category, word) ->
    @vocabulary.add category, word
    msg.send "Added word '#{word}' to a category '#{category}'."
    msg.finish()

  addPhrase: (msg, phrase) ->
    @phrases.add phrase
    msg.send "Added phrase '#{phrase}'."
    msg.finish()

  addAnswer: (msg, keyword, answer) ->
    @answers.add keyword, answer
    msg.send "Added answer '#{answer}' for a keyword '#{keyword}'."
    msg.finish()

  deleteWord: (msg, category, word) ->
    if @vocabulary.delete category, word
      msg.send "Deleted word '#{word}'."
    else
      msg.send 'Not found.'
    msg.finish()

  deletePhrase: (msg, phrase) ->
    if @phrases.delete phrase
      msg.send "Deleted phrase '#{phrase}'."
    else
      msg.send 'Not found.'
    msg.finish()

  deleteAnswer: (msg, keyword, answer) ->
    if @answers.delete keyword, answer
      msg.send "Deleted answer '#{answer}'."
    else
      msg.send 'Not found.'
    msg.finish()

  showCategories: (msg) ->
    text = 'I know the following word categories: '
    first = true
    for category in @vocabulary.categories()
      text += ', ' unless first
      text += "`#{category}`"
      first = false
    msg.send text
    msg.finish()

  showStats: (msg) ->
    msg.send "I know `#{@phrases.count()}` phrases, " +
             "`#{@answers.count()}` answers and " +
             "`#{@vocabulary.count()}` word."
    msg.finish()

module.exports = (robot) ->
  kekkone = new Kekkone robot
  kekkone.start()

