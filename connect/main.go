package main

import (
	"errors"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

type (
	Request  events.APIGatewayWebsocketProxyRequest
	Response events.APIGatewayProxyResponse
)

func handler(req *Request) (Response, error) {
	if err := validateRequest(req); err != nil {
		return Response{StatusCode: http.StatusBadRequest}, err
	}

	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("REGION")),
	}))

	ddb := dynamodb.New(sess)

	connID := req.RequestContext.ConnectionID

	input := &dynamodb.PutItemInput{
		TableName: aws.String(os.Getenv("TABLE_NAME")),
		Item: map[string]*dynamodb.AttributeValue{
			"connectionId": {
				S: aws.String(connID),
			},
		},
	}

	if _, err := ddb.PutItem(input); err != nil {
		log.Printf("Error connecting: %v", err)
		return Response{StatusCode: http.StatusInternalServerError}, err
	}

	log.Printf("ID %s is connected", connID)

	return Response{StatusCode: http.StatusOK}, nil
}

func validateRequest(req *Request) error {
	if req.RequestContext.ConnectionID == "" {
		return errors.New("Connection ID is not provided")
	}

	if req.RequestContext.DomainName == "" && req.RequestContext.Stage == "" {
		return errors.New("Connection URL is not provided")
	}

	if os.Getenv("REGION") == "" || os.Getenv("TABLE_NAME") == "" {
		return errors.New("Environment variables are not provided")
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
