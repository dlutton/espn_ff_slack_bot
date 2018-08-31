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
  let endpoint = "scoreboard"
  # Replace seasonId and leagueId
  let
    seasonId = "xxxx"
    leagueId = "xxxxxx"
  let params = "?leagueId=$1&seasonId=$2&matchupPeriodId=" % [leagueId, seasonId]

  if req.url.path == "/scoreboard" and req.reqMethod == HttpPost:
    if isNilOrEmpty(req.body):
      response = handleError()
    else:
      try:
        let week = formData(req)["text"]
        path = url & endpoint & params & "$1" % week
      except KeyError:
        response = handleError()
      except:
        response = handleError()

      # make call to espn api client
      if not isNilOrEmpty(path):
        var espn = client.getContent(path)
        yield espn
        if espn.failed:
          response = handleError()
        else:
          # parse json response
          response = matchups(espn.read)
    # send response
    await req.respond(code, pretty(response), headers)
  else:
    await req.respond(Http404, "Not Found")

waitFor server.serve(Port(80), handler)