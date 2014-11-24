<?php
require_once 'yacuna.php'; 
// your api credentials
$tokenId = 'YOUR_API_TOKEN_ID';
$secret = 'YOUR_API_SECRET';
// set which platform to use (sandbox or production)
$sandbox = true; 
$url = $sandbox ? 'https://sandbox.yacuna.com' : 'https://yacuna.com';
$basePath = '/api/';
$sslverify = true;
$version = 1;
$debug = false;
$yacuna = new \Yacuna\YacunaAPI($tokenId, $secret, $url, $version, $sslverify, $basePath, $debug);

$wallet = $yacuna->Call('GET', 'wallet/get', ['currency'=>'EUR']);
print_r($wallet);

$order = array( 
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

ksort($order);
print_r($order);
#exit;

// Create Order
#$res = $yacuna->Call('POST', 'order/create/'.$order['currency1'].'/'.$order['currency2'], $order);
#print_r($res);

// Confirm Order
#$res = $yacuna->Call('POST', 'order/confirm/'.$res->tradeOrder->id, ['orderId'=>$res->tradeOrder->id]);
#print_r($res);

// Fetch my orders in status 'Confirmed'
$res = $yacuna->Call('GET', 'order/list', ['walletAccountId'=>$wallet->wallet->accounts[0]->walletAccountId, 'tradeOrderStatus'=>'Confirmed', 'count'=>1000]);
//print_r($res->tradeOrders);

foreach ($res->tradeOrders as $order) {
	print_r("Canceling order # " . $order->id . " ");
	$res = $yacuna->Call('POST', 'order/cancel/'.$order->id, ['orderId'=>$order->id]);
	print_r($res->tradeOrder->tradeOrderMarketStatus . "\n");
}

