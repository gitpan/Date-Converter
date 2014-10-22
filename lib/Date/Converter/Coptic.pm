package Date::Converter::Coptic;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.01;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    my ($y_prime, $m_prime, $d_prime);
    {
        use integer;

        $y_prime = $y + 4996 - (13 - $m) / 13;
        $m_prime = ($m + 12) % 13;
        $d_prime = $d - 1;
    }

    my $jed = (int ((1461 * $y_prime) / 4) + 30 * $m_prime + $d_prime - 124) - 0.5;
    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $j = int ($jed + 0.5);
    my $f = ($jed + 0.5) - $j;
        
    my ($j_prime, $y_prime, $t_prime, $m_prime, $d_prime, $y, $m, $d);
    {
        use integer;
        
        $j_prime = $j + 124;
        
        $y_prime = (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461) / 4;
        $m_prime = $t_prime / 30;
        $d_prime = $t_prime % 30;

        $d = $d_prime + 1;
        $m = ($m_prime % 13) + 1;
        $y = $y_prime - 4996 + (13 - $m) / 13;
    }
    
    return ($y, $m, $d, $f);
}

1;
