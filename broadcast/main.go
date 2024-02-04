package main

import (
	"errors"
	"log"
	"net/http"
	"net/url"
	"os"
	"sync"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/apigatewaymanagementapi"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

type (
	Request  events.APIGatewayWebsocketProxyRequest
	Response events.APIGatewayProxyResponse
)

var wg sync.WaitGroup

func handler(req *Request) (Response, error) {
	if err := validateRequest(req); err != nil {
		return Response{StatusCode: http.StatusBadRequest}, err
	}

	var endpoint url.URL

	endpoint.Scheme = "https"
	endpoint.Host = req.RequestContext.DomainName
	endpoint.Path = req.RequestContext.Stage

	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(os.Getenv("REGION")),
	}))

	ddb := dynamodb.New(sess)
	api := apigatewaymanagementapi.New(
		sess,
		aws.NewConfig().WithEndpoint(endpoint.String()),
	)

	input := &dynamodb.ScanInput{
		TableName: aws.String(os.Getenv("TABLE_NAME")),
	}

	result, err := ddb.Scan(input)
	if err != nil {
		log.Printf("Error getting connections: %v", err)
		return Response{StatusCode: http.StatusInternalServerError}, err
	}

	errChan := make(chan error, len(result.Items))

	for _, item := range result.Items {
		item := item
		wg.Add(1)

		go func() {
			defer wg.Done()

			connID := item["connectionId"].S
			input := &apigatewaymanagementapi.PostToConnectionInput{
				ConnectionId: connID,
				Data:         []byte(req.Body),
			}

			if _, err := api.PostToConnection(input); err != nil {
				errChan <- err
				return
			}

			log.Printf("Broadcasted to %s", *connID)
		}()
	}

	wg.Wait()
	close(errChan)

	for err := range errChan {
		if err != nil {
			log.Printf("Error broadcasting: %v", err)
			return Response{StatusCode: http.StatusInternalServerError}, err
		}
	}

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
