package Devel::SmallProf; # To help the CPAN indexer to identify us

package DB;

require 5.000;

use strict;
# Specify global vars
use vars qw($print_lines $TIMEVAL_T $start $done $filename $line %profile
  %files $prevf $prevl %times $file @start @done $i $stat $time 
  %eval_lines $pkg);

$Devel::SmallProf::VERSION = '0.2';

$print_lines = 0;  # Print contents of executed lines

BEGIN{
  $TIMEVAL_T = "LL";
  $done = $start = pack($TIMEVAL_T, ());
  require 'sys/syscall.ph';
  syscall(&SYS_gettimeofday, $start, 0);
}

sub DB {
  syscall(&SYS_gettimeofday, $done, 0);
  ($pkg,$filename,$line) = (caller(0))[0..2];
  no strict "refs";
  if ($filename =~ /\(eval /) {
    $filename =~ s/(\(eval.*?\))/$pkg:$1/;
    $file = $1;
    $eval_lines{$filename}->[$line] = ${'main::_<'.$file}[$line]; 
  }
  use strict "refs";
  $profile{$filename}->[$line]++;
  @start = unpack($TIMEVAL_T,$start);
  @done = unpack($TIMEVAL_T,$done);
  $times{$prevf}->[$prevl] += ($done[0] + ($done[1]/1_000_000)) - 
                              ($start[0]+($start[1]/1_000_000));
  $files{$filename}++;
  ($prevf, $prevl) = ($filename, $line);
  syscall(&SYS_gettimeofday, $start, 0);
}

END {
  #
  # Get time on last line executed.
  #
  syscall(&SYS_gettimeofday, $done, 0);
  @start = unpack($TIMEVAL_T,$start);
  @done = unpack($TIMEVAL_T,$done);
  $times{$prevf}->[$prevl] += ($done[0] + ($done[1]/1_000_000)) - 
                              ($start[0]+($start[1]/1_000_000));
  #
  # Now write out the results.
  #
  open(OUT,">smallprof.out");
  foreach $file (sort keys %eval_lines) { # print out evals first
    print OUT ("\n", "=" x 50, "\n",
               " Profile of $file\n",
               "=" x 50, "\n\n");
    for $i (1..$#{$profile{$file}}) {
      $stat = $profile{$file}->[$i];
      $time = $times{$file}->[$i];
      chomp($_ = $eval_lines{$file}->[$i]);
      printf OUT ("%5d %.8f \t%4d:%s\n", $stat, $time, $i, $file.':'.$_);
    }
  }
  foreach $file (grep {!/\(eval/} sort keys %files) {
    print OUT ("\n", "=" x 50, "\n",
               " Profile of $file\n",
               "=" x 50, "\n\n");
    if ($print_lines) {
      unless ($file =~ /\(eval /) {
        open(IN, "$file") || die "can't open $file.";
        $i = 0;
        while (<IN>) {
          last if /^__END__/;
          $stat = $profile{$file}->[++$i];
          $time = $times{$file}->[$i];
          printf OUT ("%5d %.8f \t%s", $stat, $time, $_);
        }
        print OUT ("=" x 50, "\n");
      }
    } else {
      unless ($file =~/\(eval /) {
        for ($i = 1; $i <= $#{$profile{$file}}; $i++) {
          $stat = $profile{$file}->[$i];
          $time = $times{$file}->[$i];
          printf OUT ("%5d %.8f \t%s\n", $stat, $time, $file.':'.$i);
        }
      }
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
statistics are placed in the file F<smallprof.out> in one of two 
formats.  If C<$DB::print_lines> is false (the default), it prints:

	<num> <time> <file>:<line>

where <num> is the number of times that the line was executed, <time> is the
amount of time spent executing it and <file> and <line> are the filename and
line number, respectively.

If, on the other hand, C<$DB::print_lines> is true, it print:

	<num> <time> <text>

where <num> and <time> are as above and <text> is the actual text of the
executed line (read from the file).  

Eval lines print <num> and <time> like
the others, but also print the package, the eval number and, if possible, the
text of the line.  This is not affected by C<$DB::print_lines>.

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

SmallProf depends on C<syscall()> and C<gettimeofday()> 
(see L<perlfunc/syscall>) to do its timings.  If your system lacks them 
SmallProf won't work.

=back

=head1 BUGS

The handling of evals is better than version 0.1, but still poor.  For some 
reason, the C<@{'_E<lt>filename'}> array for some evals is empty.  When this
is true, there isn't a lot that can be done.

Comments, advice and questions are welcome.  If you see
inefficent stuff in this module and have a better way, please let me know.

=head1 AUTHOR

Ted Ashton <ashted@southern.edu>

SmallProf was developed from code orignally posted to usenet by Philippe
Verdret.  I've attempted to contact him but have had no success.

Copyright (c) 1997 Ted Ashton

This module is free software and can be redistributed and/or modified under the
same terms as Perl itself.

=head1 SEE ALSO

L<Devel::DProf>, L<gettimeofday()>

=cut
