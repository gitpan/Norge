package No::PersonNr;

require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK = qw(personnr_ok er_mann er_kvinne fodt_dato);

use Carp qw(croak);
use strict;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);


=head1 NAME

No::PersonNr - Check Norwegian Social security numbers

=head1 SYNOPSIS

  use No::PersonNr qw(personnr_ok);

  if (personnr_ok($nr)) {
      # ...
  }

=head1 DESCRIPTION

B<This documentation is written in Norwegian.>

Denne modulen kan brukes for � sjekke norske personnummer.  De 2 siste
siffrene i personnummerene er kontrollsiffre og m� stemme overens med
resten for at det skal v�re et gyldig nummer.  Modulen inneholder ogs�
funksjoner for � bestemme personens kj�nn og personens f�dselsdato.

Ingen av rutinene eksporteres implisitt.  Du m� be om dem.

=head1 FUNCTIONS

=head2 personnr_ok($nr)

Funksjonen personnr_ok() vil returnere FALSE hvis personnummeret gitt
som argument ikke er gyldig.  Hvis nummeret er gyldig s� vil
funksjonen returnere $nr p� standard form.  Nummeret som gis til
personnr_ok() kan inneholde ' ' eller '-'.

=cut

sub personnr_ok
{
    my($nr,$returndate) = @_;
    return undef unless defined($nr);
    $nr =~ s/[\s\-]+//g;
    return "" if $nr =~ /\D/;
    return "" if length($nr) != 11;
    my @nr = split(//, $nr);

    # Modulo 11 test
    my($vekt);
    for $vekt ([ 3, 7, 6, 1, 8, 9, 4, 5, 2, 1, 0 ],
	       [ 5, 4, 3, 2, 7, 6, 5, 4, 3, 2, 1 ]) {
	my $sum = 0;
	for (0..10) {
	    $sum += $nr[$_] * $vekt->[$_];
 	}
	return "" if $sum % 11;
    }

    # Extract the date part
    my @date = reverse unpack("A2A2A2A3", $nr);
    my $pnr = shift(@date);
 
    # B-nummer -- midlertidig (max 6 mnd) personnr
    $date[2] -= 30 if $date[2] > 40;

    # S� var det det � kjenne igjen hvilket hundre�r som er det riktige.
    # Dette er implementert etter et ikke n�dvendigvis troverdig rykte...
    if ($pnr < 500) {
        $date[0] += 1900;
    } elsif ($pnr < 750) {
	$date[0] += 1800;
    } else {
	$date[0] += 2000;
    }
    return "" unless _is_legal_date(@date);

    return $returndate ? join("-", @date) : $nr;
}


sub _is_legal_date
{
    my($y,$m,$d) = @_;
    return if $d < 1;
    return if $m < 1 || $m > 12;

    my $mdays = 31;
    if ($m == 2) {
	$mdays = (($y % 4 == 0) && ($y % 100 != 0)) || ($y % 400 == 0)
	  ? 29 : 28;
    } elsif ($m == 4 || $m == 6 || $m == 9 || $m == 11) {
	$mdays = 30;
    }
    return if $d > $mdays;
    1;
}


=head2 er_mann($nr)

Vil returnere TRUE hvis $nr tilh�rer en mann.  Rutinen vil croake hvis
nummeret er ugyldig.

=cut

sub er_mann
{
    my $nr = personnr_ok(shift);
    croak "Feil i personnummer" unless $nr;
    substr($nr, 8, 1) % 2;
}


=head2 er_kvinne($nr)

Vil returnere TRUE hvis $nr tilh�rer en kvinne.  Rutinen vil croake
hvis nummeret er ugyldig.

=cut

sub er_kvinne { !er_mann(@_); }


=head2 fodt_dato($nr)

Vil returnere personens f�dselsdato p� formen "����-MM-DD".  Rutinen
returnerer C<""> hvis nummeret er ugyldig.

=cut

sub fodt_dato
{
    personnr_ok(shift, 1);
}

1;

=head1 BUGS

Jeg er ikke helt sikker p� om vi takler f�dselsdatoer f�r �r 1900 og
etter �r 2000.  Hvis noen kan fortelle meg hva algoritmen er s� ville
jeg v�re takknemlig.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut
