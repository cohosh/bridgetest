#!/usr/bin/perl

# Take in a bootstrap.csv file, and only output the lines for tests where
# the control locale reached 100 in that test (i.e. for that runid and
# nickname).
#
# The goal is to discard test results where the control couldn't fully
# reach the bridge, because those are likely to be problems with the
# bridge rather than censorship.
#
# I picked "100" as the progress the control needed to reach, to be
# conservative, but in theory we might be able to pick some number
# between 10 and 100, since those indicate a successful connection but
# perhaps we just didn't wait long enough.

@lines = <>; # read the whole file
shift @lines; # discard the header legend line

$controlstring = "local"; # which country name is the control

# First: learn which bridges were tested in the control location
foreach (@lines) {
  my @pieces = split(/,/);

  if ($pieces[1] eq $controlstring) {
    $controlresult{$pieces[2] . $pieces[3]} = $pieces[4];
  }
}

# Second: go through and look for test probes where the control worked
foreach (@lines) {
  my @pieces = split(/,/);

  if ($pieces[1] ne $controlstring) {
    $control = $controlresult{$pieces[2] . $pieces[3]};
    if ($control == 100) {
      print $_; # the control worked, so this is a real result.
      $used{$pieces[2] . $pieces[3]} = 1; # remember we liked this test
    }
  }
}

# Last: go through and print control lines with corresponding test probes
foreach (@lines) {
  my @pieces = split(/,/);

  if ($pieces[1] eq $controlstring and $used{$pieces[2] . $pieces[3]} == 1) {
    print $_;
  }
}

