This lambda function currently accepts Lacework events as webhooks to the following routes:
 - ingestion/sns
 - ingestion/gchat

You will need an API gateway to route POST requests to those paths.

Also need the following environment variables:
- SNS -> `SNS_TOPIC = arn:topic/for/events`
- GCHAT -> `GCHAT_WEBHOOK = https://chat.googleapis.com/v1/spaces/etc/etc`

Go build the lambda zip file:

`GOOS=linux CGO_ENABLED=0 go build main.go && zip function.zip main`