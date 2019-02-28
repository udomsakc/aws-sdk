global class Sns {
    
    global class ErrorResponseException extends Exception {
        global String RequestId;
        global Error Error = new Error();
        public ErrorResponseException(Dom.Document dom) {
            Dom.XmlNode root = dom.getRootElement();
            String ns = root.getNamespace();
            this.RequestId = root.getChildElement('RequestId', ns).getText();
            this.Error.Type = root.getChildElement('Error', ns).getChildElement('Type', ns).getText();
            this.Error.Code = root.getChildElement('Error', ns).getChildElement('Code', ns).getText();
            this.Error.Message = root.getChildElement('Error', ns).getChildElement('Message', ns).getText();
            this.setMessage(this.Error.Type + ' ' + this.Error.Code + ' ' + this.Error.Message + ' ' + this.RequestId);
        }
    }

    global class Error {
        global String Type;
        global String Code;
        global String Message;
    }

    global class PublishResponse {
        global PublishResult PublishResult = new PublishResult();
        global ResponseMetadata ResponseMetadata = new ResponseMetadata();
        public PublishResponse(Dom.Document dom) {
            Dom.XmlNode root = dom.getRootElement();
            String ns = root.getNamespace();
            Dom.XmlNode publishResult = root.getChildElement('PublishResult', ns);
            Dom.XmlNode responseMetadata = root.getChildElement('ResponseMetadata', ns);
            this.PublishResult.MessageId = publishResult.getChildElement('MessageId', ns).getText();
            this.ResponseMetadata.RequestId = responseMetadata.getChildElement('RequestId', ns).getText();
        }
    }

    global class ResponseMetadata {
        global String RequestId;
    }

    global class PublishResult {
        global String MessageId;
        
    }
    
    Connector connector;
    global Sns(Connector connector, String region) {
        this.connector = connector;
        if (region != null) this.connector.region = region;
        this.connector.service = 'sns'; //Credential should be scoped to correct service
    }

    global PublishResponse publish(String topicArn, Object payload) {
        
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestURI = 'https://sns.' + this.connector.region + '.amazonaws.com/';
        request.addHeader('Content-Type', 'application/x-www-form-urlencoded');

        /**
         * The following example publishes a different messages to each protocol. Message:
         * {
         *     "default": "some message",
         *     "email": "some email message",
         *     "email-json": "some email-json message",
         *     "http": "some http message",
         *     "https": "some https message",
         *     "sqs": "some sqs message"
         * }
         */
        PageReference body = new PageReference('/');
        body.getParameters().put('Action', 'Publish');
        body.getParameters().put('TopicArn', topicArn);
        body.getParameters().put('MessageStructure', 'json');
        body.getParameters().put('Message', Json.serialize(new Map<String,Object>{
            'default' => Json.serialize(payload)
        }));
        
        request.requestBody = Blob.valueOf(body.getUrl().substringAfter('?'));
        HttpResponse response = this.connector.send(request);
        if (response.getStatusCode() != 200)
        {
            throw new ErrorResponseException(response.getBodyDocument());
        }
        
        /**
         * Unique identifier assigned to the published message.
         * When a messageId is returned, the message has been saved
         * and Amazon SNS will attempt to deliver it shortly.
         */
        return new PublishResponse(response.getBodyDocument());
    }
    
}