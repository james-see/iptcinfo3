#!/usr/bin/env perl

use IPTCInfo;

my $fn = ($#ARGV > -1 ? $ARGV[0] : 'test.jpg');
my $fn2 = substr($fn, 0, rindex($fn, '.')) . '_o.jpg';
print "fn2=$fn2\n";

($info = new Image::IPTCInfo($fn, 'force')) or die("Couldn't...\n");
print "info: $info\n";
$info->SetAttribute('urgency', 'GT');
$info->AddKeyword('ize');
$info->SaveAs($fn2);
$info = new Image::IPTCInfo($fn2, 1);
#print $info->ExportXML('iptc');

