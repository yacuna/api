#!/usr/bin/perl

use strict;
no strict 'subs';
use warnings;

use Data::Dumper;
use Data::Dump qw(dump);
use JSON;
use Error qw(:try);
use Finance::Bank::Kraken;
use Finance::Bitcoin::Yacuna;
use DateTime;
use Math::BigFloat;
use Time::HiRes qw(gettimeofday);

my $json = new JSON;
my $yacuna = {};

my $config = {
	yacuna => {
		trader => {
		    apiTokenId => 'AAEAAAgfi0Ng2OJsizUQPgyVIFejURIbuoaXE_Mfm7EgLscHzjaPWxT6',
            apiSecret => 'bbb47c33dfa06d394dc3f3db32cbbf00'
		}
	}
};

main->run();

sub run{
	try{
        my $trader = \$config->{'yacuna'}->{'trader'};
	    &init($trader);
	    foreach my $acc (@{${$trader}->{'accounts'}}){
		    dump $acc;	
			&cancelOrdersYacuna($acc);
		}
		&updateConfigYacuna($trader);
		dump $config;
	}
	catch Error::Simple with{
		my $E = shift;
		dump($E);
	};
	print DateTime->now . " finished\n";
	exit(0);
}

sub cancelOrdersYacuna(){
        my ($acc) = @_;
        my %orders = &listOrdersYacuna($acc->{'walletAccountId'}, 'Confirmed');
        foreach my $order (values %orders){
                &cancelOrderYacuna($order);
        }
}

sub listOrdersYacuna(){
	my($walletAccountId, $status) = @_;	
	my %orders = ();
	my $result = $yacuna->call('GET', 'order/list', ["walletAccountId=$walletAccountId", "tradeOrderStatus=$status", "count=1000"]);
	my @raw = @{$json->decode($result)->{'tradeOrders'}};

	my $startWith = 0;
	while ($json->decode($result)->{'pagingInfo'}->{'showNext'} eq 'true'){
		$startWith += int $json->decode($result)->{'pagingInfo'}->{'actualCount'};
		$result = $yacuna->call('GET', 'order/list', ["walletAccountId=$walletAccountId", "tradeOrderStatus=$status", "count=1000", "startWith=$startWith"]);
		push @raw, @{$json->decode($result)->{'tradeOrders'}};
	}

	%orders = map { 
		if($_->{'externalReferenceId'}){
			(split('X',$_->{'externalReferenceId'}))[0] => $_
		} 
		else {$_->{'id'} => $_} 
	} @raw;

	return %orders;
}

sub cancelOrderYacuna(){
	my($order) = @_;
	my $id = defined $order->{'externalReferenceId'} ? $order->{'externalReferenceId'} : $order->{'id'};
	print "canceling ". $id ." " .$order->{'tradeOrderStatus'} . ' -> ';
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

sub getYacunaWallet(){
	my($currency) = @_;
	return $yacuna->call('GET', 'wallet/get', ['test=olala','currency='.$currency]);
}

sub updateConfigYacuna(){
	my ($trader) = @_;
	my $wallet = $json->decode(&getYacunaWallet(''))->{'wallet'};
	${$trader}->{'accounts'} = $wallet->{'accounts'};
}


sub init{
	my ($trader) = @_;
	$yacuna = new Finance::Bitcoin::Yacuna(
        tokenId => ${$trader}->{'apiTokenId'},
        secret => ${$trader}->{'apiSecret'},
        apiVersion => 1,
        skipSSL => 0
	);
	&updateConfigYacuna($trader);
}
