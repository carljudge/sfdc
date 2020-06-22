/**
* @author: Carl Judge
* @date: 22-Jun-20
* @description: Class to replace the functionality of Auth.JWS and Auth.JWTBearerTokenExchange when using a private key instead of a certificate
**/

public class JWTPrivateKeyHelper {
    private Auth.JWT jwt;
    private Blob privateKey;
    private String tokenEndPoint;
    private String grantType = 'urn:ietf:params:oauth:grant-type:jwt-bearer';
    private HttpResponse response;
    private String compactSerialization;
    private String algorithm = 'RSA-SHA256';
    private Map<String, String> headers = new Map<String, String> {
        'typ' => 'JWT',
        'alg' => 'RS256'
    };

    public JWTPrivateKeyHelper(Auth.JWT jwt, String privateKey) {
        this.jwt = jwt;
        this.privateKey = EncodingUtil.base64Decode(privateKey.substringAfter('KEY-----').substringBefore('-----END'));
    }
    public JWTPrivateKeyHelper(Auth.JWT jwt, String privateKey, String tokenEndPoint) {
        this.jwt = jwt;
        this.privateKey = EncodingUtil.base64Decode(privateKey.substringAfter('KEY-----').substringBefore('-----END'));
        this.tokenEndPoint = tokenEndPoint;
    }

    public JWTPrivateKeyHelper setTokenEndpoint(String tokenEndPoint) {
        this.tokenEndPoint = tokenEndPoint;
        return this;
    }
    public JWTPrivateKeyHelper setGrantType(String grantType) {
        this.grantType = grantType;
        return this;
    }
    public JWTPrivateKeyHelper setAlgorithm(String grantType) {
        this.algorithm = algorithm;
        return this;
    }
    public JWTPrivateKeyHelper setHeader(String key, String val) {
        headers.put(key, val);
        return this;
    }

    public String getCompactSerialization() {
        if (compactSerialization == null) {
            generateCompactSerialization();
        }
        return compactSerialization;
    }
    public String getAccessToken() {
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(getHttpResponse().getBody());
        return (String)responseMap.get('access_token');
    }
    public String getGrantType() {
        return grantType;
    }
    public HttpResponse getHttpResponse() {
        if (response == null) {
            doCallout();
        }
        return response;
    }
    public String getTokenEndpoint() {
        return tokenEndPoint;
    }
    public String getAlgorithm() {
        return algorithm;
    }
    public Map<String, String> getHeaders() {
        return headers;
    }

    private void generateCompactSerialization() {
        String headersBase64 = Utils.base64UrlEncode(JSON.serialize(headers));
        String payloadBase64 = Utils.base64UrlEncode(jwt.toJSONString());
        Blob signatureBlob = Crypto.sign(algorithm, Blob.valueOf(headersBase64 + '.' + payloadBase64), privateKey);
        String signatureBase64 = Utils.base64UrlEncode(signatureBlob);
        compactSerialization = headersBase64 + '.' + payloadBase64 + '.' + signatureBase64;
    }

    private void doCallout() {
        if (tokenEndPoint == null) {
            throw new JWTPrivateKeyException('No token endpoint set for JWT request');
        }

        String bodyString = 'grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8') + '&assertion=' + getCompactSerialization();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(tokenEndPoint);
        req.setTimeout(120000);
        req.setBody(bodyString);
        Http http = new Http();
        response = http.send(req);
    }

    public class JWTPrivateKeyException extends Exception {}
}