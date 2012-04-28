#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use HTTP::Cookies;
use HTTP::Request;
use LWP::UserAgent;
use DateTime;
use FindBin qw($Bin);
use Readonly;

Readonly my $FAKE_UA          => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5';
Readonly my $COOKIE_FILE      => sprintf('%s/.ff-brigade-cookie',$Bin);
Readonly my $BASE_URL         => 'http://ff.sp.mbga.jp/_ffjm_team_btl?chk=MZKLjB4Q&use_bp=3&t=';
Readonly my $IRC_HOST         => 'http://127.0.0.1:4979/';
Readonly my $IRC_CHANNEL      => '#dameninngenn';

my $cookie_jar = HTTP::Cookies->new(file => $COOKIE_FILE, autosave => 1);
my $ua = LWP::UserAgent->new(
    agent      => $FAKE_UA,
    cookie_jar => $cookie_jar,
);

my $now = DateTime->now( time_zone => 'Asia/Tokyo' );

my $req = HTTP::Request->new( 'GET', sprintf('%s%d',$BASE_URL,$now->epoch) );
my $res = $ua->request( $req );

my $msg = 'auto atack';
send_irc($msg);

sub send_irc {
    my $msg = shift;
    my $type = shift || 'notice';
    my $ua = LWP::UserAgent->new(
        agent   => 'FFBrigadeWatcher::Ikachan/0.1',
    );
    my $url = sprintf('%s%s',$IRC_HOST,$type);
    $ua->post($url, +{
        channel => $IRC_CHANNEL,
        message => $msg,
    }); 
}

