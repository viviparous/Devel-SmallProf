# Check to see if .smallprof works  (it's setup in part2, used in part3 and
#   checked here).
print "1..1\n";
print !-s 'smallprof.out' ? "ok 1\n" : "not ok 1\n";

unlink '.smallprof';  # So as to not confuse the natives
