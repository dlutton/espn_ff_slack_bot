# espn_ff_slack_bot
Simple ESPN Fantasy Football Slack Bot

## Run Binary

- Replace leagueId and seasonId in src/espnff.nim
- Run nimble install from root of project to create binary

## Or Run with Docker

example:

    docker build -t espnff .
    docker run -p 80:80 espnff

## Slack

- Create a slack slash command and point it to host/scoreboard
- https://api.slack.com/slash-commands
- Example of a slash command: /scoreboard 1
- The Value after /scoreboard represents the week of the matchup
