# Now check the output file and see how it did.
print "1..7\n";
open(OUT,'smallprof.out');
undef $/;
$_ = <OUT>;
close OUT;
print +(/Profile of \(eval/ && m!Profile of t/use_part1.t!) 
                                           ? "ok 1\n" : "not ok 1\n";
my (@matches) = /Profile of/g;
print +(@matches == 2)                     ? "ok 2\n" : "not ok 2\n";
print +(/^\s*6\s.*:for \(1..5\).*$/m)      ? "ok 3\n" : "not ok 3\n";
print +(m'^\s*10\s.*\$z\+\+; \$z--;\s*$'m) ? "ok 4\n" : "not ok 4\n";
print +(/\$c\+\+;/)                        ? "ok 5\n" : "not ok 5\n";
print +(!/\$b\+\+;/)                       ? "ok 6\n" : "not ok 6\n";
print +(!/\$a\+\+;/)                       ? "ok 7\n" : "not ok 7\n";

unlink 'smallprof.out';
