use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if ($^O eq 'MSWin32') {
   &convert_SmallProf;
}

WriteMakefile(
    'NAME'	=> 'Devel::SmallProf',
    'VERSION_FROM' => 'SmallProf.pm', # finds $VERSION
    'clean' => { FILES => 'smallprof.out' },
    'dist' => { COMPRESS => "gzip", SUFFIX => "gz" }
);

sub convert_SmallProf {
  if (!(-e 'SmallProf_UNIX.pm')) { 
    print "Converting to Win32 version.\n";
    open(UNIX,"SmallProf.pm") or die "Could not open original SmallProf.pm";
    open(WIN32,">SmallProf_Win32.pm") or
      die "Could not open new SmallProf_Win32.pm";
    my $counter = 0;;
    while (<UNIX>) {
      ((print WIN32) and last) if /^__END__/;
      if (/use Time::HiRes/) {
        print WIN32 'use Win32::API;',"\n";
        $counter |= 1;
      } elsif (/use vars qw\(\$start/) {
        print WIN32 'use vars qw($qpf $qpc $freq $scale @freq $delta);',"\n";
        print WIN32;
        $counter |= 2;
      } elsif (/BEGIN {/) {
        print WIN32;
        print WIN32 <<'SetupCode';
  # Win32 Architecture-dependent code
  $scale = 2**32;
  ($qpf = new Win32::API('kernel32', 'QueryPerformanceFrequency', ['P'], 'I'))
    or die "Failed to get QueryPerformanceFrequency handle: $!";
  $freq = pack('LL', ());
  $qpf->Call($freq);
  @freq = unpack('LL', $freq);
  $freq = $freq[1] * $scale + $freq[0];
  die "This architecture does not support Win32 high-resolution performance counters!"
    unless $freq;
#    print "Frequency is $freq\n";
  
  ($qpc = new Win32::API('kernel32', 'QueryPerformanceCounter', ['P'], 'I'))
    or die "Failed to get QueryPerformanceCounter handle: $!";
  # end of architecture-dependent code
  
SetupCode
        $counter |= 4;
      } elsif (/(\s*)\$start = time/) {
        print WIN32 $1.'$qpc->Call($start);',"\n";
        $counter |= 8;
      } elsif (/(\s*)\$done = time/) {
        print WIN32 $1.'$qpc->Call($done);',"\n";
        $counter |= 16;
      } elsif (/(\s*)(\$\S.*)\=\s*\$done\s*\-\s*\$start/) {
        my($space,$var) = ($1,$2);
        my($code) = q(X@start = unpack('LL', $start);
                      X@done  = unpack('LL', $done);
                      XY= ($done [1] * $scale + $done [0]) -
                      X  ($start[1] * $scale + $start[0]););
        $code =~ s/^\s*X/$space/mg;
        $code =~ s/Y/$var/g;
        print WIN32 $code,"\n";
        $counter |= 32;
      } elsif ($x = quotemeta('$times{$file}->[$i]') and /^(.*)($x)([^=]*)$/) {
        print WIN32 "$1($2/\$freq)$3\n";
        $counter |= 64;
      } else {
        print WIN32;
      }
    }
    {  # copy the documentation
      undef local $/;
      print WIN32 <UNIX>;
    }
    close UNIX;
    close WIN32;
    rename 'SmallProf.pm','SmallProf_UNIX.pm';
    rename 'SmallProf_Win32.pm','SmallProf.pm';
  }
}
