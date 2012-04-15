#!/usr/bin/env perl

# cookieは先にごにょごにょして用意しとく
use strict;
use warnings;
use utf8;
use HTTP::Cookies;
use HTTP::Request;
use LWP::UserAgent;
use DateTime;
use Web::Scraper;
use Encode;
use FindBin qw($Bin);
use Readonly;

Readonly my $FAKE_UA          => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5';
Readonly my $COOKIE_FILE      => sprintf('%s/.ff-brigade-cookie',$Bin);
Readonly my $BASE_URL         => 'http://ff.sp.mbga.jp/_ffjm_team_action_log?team_period_id=';
Readonly my $IRC_HOST         => 'http://127.0.0.1:4979/';
Readonly my $IRC_CHANNEL      => '#dameninngenn';
Readonly my $BASE_PERIOD_ID   => 5;
Readonly my $BASE_PERIOD_TERM => 60 * 60 * 24 * 7;
Readonly my %BASE_PERIOD_DATE => (
    year      => 2012,
    month     => 1,
    day       => 2,
    hour      => 5,
    minute    => 0,
    second    => 0
);

my $cookie_jar = HTTP::Cookies->new(file => $COOKIE_FILE, autosave => 1);
my $ua = LWP::UserAgent->new(
    agent      => $FAKE_UA,
    cookie_jar => $cookie_jar,
);

my $now = DateTime->now( time_zone => 'Asia/Tokyo' )->add(minutes => -1);
my $period_id = get_period_id($now);

my $req = HTTP::Request->new( 'GET', sprintf('%s%d',$BASE_URL,$period_id) );
my $res = $ua->request( $req );
my $content = $res->content;

my $scrape = scraper {
    process '//div[@class="flex"]',
    'data[]' => 'TEXT';
}->scrape($content);

my $hour = $now->hour;
my $minute = $now->minute;
for my $msg ( @{$scrape->{data}} ) {
    if( $msg =~ /$hour:$minute/ ) {
        my $msg_type = get_msg_type($msg);
        $msg = sprintf('%s > dameninngenn',$msg) if $msg_type eq 'privmsg';
        send_irc($msg,$msg_type);
    }
}


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

sub get_msg_type {
    my $msg = shift;
    my $type = 'notice';
    my $decoded_msg = Encode::decode('utf8',$msg);
    if( $decoded_msg =~ /遭遇/ && $decoded_msg !~ /ダメ人間/ ) {
        $type = 'privmsg';
    }
    return $type;
}

sub get_period_id {
    my $now = shift || die "m9(^o^)";
    my $start_date = DateTime->new(
        time_zone => 'Asia/Tokyo',
        year      => $BASE_PERIOD_DATE{year},
        month     => $BASE_PERIOD_DATE{month},
        day       => $BASE_PERIOD_DATE{day},
        hour      => $BASE_PERIOD_DATE{hour},
        minute    => $BASE_PERIOD_DATE{minute},
        second    => $BASE_PERIOD_DATE{second},
    );
    my $period_id = $BASE_PERIOD_ID + sprintf('%d',( $now->epoch - $start_date->epoch ) / $BASE_PERIOD_TERM);
    return $period_id;
}
