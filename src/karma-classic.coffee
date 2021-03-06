# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   hubot karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#   hubot karma top [n] - show the top n (default: 10)
#   hubot karma bottom [n] - show the bottom n (default: 10)
#
# Author:
#   D. Stuart Freeman (@stuartf) https://github.com/stuartf
#   Andy Beger (@abeger) https://github.com/abeger
#   Ravikiran Janardhana (@ravikiranj)


class Karma

    constructor: (@robot) ->
        @cache = {}

        @increment_responses = [
            "+1!", "gained a level!", "is on the rise!", "leveled up!"
        ]

        @decrement_responses = [
            "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
        ]

        @robot.brain.on 'loaded', =>
            if @robot.brain.data.karma
                @cache = @robot.brain.data.karma

    kill: (thing) ->
        delete @cache[thing]
        @robot.brain.data.karma = @cache

    increment: (thing) ->
        @cache[thing] ?= 0
        @cache[thing] += 1
        @robot.brain.data.karma = @cache

    decrement: (thing) ->
        @cache[thing] ?= 0
        @cache[thing] -= 1
        @robot.brain.data.karma = @cache

    incrementResponse: ->
        @increment_responses[Math.floor(Math.random() * @increment_responses.length)]

    decrementResponse: ->
        @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

    get: (thing) ->
        k = if @cache[thing] then @cache[thing] else 0
        return k

    sort: ->
        s = []
        for key, val of @cache
            s.push({ name: key, karma: val })
        s.sort (a, b) -> b.karma - a.karma

    top: (n = 10) =>
        sorted = @sort()
        sorted.slice(0, n)

    bottom: (n = 10) =>
        sorted = @sort()
        sorted.slice(-n).reverse()

module.exports = (robot) ->
    karma = new Karma robot
    decrementKarmaRegex = /@?(\S+[^-\s])\s?--(\s|$)/g
    incrementKarmaRegex = /@?(\S+[^+\s])\s?\+\+(\s|$)/g

    ###
    # Listen for "++" messages and increment
    ###
    robot.hear incrementKarmaRegex, (msg) ->
        for input in msg.match
            result = incrementKarmaRegex.exec(input)
            incrementKarmaRegex.lastIndex = 0
            if result? and result[1]?
                subject = result[1].toLowerCase()
                karma.increment subject
                msg.send "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"

    ###
    # Listen for "--" messages and decrement
    ###
    robot.hear decrementKarmaRegex, (msg) ->
        for input in msg.match
            result = decrementKarmaRegex.exec(input)
            decrementKarmaRegex.lastIndex = 0
            if result? and result[1]?
                subject = result[1].toLowerCase()
                # avoid catching HTML comments
                unless subject[-2..] == "<!"
                    karma.decrement subject
                    msg.send "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"

    ###
    # Function that handles top and bottom list
    # @param msg The message to be parsed
    # @param title The title of the list to be returned
    # @param rankingFunction The function to call to get the ranking list
    ###
    parseListMessage = (msg, title, rankingFunction) ->
        count = if msg.match.length > 1 then msg.match[1] else null
        verbiage = [title]
        if count?
            verbiage[0] = verbiage[0].concat(" ", count.toString())
        for item, rank in rankingFunction(count)
            verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
        msg.send verbiage.join("\n")

    ###
    # Listen for "karma top [n]" and return the top n rankings
    ###
    robot.respond /karma top\s*(\d+)?$/i, (msg) ->
        parseData = parseListMessage(msg, "The Best", karma.top)

    ###
    # Listen for "karma bottom [n]" and return the bottom n rankings
    ###
    robot.respond /karma bottom\s*(\d+)?$/i, (msg) ->
        parseData = parseListMessage(msg, "The Worst", karma.bottom)

    ###
    # Listen for "karma x" and return karma for x
    ###
    robot.respond /karma (\S+[^-\s])$/i, (msg) ->
        match = msg.match[1].toLowerCase()
        if not (match in ["top", "bottom"])
            msg.send "\"#{match}\" has #{karma.get(match)} karma."
