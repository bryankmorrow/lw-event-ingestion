package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
	"log"
	"net/http"
	"os"
	"strings"
)

type LWEvent struct {
	EventTitle       string `json:"event_title"`
	EventLink        string `json:"event_link"`
	LaceworkAccount  string `json:"lacework_account"`
	EventSource      string `json:"event_source"`
	EventDescription string `json:"event_description"`
	EventTimestamp   string `json:"event_timestamp"`
	EventType        string `json:"event_type"`
	EventID          string `json:"event_id"`
	EventSeverity    string `json:"event_severity"`
}

type GChatMessage struct {
	Text string `json:"text"`
}

type Handler struct {
	Headers    map[string]string
	Data       interface{}
	Body       string
	StatusCode int
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var ApiResponse events.APIGatewayProxyResponse
	var h Handler
	if strings.Contains(request.Path, "ingestion/sns") {
		ApiResponse = h.SNS(request)
	} else if strings.Contains(request.Path, "ingestion/gchat") {
		ApiResponse = h.GChat(request)
	}

	return ApiResponse, nil
}

func (h *Handler) SNS(request events.APIGatewayProxyRequest) events.APIGatewayProxyResponse {
	var ApiResponse events.APIGatewayProxyResponse
	var lwevent LWEvent
	err := json.Unmarshal([]byte(request.Body), &lwevent)
	if err != nil {
		log.Println("error while unmarshalling the lw event body ", err)
	}
	// Send to SNS
	sess := session.Must(session.NewSession())
	client := sns.New(sess)
	subject := fmt.Sprintf("Lacework Alert: %s Severity: %s", lwevent.EventTitle, lwevent.EventSeverity)
	topicARN := os.Getenv("SNS_TOPIC")
	msg := sns.PublishInput{
		Message:  aws.String(request.Body),
		Subject:  aws.String(subject),
		TopicArn: aws.String(topicARN),
	}
	req, _ := client.PublishRequest(&msg)
	_ = req.Send()
	// Return the response
	headers := make(map[string]string)
	headers["Access-Control-Allow-Origin"] = "*"
	headers["Content-Type"] = "application/json"
	h.Headers = headers
	h.Body = "success"
	h.StatusCode = 200
	ApiResponse = events.APIGatewayProxyResponse{Headers: h.Headers, Body: h.Body, StatusCode: h.StatusCode}
	return ApiResponse
}

func (h *Handler) GChat(request events.APIGatewayProxyRequest) events.APIGatewayProxyResponse {
	var ApiResponse events.APIGatewayProxyResponse
	var lwevent LWEvent
	err := json.Unmarshal([]byte(request.Body), &lwevent)
	if err != nil {
		log.Println("error while unmarshalling the lw event body ", err)
	}
	// Post the webhook
	str := lwevent.toGChat()
	text, err := json.Marshal(GChatMessage{Text: str})
	if err != nil {
		log.Println("error while marshaling gchat message ", err)
	}
	gchat := os.Getenv("GCHAT_WEBHOOK")
	_, err = http.Post(gchat, "application/json",
		bytes.NewBuffer(text))

	if err != nil {
		log.Fatal(err)
	}

	// Return the response
	headers := make(map[string]string)
	headers["Access-Control-Allow-Origin"] = "*"
	headers["Content-Type"] = "application/json"
	h.Headers = headers
	h.Body = "success"
	h.StatusCode = 200
	ApiResponse = events.APIGatewayProxyResponse{Headers: h.Headers, Body: h.Body, StatusCode: h.StatusCode}
	return ApiResponse
}

func (l *LWEvent) toGChat() string {
	var str string
	str = fmt.Sprintf("Lacework Event Title: %s  Event Severity: %s\nEvent Source: %s  Event Description: %s\nEvent Link: %s\nTimestamp: %s",
		l.EventTitle, l.EventSeverity, l.EventSource, l.EventDescription, l.EventLink, l.EventTimestamp)
	return str
}
