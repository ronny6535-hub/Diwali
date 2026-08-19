#!/usr/bin/perl
# Minimal static file server for local preview.
#
#     perl serve.pl [port]        # defaults to 4321
#
# Why this exists rather than `python3 -m http.server` or `ruby -run -e httpd`:
#   * macOS system python3 is gated behind the Xcode licence prompt
#     (sudo xcodebuild -license), so it won't run here.
#   * Ruby's WEBrick refuses to serve any path whose name ends in a space,
#     and this project folder is "Diwali Website " — with a trailing space.
#
# Perl ships with macOS and only core modules are used, so there is nothing to
# install. This serves the folder the script lives in.

use strict;
use warnings;
use IO::Socket::IP;
use Errno qw(EINTR EAGAIN EWOULDBLOCK);
use FindBin qw($RealBin);
use Cwd qw(abs_path);

my $port = shift(@ARGV) || 4321;
my $root = abs_path($RealBin);

my %TYPES = (
    html => 'text/html; charset=utf-8',
    css  => 'text/css; charset=utf-8',
    js   => 'text/javascript; charset=utf-8',
    json => 'application/json; charset=utf-8',
    svg  => 'image/svg+xml',
    png  => 'image/png',
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    gif  => 'image/gif',
    webp => 'image/webp',
    ico  => 'image/x-icon',
    ics  => 'text/calendar; charset=utf-8',
    txt  => 'text/plain; charset=utf-8',
    md   => 'text/plain; charset=utf-8',
);

# Dual-stack: "localhost" resolves to ::1 before 127.0.0.1 on macOS, so an
# IPv4-only socket gets connection-refused by anything probing localhost.
my $server = IO::Socket::IP->new(
    LocalHost => '::',
    LocalPort => $port,
    Proto     => 'tcp',
    Listen    => 32,
    ReuseAddr => 1,
    V6Only    => 0,
) || IO::Socket::IP->new(          # fall back to IPv4 if the stack lacks v6
    LocalHost => '0.0.0.0',
    LocalPort => $port,
    Proto     => 'tcp',
    Listen    => 32,
    ReuseAddr => 1,
) or die "Cannot listen on port $port: $!\n";

$SIG{CHLD} = 'IGNORE';        # let the kernel reap children; no SIGCHLD handler

print "Serving $root on http://localhost:$port/\n";

while (1) {
    my $client = $server->accept;

    # A signal can interrupt accept() and return undef. That is not a reason to
    # stop serving — only a genuinely dead listening socket is.
    unless ($client) {
        next if $!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK};
        last;
    }

    my $pid = fork();
    if (!defined $pid) { close $client; next; }
    if ($pid) { close $client; next; }                    # parent keeps listening

    close $server;
    handle($client);
    close $client;
    exit 0;
}

sub handle {
    my ($client) = @_;
    $client->autoflush(1);

    my $request = <$client> // return;
    my ($method, $target) = $request =~ m{^(GET|HEAD)\s+(\S+)\s+HTTP/}
        or return respond($client, 405, 'text/plain', 'Method Not Allowed', 'HEAD');

    # Drain the rest of the headers so the client isn't left waiting
    while (my $line = <$client>) { last if $line =~ /^\r?\n$/ }

    $target =~ s/[?#].*$//;                               # strip query and fragment
    $target =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;       # percent-decode
    $target = '/index.html' if $target eq '/';

    # Reject traversal outright rather than trying to sanitise it
    return respond($client, 403, 'text/plain', 'Forbidden', $method)
        if $target =~ m{(^|/)\.\.(/|$)};

    my $path = $root . $target;
    $path .= '/index.html' if -d $path;

    unless (-f $path && -r $path) {
        return respond($client, 404, 'text/plain', "Not found: $target", $method);
    }

    my ($ext) = $path =~ /\.([^.\/]+)$/;
    my $type = $TYPES{lc($ext // '')} // 'application/octet-stream';

    open(my $fh, '<:raw', $path) or
        return respond($client, 500, 'text/plain', 'Read error', $method);
    local $/;
    my $body = <$fh>;
    close $fh;

    respond($client, 200, $type, $body, $method);
}

sub respond {
    my ($client, $status, $type, $body, $method) = @_;
    my %text = (200 => 'OK', 403 => 'Forbidden', 404 => 'Not Found',
                405 => 'Method Not Allowed', 500 => 'Internal Server Error');

    print $client "HTTP/1.1 $status $text{$status}\r\n";
    print $client "Content-Type: $type\r\n";
    print $client "Content-Length: " . length($body) . "\r\n";
    print $client "Cache-Control: no-store\r\n";       # always see the latest edit
    print $client "Connection: close\r\n\r\n";
    print $client $body unless ($method // '') eq 'HEAD';
}
