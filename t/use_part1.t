#!perl -d:SmallProf

$DB::drop_zeros = 1;
%DB::packages = ( 'main' => 1, 'A' => 0, 'C' => 1 );
$DB::profile = 0;
sleep(1);
$DB::profile = 1;
for (1..5) {
  $z++;
  $z--;
  $z++; $z--;
}

package A;

sub test {
  $a++;
}

eval q[
package B;

sub test {
  $b++;
}
];

eval q[
package C;

sub test {
  $c++;
}
];

A::test();
B::test();
C::test();

print "1..1\nok 1\n";  # do the actual checks in _part2
