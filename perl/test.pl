#!/usr/bin/perl

use strict;
no strict 'subs';
use warnings;

use Data::Dumper;
use Data::Dump qw(dump);
use JSON;
use Error qw(:try);
use Finance::Bitcoin::Yacuna;
use Math::BigFloat;
use Time::HiRes qw(time);

my $json = new JSON;
my $yacuna = {};

my $config = {
	yacuna => {
		trader => {
			apiTokenId => 'AAEAAAgfi0Ng9mYQs0kvyX50NtWxRojXUOuGeamOQjWspHCt0MsxiY9q',
			apiSecret => '92973690bb906eca2fdf05923aa8f231'
		}
	}
};

main->run();

sub run{
	try{
		# yacuna provides in wallet accounts per currency
		# connects to yacuna API and pulls the wallet accounts into $config
		&init();
		dump $config;

		# iterate through the available wallet accounts
		foreach my $acc (@{$config->{'yacuna'}->{'trader'}->{'accounts'}}){
			# create order for EUR balance
			if($acc->{'accountBalance'}->{'balance'}->{'currency'} eq 'EUR'){ 
				my @orders = &calculateOrders($acc);
				&placeOrders(@orders);
			}
		}
	}
	catch Error::Simple with{
		dump(shift);
	};
	exit(0);
}

sub calculateOrders(){
	my ($acc) = @_;
	my @orders = ();	
	if($acc->{'accountBalance'}->{'balance'}->{'currency'} eq 'EUR'){ # selling eur
		# use 1/10 of available money
		#my $toSpend = Math::BigFloat->new($acc->{'accountBalance'}->{'balance'}->{'amount'})->bdiv(Math::BigFloat->new('10'));

		# set the buy limit as current-market_price/2
		#my $price = &getPrice('EUR','DOGE')->{'bid'}->copy()->bmul(Math::BigFloat->new('0.5'));
		#$price->precision(-8);

		# calculate amount to buy
		#my $buyAmount = $toSpend->copy()->bdiv($price);
		#$buyAmount->precision(-8);

		my $order = { 
			walletAccountId => $acc->{'walletAccountId'},
			externalReferenceId => 'olala.1',
			currency1 => 'EUR',
			currency2 => 'XBT',
			tradeOrderType => 'BuyLimit',
			sellAmount => '',
			sellCurrency => 'EUR',
			buyAmount => '1',
			buyCurrency => 'XBT',
			priceLimitAmount => '300',
			priceLimitCurrency => 'EUR'
		};
		push @orders, $order;
	}

	return @orders;
}

sub getPrice(){
	my ($currency1, $currency2) = @_;
	my $orderbook = $json->decode($yacuna->call('GET', 'orderbook/get/'.$currency1.'/'.$currency2, ['currency1='.$currency1, 'currency2='.$currency2,]));	
	return { 
		ask => Math::BigFloat->new($orderbook->{'orderBook'}->{'asks'}->[0]->[0]), 
		bid => Math::BigFloat->new($orderbook->{'orderBook'}->{'bids'}->[0]->[0])
	};	
}

sub placeOrders(){
	my (@orders) = @_;

	dump @orders; 
	print "\n". scalar @orders . "\n"; 
	#return;

	foreach my $order(@orders){
		my $result = &createOrderYacuna($order); 
		my $confirmed = {};
		try{
			my $o = $json->decode($result);
			$confirmed = &confirmOrderYacuna($o->{'tradeOrder'}->{'id'}) if $o->{'tradeOrder'}->{'id'};
			print "\n ". $json->pretty->encode($json->decode($confirmed));
		}
		catch Error::Simple with{
			dump($result);
			dump($confirmed);
			throw Error::Simple(shift);
		};
		sleep 1;
	}
}

sub listOrdersYacuna(){
	my($walletAccountId, $status) = @_;	
	my %orders = ();
	my $result = $yacuna->call('GET', 'order/list', ["walletAccountId=$walletAccountId", "tradeOrderStatus=$status", "count=1000"]);
	%orders = map { (split('X',$_->{'externalReferenceId'}))[0] => $_ } @{$json->decode($result)->{'tradeOrders'}};
	my $startWith = 0;
	while ($json->decode($result)->{'pagingInfo'}->{'showNext'} eq 'true'){
		$startWith += int $json->decode($result)->{'pagingInfo'}->{'actualCount'};
		$result = $yacuna->call('GET', 'order/list', ["walletAccountId=$walletAccountId", "tradeOrderStatus=$status", "count=1000", "startWith=$startWith"]);
		my %nextOrds = map { (split('X',$_->{'externalReferenceId'}))[0] => $_ } @{$json->decode($result)->{'tradeOrders'}};
		@orders{keys %nextOrds} = values %nextOrds;
	}
	return %orders;
}

sub cancelOrderYacuna(){
	my($order) = @_;
	print "canceling ". $order->{'externalReferenceId'} ." " .$order->{'tradeOrderStatus'} . ' -> ';
	my $result = $yacuna->call('POST', 'order/cancel/'.$order->{'id'}, ["orderId=".$order->{'id'}]);
	if($json->decode($result)->{'tradeOrder'}){
		print $json->decode($result)->{'tradeOrder'}->{'tradeOrderStatus'}; 
	}	
	else{
		print $result;  
	}
	print "\n";
	return $result;
}

sub confirmOrderYacuna(){
	my($orderId) = @_;
	return $yacuna->call('POST', 'order/confirm/'.$orderId, ["orderId=$orderId"]);
}

sub createOrderYacuna(){
	my($order) = @_;
	print "\n Creating order $order->{'externalReferenceId'}";
	my @params = map { $_.'='.$order->{$_} } keys %{$order};
	return $yacuna->call('POST', 'order/create/'.$order->{'currency1'}.'/'.$order->{'currency2'}, [@params]);
}

sub getYacunaWallet(){
	my($currency) = @_;
	return $yacuna->call('GET', 'wallet/get', ['currency='.$currency]);
}

sub init{
	$yacuna = new Finance::Bitcoin::Yacuna(
		tokenId => $config->{'yacuna'}->{'trader'}->{'apiTokenId'}, 
		secret => $config->{'yacuna'}->{'trader'}->{'apiSecret'}, 
		apiVersion => 1,
		skipSSL => 0,
        sandbox => 1,
        debug => 1
	);

	my $result = {};
	try{
		$result = $json->decode(&getYacunaWallet(''));
		if($result->{'status'} eq 'Error'){
			dump $result;
			throw Error::Simple($result);
		}
		$config->{'yacuna'}->{'trader'}->{'accounts'} = $result->{'wallet'}->{'accounts'};
	}
	catch Error::Simple with{
		throw Error::Simple(shift);
	};
}


