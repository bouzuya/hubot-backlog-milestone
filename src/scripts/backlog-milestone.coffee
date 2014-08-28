# Description
#   A Hubot script that backlog-milestone
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_BACKLOG_MILESTONE_SPACE_ID
#   HUBOT_BACKLOG_MILESTONE_API_KEY
#
# Commands:
#   hubot backlog-milestone - backlog-milestone
#
# Author:
#   bouzuya <m@bouzuya.net>
#
module.exports = (robot) ->
  require('hubot-arm') robot
  moment = require 'moment'

  spaceId = process.env.HUBOT_BACKLOG_MILESTONE_SPACE_ID
  apiKey = process.env.HUBOT_BACKLOG_MILESTONE_API_KEY
  baseUrl = "https://#{spaceId}.backlog.jp"

  robot.respond /backlog-milestone\s+(.+)/i, (res) ->
    projectKey = res.match[1].toUpperCase()
    projectId = null
    milestoneId = null
    res.robot.arm('request')(
      method: 'GET'
      url: "#{baseUrl}/api/v2/projects/#{projectKey}"
      qs:
        apiKey: apiKey
      format: 'json'
    ).then (r) ->
      projectId = r.json.id
      res.robot.arm('request')(
        method: 'GET'
        url: "#{baseUrl}/api/v2/projects/#{projectKey}/versions"
        qs:
          apiKey: apiKey
        format: 'json'
      )
    .then (r) ->
      today = moment()
      milestone = r.json.filter((i) ->
        start = moment(i.startDate).startOf('day')
        end = moment(i.releaseDueDate).endOf('day')
        today.isAfter(start) and today.isBefore(end)
      )[0]
      return unless milestone?
      res.robot.arm('request')(
        method: 'GET'
        url: "#{baseUrl}/api/v2/issues"
        qs:
          'projectId': [projectId]
          'milestoneId': [milestone.id]
          'statusId': [1, 2, 3]
          apiKey: apiKey
        format: 'json'
      )
    .then (r) ->
      message = r.json.map (issue) ->
        "#{issue.issueKey} #{issue.summary}"
      .join '\n'
      res.send message
