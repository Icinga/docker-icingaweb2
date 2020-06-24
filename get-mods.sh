#!/bin/bash
set -exo pipefail

BRANCH="$1"

get_special () {
	if [ ! -e "icingaweb2/modules/$3" ]; then
		case "$3" in
			incubator|ipl|reactbundle)
				REF="$2"
				;;
			*)
				if [ -n "$BRANCH" ]; then
					REF="$BRANCH"
				else
					REF="$2"
				fi
				;;
		esac

		rm -rf dockerweb2-temp
		git clone --bare "https://github.com/Icinga/${1}.git" dockerweb2-temp
		git -C dockerweb2-temp archive "--prefix=icingaweb2/modules/${3}/" "$REF" |tar -x
		rm -rf dockerweb2-temp
	fi
}

get_mod () {
	get_special "icingaweb2-module-$1" "$2" "$1"
}

get_mod audit 0aa5f547a9829fae82df7481f1a1c871c5c75ac4 # v1.0.1
get_mod aws 0a889cc8eb60308e0dbe12e458298c1ef1a3553d # v1.0.0
get_mod businessprocess 346ace79d0a2908e7cc73ab832233ab58c63da6a # v2.3.0
get_mod cube 62a3d0605efaf1d20f8023fee740eb4c457ac835 # v1.1.1
get_mod director 9c95fb8680f6f389ca24ff6e41d9002185596cb3 # v1.7.2
get_mod fileshipper c800286277fbd7676573a17026071ebc1c85de7e # v1.1.0
get_mod graphite cb2a94397529f5a4b73d423fe89fabf2b0f064a6 # v1.1.0
get_special icingadb-web 2c0662c420617712bd26234da550dcf8d4afcdb8 icingadb # v1.0.0-rc1+
get_mod idoreports cdeecede5faeba71b9d83a64be019a0592e5f296 # v0.9.1
get_mod incubator f24a26f51d37688e85617da713be54c4e853e462 # v0.5.0
get_mod ipl dd3e987a4b7967d087e1a69f6ebeca4ed4a5d89d # v0.5.0
get_mod pdfexport 94f00d13b842ffe68de032b216c721957917ed0e # v0.9.1
get_mod reactbundle 8b8c9689e5883cd890fb92b7ca22659af56b2c94 # v0.7.0
get_mod reporting 5d59f5001ad8cfe316f9e1570f8ebbdad08b9261 # v0.9.2
get_mod vspheredb 5bc3546ce53f59c37814e8572823a2556b0507a7 # v1.1.0
get_mod x509 0997bf734b54b62582b3a000c4f04980a583a9e2 # v1.0.0
