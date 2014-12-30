<?php
require_once 'yacuna.php'; 
// your api credentials
$tokenId = 'YOUR_API_TOKEN_ID';
$secret = 'YOUR_API_SECRET';
$sandbox = false; // set which platform to use (sandbox or production)
$sslverify = true;
$version = 1;
$debug = false;

$url = $sandbox ? 'https://sandbox.yacuna.com' : 'https://yacuna.com';
$basePath = '/api/';
$yacuna = new \Yacuna\YacunaAPI($tokenId, $secret, $url, $version, $sslverify, $basePath, $debug);

$wallet = $yacuna->Call('GET', 'wallet/get', ['currency'=>'EUR']);
print_r($wallet);

//getOrders($wallet->wallet->accounts[0]->walletAccountId);
getDeals($wallet->wallet->accounts[0]->walletAccountId);

$ordr = array( 
	'walletAccountId' => $wallet->wallet->accounts[0]->walletAccountId,
	'externalReferenceId' => 'olala.'.microtime(true),
	'currency1' => 'EUR',
	'currency2' => 'XBT',
	'tradeOrderType' => 'BuyLimit',
	'sellAmount' => '',
	'sellCurrency' => 'EUR',
	'buyAmount' => 1,
	'buyCurrency' => 'XBT',
	'priceLimitAmount' => 300,
	'priceLimitCurrency' => 'EUR'
);

function placeOrder($order){
    global $yacuna;
    ksort($order);
    print_r($order);
    
    // Create Order
    $res = $yacuna->Call('POST', 'order/create/'.$order['currency1'].'/'.$order['currency2'], $order);
    print_r($res);

    // Confirm Order
    $res = $yacuna->Call('POST', 'order/confirm/'.$res->tradeOrder->id, ['orderId'=>$res->tradeOrder->id]);
    print_r($res);
    return $res;
}

function getOrders($walletAccountId){
    // Fetch my orders in status 'Confirmed'
    $res = $yacuna->Call('GET', 'order/list', ['walletAccountId'=>$walletAccountId, 'tradeOrderStatus'=>'Confirmed', 'count'=>1000]);
    //print_r($res->tradeOrders);

    foreach ($res->tradeOrders as $order) {
	    print_r($order->id . "\n");
    }
}

function getDeals($walletAccountId){
    global $yacuna;
    $res = $yacuna->Call('GET', 'deal/list', ['walletAccountId'=>$walletAccountId, 'count'=>1000, 'sorting'=>'+CreationDateTime|+Id']);
    print_r($res);
}

