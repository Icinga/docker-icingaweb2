#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

usage() {
	cat >&2 <<EOF
Usage: get-mods.sh <release|snapshot>

  release:  download the latest release version of all external modules
  snapshot: download a snapshot/development version of all external modules
EOF
	exit 1
}

get_first_line() {
  head -n 1
  cat >/dev/null
}

get_tag () {
	if git -C dockerweb2-temp tag |grep -vFe - >/dev/null; then # ex. RCs
		git -C dockerweb2-temp tag --sort=-version:refname |grep -vFe - |get_first_line
	else
		git -C dockerweb2-temp tag --sort=-version:refname |grep -Fe - |get_first_line
	fi
}

get_special () {
	if [ ! -e "$2" ]; then
		rm -rf dockerweb2-temp
		git clone --bare "https://github.com/Icinga/${1}.git" dockerweb2-temp

		case "$MODE" in
			release)
				REF="$(get_tag)"
				;;
			snapshot)
				case "$2" in
					icingaweb2/modules/incubator)
						# "HINT: Do NOT install the GIT master, it will not work!"
						# https://github.com/Icinga/icingaweb2-module-incubator/blob/master/README.md
						REF="$(get_tag)"
						;;
					icinga-php/*)
						# Special branch that contains vendored dependencies missing in HEAD
						REF=snapshot/nightly
						;;
					*)
						REF=HEAD
						;;
				esac
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

MODE="$1"
case "$MODE" in
	release|snapshot) ;;
	*) usage ;;
esac

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
get_special L10n icinga-L10n
get_mod pdfexport
get_mod reporting
get_mod vspheredb
get_mod x509
