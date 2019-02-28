@IsTest class SnsTest {
    
    @IsTest static void testSuccess() {
        
        //arrange
        Sns sns = new Connector('AccessKey', 'SecretKey').sns('Region');
        
        //act
        Test.setMock(HttpCalloutMock.class, new PublishSuccess());
        Sns.PublishResponse response = sns.publish('TopicArn', 'Payload');
        
        //assert
        System.assertEquals('f24d0373-7dde-58fd-9559-57295091b79f', response.ResponseMetadata.RequestId);
    }
    
    @IsTest static void testFailure() {
        
        //arrange
        Sns sns = new Connector('AccessKey', 'SecretKey').sns('Region');
        
        try {
            //act
            Test.setMock(HttpCalloutMock.class, new PublishFailure());
            sns.publish('TopicArn', 'Payload');
            System.assert(false, 'wrong exception');
        } catch (Sns.ErrorResponseException e) {
            //assert
            System.assertEquals('Sender', e.Error.Type);
            System.assertEquals('NotFound', e.Error.Code);
            System.assertEquals('Topic does not exist', e.Error.Message);
            System.assertEquals('113bc8ab-5044-5c3f-946a-9cf17a58541c', e.RequestId);
        }
    }
    
    class PublishFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setBody(''
                + '<ErrorResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">'
                + '    <Error>'
                + '        <Type>Sender</Type>'
                + '        <Code>NotFound</Code>'
                + '        <Message>Topic does not exist</Message>'
                + '    </Error>'
                + '    <RequestId>113bc8ab-5044-5c3f-946a-9cf17a58541c</RequestId>'
                + '</ErrorResponse>'
            );
            return response;
        }
    }
    
    class PublishSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(''
                + '<PublishResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">'
                + '    <PublishResult>'
                + '        <MessageId>0ab2de57-b693-5789-b30a-8a0d9bdc78eb</MessageId>'
                + '    </PublishResult>'
                + '    <ResponseMetadata>'
                + '        <RequestId>f24d0373-7dde-58fd-9559-57295091b79f</RequestId>'
                + '    </ResponseMetadata>'
                + '</PublishResponse>'
            );
            return response;
        }
    }
    
    final static String testService = 'service';
    final static String testRegion = 'us-east-1';
    final static String testAccessKey = 'AKIDEXAMPLE';
    final static String testSecretKey = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY';
    final static Datetime testNow = Datetime.newInstanceGmt(2015, 08, 30, 12, 36, 00);
    
    static Connector connector()
    {
        //arrange
        Connector connector = new Connector(testAccessKey, testSecretKey);
        connector.now = testNow;
        connector.region = testRegion;
        connector.service = testService;
        return connector;
    }
    
    static HttpResponse testResponse;
    
    public class SignatureMock implements HttpCalloutMock
    {
        public HttpResponse respond(HttpRequest request)
        {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getHeader('Authorization').substringAfter('Signature='));
            testResponse = response;
            return response;
        }
    }
    
    @IsTest static void testTripleByteUnicodes() {
        
        //act
        try
        {
            Test.setMock(HttpCalloutMock.class, new SignatureMock());
            connector().sns(testRegion).publish('TopicArn', '😅');
        }
        catch (Exception e)
        {
            //suppress errors, just get static
        }
        
        //assert
        String actual = testResponse.getBody();
        String expected = '9f7085c2b5f7e9abb2884c984c8b279a6058b0654c23c33164abc39f586f8176';
        System.assertEquals(expected, actual, 'wrong signature');
    }
    
}