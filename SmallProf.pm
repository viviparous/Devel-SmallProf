package Devel::SmallProf; # To help the CPAN indexer to identify us

use vars qw($VERSION);
$VERSION = '0.3';

package DB;

require 5.000;

use Time::HiRes 'time';

use strict;
# Specify global vars
use vars qw($start $done $filename $line %profile $drop_zeros $delta
  %files $prevf $prevl %times $file @start @done $i $stat $time 
  %eval_lines $pkg $nulltime);

$drop_zeros = 0;

BEGIN {
  $prevf = '';
  $done = $prevl = 0;

  # "Null time" compensation code
  $nulltime = 0;
  for (1..100) {
    $start = time;
    $done = time;
    $nulltime += $done - $start;
  }
  $nulltime /= 100;
  # print "Nulltime is $nulltime.\n";

  $start = time;
}

sub DB {
  $done = time;
  $delta = $done - $start;
  $delta = ($delta > $nulltime) ? $delta - $nulltime : 0;
  ($pkg,$filename,$line) = (caller(0))[0..2];
  no strict "refs";
  if ($filename =~ /\(eval /) {
    $filename =~ s/(\(eval.*?\))/$pkg:$1/;
    $file = $1;
    $eval_lines{$filename}->[$line] = ${'main::_<'.$file}[$line]; 
  }
  use strict "refs";
  $profile{$filename}->[$line]++;
  $times{$prevf}->[$prevl] += $delta;
  $files{$filename}++;
  ($prevf, $prevl) = ($filename, $line);

  $start = time;
}

END {
  # Get time on last line executed.
  $done = time;
  $delta = $done - $start;
  $delta = ($delta > $nulltime) ? $delta - $nulltime : 0;
  $times{$prevf}->[$prevl] += $delta;

  # Now write out the results.
  open(OUT,">smallprof.out");
  foreach $file (sort keys %eval_lines) { # print out evals first
    print OUT ("\n", "=" x 50, "\n",
               " Profile of $file\n",
               "=" x 50, "\n\n");
    for $i (1..$#{$profile{$file}}) {
      $stat = $profile{$file}->[$i] || 0;
      next if !$stat && $drop_zeros;
      $time = $times{$file}->[$i] || 0;
      chomp($_ = $eval_lines{$file}->[$i]);
      printf OUT ("%5d %.8f %4d:%s\n", $stat, $time, $i, $file.':'.$_);
    }
  }
  foreach $file (grep {!/\(eval/} sort keys %files) {
    print OUT ("\n", "=" x 50, "\n",
               " Profile of $file\n",
               "=" x 50, "\n\n");
    unless ($file =~ /\(eval /) {
      open(IN, "$file") || die "can't open $file.";
      $i = 0;
      while (<IN>) {
        last if /^__END__/;
        $stat = $profile{$file}->[++$i] || 0;
        next if !$stat && $drop_zeros;
        $time = $times{$file}->[$i] || 0;
        printf OUT ("%5d %.8f %4d:%s", $stat, $time, $i, $_);
      }
      print OUT ("=" x 50, "\n");
    }
  }
  close OUT;
}

1;

__END__

=head1 NAME

Devel::SmallProf - per-line Perl profiler

=head1 SYNOPSIS

	perl5 -d:SmallProf test.pl

=head1 DESCRIPTION

The Devel::SmallProf is a small profiler which I find useful (or at least 
interesting :-) when used in conjuction with Devel::DProf.  It collects 
statistics on the run times of the lines in the various files being run.  Those
statistics are placed in the file F<smallprof.out> in the following format:
 
        <num> <time> <file>:<line>:<text>

where <num> is the number of times that the line was executed, <time> is the
amount of time spent executing it and <file>, <line> and <text> are the 
filename, the line number and the actual text of the executed line (read from
the file).

Eval lines print <num> and <time> like the others, but also print the package,
the eval number and, if possible, the text of the line.

The package uses the debugging hooks in Perl and thus needs the B<-d> switch,
so to profile F<test.pl>, use the command:

	perl5 -d:SmallProf test.pl

Once the script is done, the statistics in F<smallprof.out> can be sorted to 
show which lines took the most time.  The output can be sorted to find which
lines take the longest, either with the sort command:

	sort -nrk 2 smallprof.out | less

or a perl script:

	open(PROF,"smallprof.out");
	@sorted = sort {(split(/\s+/,$b))[2] <=> 
                        (split(/\s+/,$a))[2]} <PROF>;
        close PROF;
	print join('',@sorted);

=head1 NOTES

=over 4

=item * 

Determining the accuracy or signifiance of the results is left as an 
exercise for the reader.  I've tried to keep the timings pretty much just to 
the profiled code, but no guarantees of any kind are made.

=item *

SmallProf does attempt to make up for its shortcomings by subtracting a small
amount from each timing (null time compensation).  This should help somewhat
with the accuracy.

=item * 

SmallProf depends on the Time::HiRes package to do its timings except for the
Win32 version which depends on Win32::API.

=item *

If you do not wish to see lines which were never called, set the variable
C<$DB::drop_zeros = 1>.

=back

=head1 INSTALLATION

Makefile.PL checks to see if this is a Win32 platform and runs a conversion
script on SmallProf prior to installation.  I've not been able to test this,
but have hopes that it will install on most platforms smoothly.  As always,
please let me know.

=head1 BUGS

The handling of evals is better than version 0.1, but still poor.  For some 
reason, the C<@{'_E<lt>filename'}> array for some evals is empty.  When this
is true, there isn't a lot that can be done.

The conversion to the Win32 version is done during the call to Makefile.PL.
This seems fairly inappropriate, but I'm not sure where better to do it.

Comments, advice and questions are welcome.  If you see
inefficent stuff in this module and have a better way, please let me know.

=head1 AUTHOR
 
Ted Ashton E<lt>ashted@southern.eduE<gt>
 
SmallProf was developed from code orignally posted to usenet by Philippe
Verdret.
 
Copyright (c) 1997 Ted Ashton
 
This module is free software and can be redistributed and/or modified under the
same terms as Perl itself.

=head1 SEE ALSO

L<Devel::DProf>, L<gettimeofday()>

=cut
