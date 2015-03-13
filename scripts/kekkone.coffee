module.exports = (robot) ->

  robot.hear /kekkone/i, (msg) ->
    msg.send 'Olen Urho Kaleva Kekkone :kekkonen:'

