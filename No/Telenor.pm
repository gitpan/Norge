package No::Telenor;

require Carp;
require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK = qw(samtale_pris);

use strict;
use vars qw(%TAKSTER $DEBUG $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);


=head1 NAME

No::Telenor - Calculate telephone call prices in Norway

=head1 SYNOPSIS

  use No::Telenor qw(samtale_pris);
  $kr = samtale_pris($time, 3600, "LFV");


=head1 DESCRIPTION

B<This documentation is written in Norwegian.>

Denne modulen inneholder funksjonen samtale_pris().  Denne funksjonen
vil beregne prisen p� en telefonsamtale gitt tidspunkt, varighet og
takst som parameter.  Funksjonen kjenner til sanntidstakstene som
ble innf�rt fra og med �r 1997.  Forh�pentligvis vil jeg klare �
oppdater funksjonen etterhvert som Telenor finner p� nye sprell.

=cut


%TAKSTER = (
        # Takstnavn                    Start  Dag    Natt   Dagtakst
	#                              pris   takst  takst  periode
 L   => [ "Lokaltakst",                0.40,  0.25,  0.14,   8 => 17 ],
 LFV => [ "Lokaltakst Familie&Venner", 0.40,  0.25,  0.112,  8 => 17 ],
 R   => [ "Rikstakst",                 0.40,  0.60,  0.50,   8 => 17 ],
 RFV => [ "Rikstakst Familie&Venner",  0.32,  0.48,  0.40,   8 => 17 ],
'L+' => [ "Lokaltakst Pluss",          0.37,  0.23,  0.13,   8 => 22 ],
'R+' => [ "Rikstakst Pluss",           0.37,  0.55,  0.46,   8 => 22 ],
 M   => [ "Telenor Mobil",             0.40,  2.40,  2.40,   0 =>  0 ],
'M+' => [ "Telenor Mobil Pluss",       0.37,  2.19,  2.19,   0 =>  0 ],
);

# Det er greier � regne med takstene pr. time
for (values %TAKSTER) {
    $_->[2] *= 60;
    $_->[3] *= 60;
}

$DEBUG ||= 0;
if ($DEBUG) {
    for (sort keys %TAKSTER) {
	printf "%-3s %-30s %4.2f %5.2f %5.2f %02d-%02d\n", $_, @{$TAKSTER{$_}};
    }
}


=head2 samtale_pris($start, $varighet, $takst)

Rutinen vil beregne samtale prisen i NOK.  Argumentet $start er
starttidspunktet gitt som en standard perl 'time' verdi.  Argumentet
$varighet er samtalens varighet i sekunder.  Argumentet $takst er en
kort streng som forteller hvilken takst som skal brukes.  F�lgende
takser er st�ttet:

   L     Lokaltakst
   LFV   Lokaltakst Familie&Venner
   R     Rikstakst
   RFV   Rikstakst Familie&Venner
   L+    Lokaltakst Pluss
   R+    Rikstakst Pluss
   M     Telenor Mobil
   M+    Telenor Mobil Pluss

=cut


sub samtale_pris
{
    my($start, $dur, $takst) = @_;

    Carp::croak("Ukjent takst '$takst'") unless exists $TAKSTER{$takst};
    my($T, $START_PRIS, $DAG_TAKST, $NATT_TAKST, $DAG_START, $DAG_SLUTT) =
	@{$TAKSTER{$takst}};

    if ($DEBUG) {
	printf "Takst: $takst start=%.2f/dag=%.2f/natt=%.2f\n",
	       $START_PRIS, $DAG_TAKST, $NATT_TAKST;
    }

    # Istedenfor � regne med dagtakst fra 0800-1700 s� trekker vi fra
    # 8 timer p� starttidspunktet og regner dagtakst fra 0000-0900.  Det
    # forenkler endel senere.
    $start -= $DAG_START * 3600;
    $DAG_SLUTT -= $DAG_START;

    # Finn klokkeslett for startstidspunktet
    my($sec,$min,$hour,$d,$m,$y,$weekday) = localtime($start);
    Carp::croak("Kjenner ikke takstene f�r 1997") if $y < 97;

    # Gj�r $hour og $dur om til desimaltall
    $hour += $min/60 + $sec / 3600;
    $dur = $dur/3600;
    $weekday = ($weekday + 6) % 7;  # make monday day #0, sunday #6

    # Kalkuler prisen for samtalen.
    # Vi tar en og en takstsone men maksimalt en dag av gangen.
    my $price = $START_PRIS;
    while ($dur > 0) {
	printf ">>> PRICE=%.2f DUR=%.3f HOUR=%.3f DAY=%d\n",
	       $price, $dur, $hour+8, $weekday if $DEBUG;
	if ($weekday >= 5 || $hour >= $DAG_SLUTT) {
	    if (24 - $hour < $dur) {
		# crossing day boundary
		$price += (24 - $hour) * $NATT_TAKST;
		$dur -= 24 - $hour;
		$weekday = ($weekday + 1) % 7;
		$hour = 0;
	    } else {
		$price += $dur * $NATT_TAKST;
		$dur = 0;
	    }
	} else {
	    if ($DAG_SLUTT - $hour < $dur) {
		$price += ($DAG_SLUTT - $hour) * $DAG_TAKST;
		$dur -= ($DAG_SLUTT - $hour);
		$hour = $DAG_SLUTT;
	    } else {
		$price += $dur * $DAG_TAKST;
		$dur = 0;
	    }
	}
    }
    printf ">>> PRICE=%.2f\n", $price if $DEBUG;
    $price;
}

1;
__END__

=head1 BUGS

Prisberegningen kan bli un�yaktig hvis samtalen foregikk i overgangen
mellom vinter- og sommertid eller omvendt.

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut
