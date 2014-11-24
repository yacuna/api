<?php
namespace Yacuna;

class YacunaAPIException extends \ErrorException {};

class YacunaAPI
{
    protected $tokenId;     // API tokenId
    protected $secret;  // API secret
    protected $url;     // API base URL
    protected $basePath;     // API base path
    protected $version; // API version
    protected $curl;    // curl handle
    protected $debug;
    /**
     * Constructor 
     *
     * @param string $tokenId API key
     * @param string $secret API secret
     * @param string $url base URL 
     * @param string $version API version
     * @param bool $sslverify enable/disable SSL peer verification. 
     * @param string $basePath 
     */
    function __construct($tokenId, $secret, $url='https://yacuna.com', $version='1', $sslverify=true, $basePath='/api/', $debug=false)
    {
        /* check we have curl */
        if(!function_exists('curl_init')) {
         print "[ERROR] The API client requires that PHP is compiled with 'curl' support.\n";
         exit(1);
        }
        $this->tokenId = $tokenId;
        $this->secret = $secret;
        $this->url = $url;
        $this->version = $version;
	$this->basePath = $basePath;
	$this->debug = $debug;
        $this->curl = curl_init();
        curl_setopt_array($this->curl, array(
            CURLOPT_SSL_VERIFYPEER => $sslverify,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_USERAGENT => 'PHP API Agent',
            //CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true)
        );
    }
    function __destruct()
    {
    	if(function_exists('curl_close')) {
         curl_close($this->curl);
	}
    }

    /**
     */
    function Call($httpMethod, $restPath, array $request = array()) {
        $qry = http_build_query($request, '', '&');
	$body = '';
	if(isset($httpMethod) && $httpMethod == 'GET'){
		if(isset($qry)){ $restPath .= "?$qry"; }
	}
	else if(isset($httpMethod) && $httpMethod == 'POST'){
		$body = $qry;
		if($this->debug){ print_r($body . "\n"); }
	}

        $path = $this->basePath . $this->version . '/' . $restPath;
	$tokenSalt = $this->millitime();
	$hashInput = $tokenSalt.'@'.$this->secret.'@'.$httpMethod.'@'.$path;
	if($body != ''){ $hashInput .= '@'.$body; }
	$sign = $tokenSalt.'T'.(hash('sha512', $hashInput));

	if($this->debug){
		print_r($hashInput . "\n");
		print_r($sign . "\n");
	}
	
        $headers = array(
            'Api-Token-Id: ' . $this->tokenId,
            'API-Token: ' . $sign
        );

        // make request
        curl_setopt($this->curl, CURLOPT_URL, $this->url . $path);
        curl_setopt($this->curl, CURLOPT_HTTPHEADER, $headers);
	if($httpMethod == 'POST'){
		curl_setopt($this->curl, CURLOPT_POST, true);
        	curl_setopt($this->curl, CURLOPT_POSTFIELDS, $body);
	}
        $result = curl_exec($this->curl);
        if($result===false)
            throw new yacunaAPIException('CURL error: ' . curl_error($this->curl));
        // decode results
        $result = json_decode($result);
        //if(!is_array($result))
        //    throw new YacunaAPIException('JSON decode error');
        return $result;
    }

	function millitime() {
    		$mt = explode(' ', microtime());
    		return $mt[1] * 1000 + round($mt[0] * 1000);
	}
}

