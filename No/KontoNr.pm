package No::KontoNr;

require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK = qw(kontonr_ok modulus_10);

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use strict;

sub kontonr_ok {
    my $nr = shift || return 0;
    $nr =~ s/[ \.]//g;  # det er ok med mellomrom og punktum i nummeret

    # F�rst et par trivielle sjekker
    return 0 unless length($nr) == 11;
    return 0 if $nr =~ /\D/;

    # Siste siffer er kontrollsiffer, plukk det av
    $nr =~ s/(\d)$//;
    my $kontroll = $1; 

    my $sum = 0;
    my $i = 0;
    my $vekt;
    for $vekt (5,4,3,2,7,6,5,4,3,2) {
        $sum += substr($nr, $i++, 1) * $vekt;
    }
    my $k = 11 - ($sum % 11);
    return 0 if $k == 10;  # disse er alltid ulovlige
    $k = 0 if $k == 11;
    return 0 if $k != $kontroll;
    return $nr;
}

sub modulus_10
{
    my $tall = shift;
    $tall =~ s/[^\d]//g;
    my $siffersum = 0;
    my $vekt = 2;
    my $siffer;
    foreach $siffer (reverse split(//, $tall)) {
        my $produkt = $siffer * $vekt;
        # print "$siffer�$vekt=$produkt\n";
        while ($produkt >= 10) {
            $siffersum++;
            $produkt -= 10;
        }
        $siffersum += $produkt;
        $vekt = 3 - $vekt;
    }
    # print "SUM=$siffersum\n";
    (- $siffersum) % 10;
}


1;

__END__

# F�lgende er ogs� en mod_10 sjekker.  Er den raskere?

## credit card verification
## by Randal L. Schwartz <merlyn@stonehenge.com>
## last revision: 12/14/1995

package Card;

## return true iff the $number is a valid card
## non digits are ignored in the string
## works on both 13-number and 16-number cards
sub validate {
    my @revdigits = reverse (shift =~ /(\d)/g);
    my $sum;
    $sum += &digitsum(shift (@revdigits))
        + &digitsum(2*shift (@revdigits))
            while @revdigits;
    not $sum % 10;              # return
}

sub digitsum {
    my @digits = shift =~ /(\d)/g;
    my $sum;
    $sum += shift @digits while @digits;
    $sum;
}

1;
