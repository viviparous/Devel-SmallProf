use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if ($^O eq 'MSWin32') {
  &convert_SmallProf;
  %prereq = ( 'Win32::API' => '' );
} else {
  %prereq = ( 'Time::HiRes' => '1.16' );
}

WriteMakefile(
    'NAME'	=> 'Devel::SmallProf',
    'VERSION_FROM' => 'SmallProf.pm', # finds $VERSION
    'PREREQ_PM' => \%prereq,
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
      } elsif (/BEGIN {/) {
        print WIN32;
        print WIN32 <<'SetupCode';
  # Win32 Architecture-dependent code
  sub SCALE () { 2**32 }
  my($qpf,@freq);
  ($qpf = new Win32::API('kernel32', 'QueryPerformanceFrequency', ['P'], 'I'))
    or die "Failed to get QueryPerformanceFrequency handle: $!";
  $DB::freq = pack('LL', ());
  $qpf->Call($DB::freq);
  @freq = unpack('LL', $DB::freq);
  $DB::freq = $freq[1] * SCALE + $freq[0];
  die "This architecture does not support Win32 high-resolution performance counters!"
    unless $DB::freq;
#    print "Frequency is $DB::freq\n";
  
  ($DB::qpc = new Win32::API('kernel32', 'QueryPerformanceCounter', ['P'], 'I'))
    or die "Failed to get QueryPerformanceCounter handle: $!";
  # end of architecture-dependent code
  
SetupCode
        $counter |= 4;
      } elsif (/(\s*)\$DB::start\s*=\s*time/) {
        print WIN32 $1.'$DB::qpc->Call($start);',"\n";
        $counter |= 8;
      } elsif (/(\s*(?:my\s*)?)\$done\s*=\s*time/) {
        print WIN32 $1.'$DB::qpc->Call($done);',"\n";
        $counter |= 16;
      } elsif (/(\s*(?:my\s*)?)(\$\S.*)\=\s*\$done\s*\-\s*\$DB::start/) {
        my($space,$var) = ($1,$2);
        my($code) = q(Xmy(@start) = unpack('LL', $DB::start);
                      Xmy(@done)  = unpack('LL', $done);
                      XY= ($done [1] * SCALE + $done [0]) -
                      X  ($start[1] * SCALE + $start[0]););
        $code =~ s/^\s*X/$space/mg;
        $code =~ s/Y/$var/g;
        print WIN32 $code,"\n";
        $counter |= 32;
      } elsif ($x = quotemeta('$DB::times{$file}->[$i]') and 
               /^(.*)($x)([^=]*)$/) {
        print WIN32 "$1($2/\$DB::freq)$3\n";
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
