This lambda function currently accepts Lacework events as webhooks to the following routes:

[![IaC](https://app.soluble.cloud/api/v1/public/badges/6cc2b689-5b56-430b-b7e7-51c5dce5f43b.svg)](https://app.soluble.cloud/repos/details/github.com/bryankmorrow/lw-event-ingestion)  
 - ingestion/sns
 - ingestion/gchat

You will need an API gateway to route POST requests to those paths.

Also need the following environment variables:
- SNS -> `SNS_TOPIC = arn:topic/for/events`
- GCHAT -> `GCHAT_WEBHOOK = https://chat.googleapis.com/v1/spaces/etc/etc`

Go build the lambda zip file:

`GOOS=linux CGO_ENABLED=0 go build main.go && zip function.zip main`