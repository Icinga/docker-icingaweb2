#!/bin/bash
set -exo pipefail

BRANCH="$1"

get_tag () {
	git -C dockerweb2-temp tag --sort=-version:refname |grep -vFe - |head -n 1
}

get_special () {
	if [ ! -e "icingaweb2/modules/$2" ]; then
		rm -rf dockerweb2-temp
		git clone --bare "https://github.com/Icinga/${1}.git" dockerweb2-temp

		case "$2" in
			icingadb)
				REF=2c0662c420617712bd26234da550dcf8d4afcdb8 # v1.0.0-rc1+
				;;
			incubator|ipl|reactbundle)
				REF="$(get_tag)"
				;;
			*)
				if [ -n "$BRANCH" ]; then
					REF="$BRANCH"
				else
					REF="$(get_tag)"
				fi
				;;
		esac

		git -C dockerweb2-temp archive "--prefix=icingaweb2/modules/${2}/" "$REF" |tar -x
		rm -rf dockerweb2-temp
	fi
}

get_mod () {
	get_special "icingaweb2-module-$1" "$1"
}

get_mod audit
get_mod aws
get_mod businessprocess
get_mod cube
get_mod director
get_mod fileshipper
get_mod graphite
get_special icingadb-web icingadb
get_mod idoreports
get_mod incubator
get_mod ipl
get_mod pdfexport
get_mod reactbundle
get_mod reporting
get_mod vspheredb
get_mod x509
