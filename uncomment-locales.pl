#!/usr/bin/perl -i

my %uniqLocs = ();

for my $subDir ('icinga-L10n', 'icingaweb2/modules/*/application') {
	for my $lcDir (glob "/usr/share/$subDir/locale/*_*") {
		if ($lcDir =~ /(\w+)$/) {
			$uniqLocs{$1} = 1
		}
	}
}

my @locs = keys %uniqLocs;

while (<>) {
	if (/\bUTF-8\b/) {
		for my $loc (@locs) {
			if (/\b$loc\b/) {
				s/^# *//;
				last
			}
		}
	}
} continue {
	print or die $!
}
