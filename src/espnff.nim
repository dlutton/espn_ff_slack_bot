import httpclient, json, asyncdispatch, strutils, espnffpkg/util, tables, asyncHttpServer, uri

var server = newAsyncHttpServer()

proc handler(req: Request) {.async.} =
  var client = newAsyncHttpClient()
  let headers = newHttpHeaders([("Content-Type","application/json")])
  client.headers = headers
  let url = "http://games.espn.com/ffl/api/v2/"
  var code = Http200
  var response: JsonNode
  var path: string
  let scoreboard_endpoint = "scoreboard"
  let roster_endpoint = "rosterInfo"
  # Replace seasonId and leagueId
  let
    seasonId = "xxxx"
    leagueId = "xxxxxx"
    # comma separated list of teamIds
    teamIds = "x,x,x"
  let scoreboard_params = "?leagueId=$1&seasonId=$2&matchupPeriodId=" % [leagueId, seasonId]
  let roster_params = "?leagueId=$1&seasonId=$2&teamIds=$3" % [leagueId, seasonId, teamIds]

  if req.url.path == "/scoreboard" and req.reqMethod == HttpPost:
    if isNilOrEmpty(req.body):
      response = handleError()
    else:
      try:
        let week = formData(req)["text"]
        path = url & scoreboard_endpoint & scoreboard_params & "$1" % week
      except KeyError:
        response = handleError()
      except:
        response = handleError()

      # make call to espn api client
      if not isNilOrEmpty(path):
        let espn = client.getContent(path)
        yield espn
        if espn.failed:
          response = handleError()
        else:
          # parse json response
          response = matchups(espn.read)
    # send response
    await req.respond(code, pretty(response), headers)
  elif req.url.path == "/roster" and req.reqMethod == HttpPost: 
    var team: string

    if isNilOrEmpty(req.body):
      response = handleError()
    else:
      try:
        team = toUpperAscii(decodeUrl(formData(req)["text"]))
        path = url & roster_endpoint & roster_params
      except KeyError: 
        response = handleError()
      except:
        response = handleError()

      # make call to espn api client
      if not isNilOrEmpty(path):
        let espn = client.getContent(path)
        yield espn
        if espn.failed:
          response = handleError()
        else:
          # parse json response
          response = roster(espn.read, team)
    # send response    
    await req.respond(code, pretty(response), headers)
  else:
    await req.respond(Http404, "Not Found")

waitFor server.serve(Port(80), handler)