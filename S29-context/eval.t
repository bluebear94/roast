use v6;
use Test;
plan 23;

# L<S29/Context/"=item EVAL">

=begin pod

Tests for the EVAL() builtin

=end pod

# EVAL should evaluate the code in the lexical scope of EVAL's caller
{
    sub make_eval_closure {
        my $a = 5;   #OK not used
        return sub ($s) {
            EVAL $s 
        };
    };
    is(make_eval_closure().('$a'), 5, 'EVAL runs code in the proper lexical scope');
}

is(EVAL('5'), 5, 'simple EVAL works and returns the value');
my $foo = 1234;
is(EVAL('$foo'), $foo, 'simple EVAL using variable defined outside');

# traps die?
dies-ok {EVAL('die; 1')}, "EVAL does not trap die";

dies-ok {EVAL '1 1)'}, "EVAL throws on syntax error";

dies-ok {EVAL 'use Poison; 1'}, "EVAL dies on fatal use";

# L<S04/Exception handlers/Perl 6's EVAL function only evaluates strings, not blocks.>
dies-ok({EVAL {; 42} }, 'block EVAL is gone');

# RT #63978, EVAL didn't work in methods
{
    class EvalTester1 {
        method e($s) { EVAL $s };
    }
    is EvalTester1.e('5'),       5, 'EVAL works inside class methods';
    is EvalTester1.new.e('5'),   5, 'EVAL works inside instance methods';
}

{
    my $x = 5;
    class EvalTester2 {
        method e($s) { EVAL "$s + \$x" };
    }
    is EvalTester2.e('1'),       6, 
       'EVAL works inside class methods, with outer lexicals';
    is EvalTester2.new.e('1'),   6, 
       'EVAL works inside instance methods, with outer lexicals';
}

#?rakudo skip 'EVAL(Buf) RT #122256'
#?niecza skip 'Unable to resolve method encode in class Str'
{
    is EVAL("'møp'".encode('UTF-8')), 'møp', 'EVAL(Buf)';
    is "'møp'".encode('UTF-8').EVAL, 'møp', 'Buf.EVAL';
}

{
    is EVAL(88), 88, 'EVAL of non-string works';
    is 88.EVAL, 88, '.EVAL of non-string works';

    my $number = 2;
    is EVAL($number), $number, 'EVAL of non-string variable works';
    is $number.EVAL, $number, '.EVAL of non-string variable works';
}

# RT #77646
{
    my $x = 0;
    EVAL '$x++' for 1..4;
    is $x, 4, 'can execute the same EVAL multiple times, without surrounding block';

}

# RT #112472
#?niecza todo "No :lang argument yet..."
{
    try EVAL(:lang<rt112472>, '1');
    ok "$!" ~~ / 'rt112472' /, 'EVAL in bogus language mentions the language';
}

# RT #115344
my $rt115344 = 115344;
#?niecza skip 'method form of EVAL does not see outer lexicals'
is('$rt115344'.EVAL, $rt115344, 'method form of EVAL sees outer lexicals');

# RT #115774
#?niecza skip "int NYI"
{
    my int $a; EVAL('');
    ok(1, "presence of low level types doesn't cause EVAL error")
}

# RT #124304
{
    my \a = rand;
    lives-ok { EVAL 'a' }, 'Can EVAL with a sigilless var';
    is EVAL('a'), a, 'EVAL with sigilless var gives correct result';
}

# vim: ft=perl6
