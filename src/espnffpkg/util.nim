import strutils, tables, asynchttpserver, json, times

type
  MultiData = Table[string, string]

  SlackResponseMatchups = ref object of RootObj
    response_type: string
    text: string
    attachments: seq[Attachments]

  SlackResponseRoster = ref object of RootObj
    response_type: string
    text: string
    attachments: array[1, JsonNode]

  Attachments = ref object of RootObj
    title: string
    text: string
    color: string
    fields: seq[Fields]

  Fields = ref object of RootObj
    title: string
    value: int
    short: bool

  Team = ref object of RootObj
    name: string
    score: int

proc parseBody(body: string): MultiData =
  let items = body.split('&')
  result = initTable[string, string]()
  for i in items:
    let values = i.split('=')
    result.add(values[0], values[1])

proc formData*(req: Request): MultiData =
  let contentType = req.headers.getOrDefault("Content-Type")
  if contentType.startsWith("application/x-www-form-urlencoded"):
    result = parseBody(req.body)

proc handleError*(): JsonNode =
  let error = %* {"text": "Sorry that didn't work. Please try again"}
  let
    e = getCurrentException()
    msg = getCurrentExceptionMsg()
  echo format(now(), "d MMMM yyyy HH:mm"), " : Got exception ", repr(e), " with message ", msg
  result = error

proc matchups*(response: string): JsonNode =
  let parse = parseJson(response)
  var team: Team
  var attachments: seq[Attachments]
  var fields: seq[Fields]

  attachments = @[]

  for m in parse["scoreboard"]["matchups"]:
    fields = @[]
    for t in m["teams"]:
      team = Team(name: "$1 $2" % [t["team"]["teamLocation"].getStr(),t["team"]["teamNickname"].getStr()], score: t["score"].getInt())
      fields.add(Fields(title: team.name, value: team.score, short: true))
    let winner = "Winner: $1" % m["winner"].getStr()
    attachments.add(Attachments(title: winner, text: "", color: "#5cacee", fields: fields))

  let week = "Week $1" % $parse["scoreboard"]["matchupPeriodId"].getInt()
  result = %* SlackResponseMatchups(responseType: "in_channel", text: week, attachments: attachments)

proc roster*(response: string, team: string): JsonNode =
  let parse = parseJson(response)
  var roster: string

  for t in parse["leagueRosters"]["teams"]:
    let team = replace(team,"’","'")
    if cmpIgnoreCase(team, "$1 $2" % [t["team"]["teamLocation"].getStr(), t["team"]["teamNickname"].getStr()]) == 0:
      roster = ""
      for s in t["slots"]:
        let firstName = s["player"]["firstName"].getStr()
        let lastName = s["player"]["lastName"].getStr()
        roster.add("$1 $2\n" % [firstName, lastName])
    
  let attachment = %* {
        "title": team,
        "text": roster,
        "color": "#5cacee"
  }
  var attachments: array[1, JsonNode]
  attachments[0] = attachment
  if isNilOrEmpty(roster):
    result = handleError()
  else:
    result = %* SlackResponseRoster(responseType: "in_channel", text: "Roster", attachments: attachments)
