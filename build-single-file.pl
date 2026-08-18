#!/usr/bin/perl
# Fallback for build-single-file.py — does exactly the same job, but with
# Perl instead of Python. Use this if python3 refuses to run with:
#
#     You have not agreed to the Xcode license agreements.
#
# That's a one-time macOS prompt, not a bug in either script — fix it
# permanently with:
#
#     sudo xcodebuild -license
#
# and go back to `python3 build-single-file.py` afterwards. Until then, or if
# you'd rather not run a sudo command, this does the same inlining with the
# Perl that ships with every Mac — nothing to install.
#
#     perl build-single-file.pl

use strict;
use warnings;
use MIME::Base64 qw(encode_base64);
use FindBin qw($RealBin);

my $root   = $RealBin;
my $source = "$root/index.html";
my $outdir = "$root/dist";
my $out    = "$outdir/index.html";

die "index.html not found at $source\n" unless -f $source;

open(my $ifh, "<:raw", $source) or die "$!";
local $/;
my $html = <$ifh>;
close $ifh;
printf STDERR "Reading index.html (%d KB)\n", length($html) / 1024;

my %mime_for = (
    png => "image/png", jpg => "image/jpeg", jpeg => "image/jpeg",
    svg => "image/svg+xml",
);
my $inlined = 0;

# Matches both src="assets/…" (images) and href="assets/…" (favicon <link>
# tags) so the single-file bundle is genuinely self-contained either way.
$html =~ s{(src=|href=)(["'])(assets/[^"']+)\2}{
    my ($attr, $quote, $rel) = ($1, $2, $3);
    my $path = "$root/$rel";

    if (-f $path) {
        open(my $afh, "<:raw", $path) or die "cannot read $path: $!";
        local $/;
        my $bytes = <$afh>;
        close $afh;

        my ($ext) = $rel =~ /\.([^.]+)$/;
        my $mime = $mime_for{lc($ext // '')} // "application/octet-stream";
        my $b64 = encode_base64($bytes, "");

        $inlined++;
        printf STDERR "  inlined: %s (%d KB)\n", $rel, length($bytes) / 1024;
        qq{${attr}${quote}data:$mime;base64,$b64${quote}};
    } else {
        print STDERR "  skip (missing): $rel\n";
        $&;
    }
}ge;

mkdir $outdir unless -d $outdir;
open(my $ofh, ">:raw", $out) or die "$!";
print $ofh $html;
close $ofh;

printf STDERR "\nWrote dist/index.html (%d KB), %d image(s) inlined\n",
    length($html) / 1024, $inlined;
