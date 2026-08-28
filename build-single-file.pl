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

# Minification happens only here, in the bundle — index.html itself keeps
# every comment and its one-selector-per-line formatting, since that's the
# file people actually edit. This just strips the same bytes back out of the
# copy that gets deployed.
#
# CSS gets a real minify: strip /* */ comments, collapse whitespace, trim
# around { } ;. Safe because the stylesheet has no url(...) values — a colon
# or slash inside one of those is exactly the kind of thing a careless
# minifier corrupts, so that's checked before this ships, not assumed.
sub minify_css {
    my ($css) = @_;
    $css =~ s{/\*.*?\*/}{}gs;
    $css =~ s{[ \t\r\n]+}{ }g;
    $css =~ s{ *([{};]) *}{$1}g;
    $css =~ s{^\s+|\s+$}{}g;
    return $css;
}

# JS gets a deliberately smaller pass: only /* */ block comments and blank
# lines. Line comments (//) are left alone — a regex can't reliably tell a
# real // comment from one that's part of a string or a `https://` URL
# without actually tokenising the code, and getting that wrong silently
# breaks the page. The full block-comment style used throughout this file's
# script is still worth stripping; it's most of the saving anyway.
sub minify_js {
    my ($js) = @_;
    $js =~ s{/\*.*?\*/}{}gs;
    $js =~ s{\n[ \t]*\n}{\n}g;
    $js =~ s{^[ \t]+}{}gm;
    $js =~ s{^\s+|\s+$}{}g;
    return $js;
}

my ($css_before, $css_after) = (0, 0);
$html =~ s{(<style>)(.*?)(</style>)}{
    $css_before += length($2);
    my $min = minify_css($2);
    $css_after += length($min);
    "$1$min$3";
}gse;

my ($js_before, $js_after) = (0, 0);
$html =~ s{(<script>)(.*?)(</script>)}{
    $js_before += length($2);
    my $min = minify_js($2);
    $js_after += length($min);
    "$1$min$3";
}gse;

if ($css_before) {
    printf STDERR "Minified CSS: %d KB -> %d KB\n", $css_before / 1024, $css_after / 1024;
}
if ($js_before) {
    printf STDERR "Minified JS:  %d KB -> %d KB\n", $js_before / 1024, $js_after / 1024;
}

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
