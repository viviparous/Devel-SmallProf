use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

%prereq = ( 'Time::HiRes' => '1.20' );

WriteMakefile(
    'NAME'	=> 'Devel::SmallProf',
    'VERSION_FROM' => 'SmallProf.pm', # finds $VERSION
    'PREREQ_PM' => \%prereq,
    'clean' => { FILES => 'smallprof.out' },
    'dist' => { COMPRESS => "gzip", SUFFIX => "gz" }
);
