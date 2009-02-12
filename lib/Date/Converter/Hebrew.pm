package Date::Converter::Hebrew;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.0;

# E G Richards,
# Algorithm I,
# Mapping Time, The Calendar and Its History,
# Oxford, 1999, page 334.

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;
    
    $f = 0 unless defined $f;

    return -1 if ymd_check(\$y, \$m, \$d);
    
    my $jed = new_year_to_jed($y);

    for my $m2 (1 .. $m - 1) {
        $jed += month_length($y, $m2);
    }

    $jed += $d - 1;
    $jed += $f;
    
    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $y1 = jed_to_year($jed);
    my $jed2 = new_year_to_jed($y1);

    my $type = year_to_type($y1);

    my $j1 = int($jed - $jed2);
    my $f1 = ($jed - $jed2) - $j1;

    $j1++;

    return yjf_to_ymdf($y1, $j1, $f1);
}

sub yjf_to_ymdf {
    my ($y, $j, $f) = @_;

    retun (0, 0, 0, 0) if yj_check(\$y, \$j);

    my $m = 1;
    my $d = $j;

    day_borrow(\$y, \$m, \$d);
    day_carry(\$y, \$m, \$d);
    
    return ($y, $m, $d, $f);
}

sub jed_to_year {
    my ($jed) = @_;

    my $jed_epoch = epoch_to_jed();

    return -1 if $jed < $jed_epoch;
    
    my $m = 1 + int ((25920.0 * ($jed - $jed_epoch + 2.5)) / 765433.0);
    my $y = 19 * int ($m / 235) + int ((19 * (Date::Converter::i_modp($m, 235) - 2)) / 235) + 1;

    my $jed2 = new_year_to_jed($y);

    $y-- if $jed2 > $jed;
    
    return $y;
}

sub ymd_check {
    my ($y_ref, $m_ref, $d_ref) = @_;
    
    return 1 if $$y_ref <= 0;

    return 1 if ym_check($y_ref, $m_ref);

    day_borrow($y_ref, $m_ref, $d_ref);
    day_carry($y_ref, $m_ref, $d_ref);

    return 0;
}

sub ym_check {
    my ($y_ref, $m_ref) = @_;

    return 1 if y_check($y_ref);

    month_borrow($y_ref, $m_ref);
    month_carry($y_ref, $m_ref);

    return 0;
}

sub yj_check {
    my ($y_ref, $j_ref) = @_;

    return 1 if y_check($y_ref);

    j_borrow($y_ref, $j_ref);
    j_carry($y_ref, $j_ref);
    
    return 0;
}

sub y_check {
    my ($y_ref) = @_;

    return !($$y_ref > 0);
}

sub month_borrow {
    my ($y_ref, $m_ref) = @_;

    while ($$m_ref <= 0) {
        $$m_ref += year_length_months($$y_ref);
        $$y_ref--;
    }
}

sub month_carry {
    my ($y_ref, $m_ref) = @_;
    
    my $months = year_length_months($$y_ref);

    return if $$m_ref <= $months;

    $$m_ref -= $months;
    $$y_ref++;
}

sub day_borrow {
    my ($y_ref, $m_ref, $d_ref) = @_;

    while ($$d_ref <= 0) {    
        $$m_ref--;    
        month_borrow($y_ref, $m_ref);        
        $$d_ref += month_length($$y_ref, $$m_ref);
    }
}

sub day_carry {
    my ($y_ref, $m_ref, $d_ref) = @_;

    my $days = month_length($$y_ref, $$m_ref);

    while ($$d_ref > $days) {    
        $$d_ref -= $days;
        $$m_ref++;
        $days = month_length($$y_ref, $$m_ref);
        month_carry($y_ref, $m_ref);
    }
}

sub j_borrow {
    my ($y_ref, $j_ref) = @_;

    while ($$j_ref <= 0) {
        $$y_ref--;
        $$j_ref += year_length_hebrew($$y_ref);
    }
}

sub j_carry {
    my ($y_ref, $j_ref) = @_;

    my $days = year_length($$y_ref);

    return if $$j_ref < $days;

    $$j_ref -= $days;
    $$y_ref++;
}

sub month_length {
    my ($y, $m) = @_;

    my @a = (
        [30,  30,  30,  30,  30,  30],
        [29,  29,  30,  29,  29,  30],
        [29,  30,  30,  29,  30,  30],
        [29,  29,  29,  29,  29,  29],
        [30,  30,  30,  30,  30,  30],
        [29,  29,  29,  30,  30,  30],
        [30,  30,  30,  29,  29,  30],
        [29,  29,  29,  30,  30,  29],
        [30,  30,  30,  29,  29,  29],
        [29,  29,  29,  30,  30,  30],
        [30,  30,  30,  29,  29,  29],
        [29,  29,  29,  30,  30,  30],
        [ 0,   0,   0,  29,  29,  29]
    );

    return 0 if ym_check(\$y, \$m);

    my $type = year_to_type($y);

    if ($type < 1 || $type > 6) {
        return 0;
    }
    elsif ($m < 1 || $m > 13) {
        return 0;
    }
    else {
        return $a[$m - 1][$type - 1];
    }
}

sub year_to_type {
    my ($y) = @_;

    return -1 if $y <= 0;
  
    my $jed = new_year_to_jed($y);
    my $jed2 = new_year_to_jed($y + 1);
    
    my $year_length = int ($jed2 - $jed + 0.5);

    if ($year_length == 353) {
        return 1;
    }    
    elsif ($year_length == 354) {
        return 2;
    }
    elsif ($year_length == 355) {
        return 3;
    }
    elsif ($year_length == 383) {
        return 4;
    }
    elsif ($year_length == 384) {
        return 5;
    }
    elsif ($year_length == 385) {
        return 6;
    }
    else {
        return 0;
    }
}

sub new_year_to_jed {
    my ($y) = @_;

    my ($mu, $tc, $th, $d, $t_prime, $w, $e, $e_prime);
    {
        use integer;
        
        $mu = (235 * $y - 234) / 19;
        $tc = 204 + 793 * $mu;
        $th = 5 + 12 * $mu + $tc / 1080;
        $d = 1 + 29 * $mu + $th / 24;
        $t_prime = ($tc % 1080) + 1080 * ($th % 24);
        
        $w = Date::Converter::i_wrap($d + 1, 1, 7);
        
        $e = ((7 * $y + 13) % 19) / 12;
        $e_prime = ((7 * $y + 6) % 19 ) / 12;
        
        $d++ if
            ($t_prime >= 19940 ||
            ($t_prime >= 9924 && $w == 3 && $e == 0) ||
            ($t_prime >= 16788 && $w == 2 && $e == 0 && $e_prime == 1));
    }
    
    my $jed_epoch = epoch_to_jed();
    my $jed = $jed_epoch - 1 + $d + (($d + 5) % 7) % 2;

    return $jed;
}

sub epoch_to_jed {
    return 347998.5;
}

sub year_length_months {
    my ($y) = @_;

    return year_is_embolismic($y) ? 13 : 12;
}

sub year_length {
    my ($y) = @_;

    my $jed = new_year_to_jed($y);
    my $y2 = $y + 1;

    my $jed2 = new_year_to_jed($y2);
    return int ($jed2 - $jed + 0.5);
}

sub year_is_embolismic {
    my ($y) = @_;

    return Date::Converter::i_modp(7 * $y + 13, 19) >= 12;
}

1;
