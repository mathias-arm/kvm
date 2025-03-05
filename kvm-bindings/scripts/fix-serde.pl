#!/usr/bin/env perl

use strict;

if ($#ARGV != 2) {
    print "Usage:\n\tperl fix-serde.pl \$\{ARCH\}_headers/bindings.rs src/\$\{ARCH\}/serialize.rs src/\$\{ARCH\}/bindings.rs\n";
    exit;
}

my ($input_file, $serialize_file, $output_file) = @ARGV;

open(INPUT, $input_file);
my $content = join '', <INPUT>;
close (INPUT);

open(SERIALIZE, $serialize_file);
my $serialize = join '', <SERIALIZE>;
close (SERIALIZE);

my @special_structs = qw(__BindgenBitfieldUnit __IncompleteArrayField);
my $insert = "#[cfg_attr(\n    feature = \"serde\",\n    derive(zerocopy::AsBytes, zerocopy::FromBytes, zerocopy::FromZeroes)\n)]\n";

my ($struct) = ($serialize =~ m/\nserde_impls\![(](.*?)[)]/sg);
my @structs = map { s/\s*(.*)\s*/$1/; $_ } (split m/,/, $struct);

if ($output_file =~ m/x86_64/) {
    for my $struct (@special_structs) {
        $content =~ s/#\[repr\(C\)\](.*)(pub struct \Q${struct}\E)/\#\[repr\(transparent\)\]$1$2/s;
        $content =~ s/(pub struct \Q${struct}\E)/${insert}$1/s;
    }

    for my $struct (@structs) {
        my $struct_ty = "${struct}__bindgen_ty_";
        $content =~ s/(pub\s+struct\s+${struct_ty})/${insert}$1/sg;
        $content =~ s/(pub\s+union\s+${struct_ty})/${insert}$1/sg;
    }
}

for my $struct (@structs) {
    $content =~ s/(pub struct ${struct})/${insert}$1/s;
}

$content =~ s/\Q${insert}${insert}\E/${insert}/sg;

open(OUTPUT, ">$output_file");
print OUTPUT $content;
close(OUTPUT);

exit 0;
