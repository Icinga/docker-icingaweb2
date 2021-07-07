#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

BRANCH="$1"

get_tag () {
	if git -C dockerweb2-temp tag |grep -qvFe -; then # ex. RCs
		git -C dockerweb2-temp tag --sort=-version:refname |grep -vFe - |head -n 1
	else
		git -C dockerweb2-temp tag --sort=-version:refname |grep -Fe - |head -n 1
	fi
}

get_special () {
	if [ ! -e "$2" ]; then
		rm -rf dockerweb2-temp
		git clone --bare "https://github.com/Icinga/${1}.git" dockerweb2-temp

		case "$2" in
			icingaweb2/modules/incubator)
				REF="$(get_tag)"
				;;
			*)
				if [ -n "$BRANCH" ] && git -C dockerweb2-temp show -s --oneline "$BRANCH"; then
					REF="$BRANCH"
				else
					REF="$(get_tag)"

					if [ "$2" = icingaweb2/modules/icingadb ] && [ "$REF" = 'v1.0.0-rc1' ]; then
						REF=2c0662c420617712bd26234da550dcf8d4afcdb8 # v1.0.0-rc1+
					fi
				fi
				;;
		esac

		git -C dockerweb2-temp archive "--prefix=${2}/" "$REF" |tar -x
		rm -rf dockerweb2-temp
	fi
}

get_lib () {
	get_special "icinga-php-$1" "icinga-php/$2"
}

get_altname () {
	get_special "$1" "icingaweb2/modules/$2"
}

get_mod () {
	get_altname "icingaweb2-module-$1" "$1"
}

get_lib library ipl
get_lib thirdparty vendor
get_mod audit
get_mod aws
get_mod businessprocess
get_mod cube
get_mod director
get_mod fileshipper
get_mod graphite
get_altname icingadb-web icingadb
get_mod idoreports
get_mod incubator
get_mod pdfexport
get_mod reporting
get_mod vspheredb
get_mod x509
