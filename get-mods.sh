#!/bin/bash
set -exo pipefail

if [ ! -e 'icingaweb2/modules/audit' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-audit.git' dockerweb2-temp
	# v1.0.1
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/audit/' 0aa5f547a9829fae82df7481f1a1c871c5c75ac4 |tar -x
fi

if [ ! -e 'icingaweb2/modules/aws' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-aws.git' dockerweb2-temp
	# v1.0.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/aws/' 0a889cc8eb60308e0dbe12e458298c1ef1a3553d |tar -x
fi

if [ ! -e 'icingaweb2/modules/businessprocess' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-businessprocess.git' dockerweb2-temp
	# v2.3.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/businessprocess/' 346ace79d0a2908e7cc73ab832233ab58c63da6a |tar -x
fi

if [ ! -e 'icingaweb2/modules/cube' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-cube.git' dockerweb2-temp
	# v1.1.1
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/cube/' 62a3d0605efaf1d20f8023fee740eb4c457ac835 |tar -x
fi

if [ ! -e 'icingaweb2/modules/director' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-director.git' dockerweb2-temp
	# v1.7.2
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/director/' 9c95fb8680f6f389ca24ff6e41d9002185596cb3 |tar -x
fi

if [ ! -e 'icingaweb2/modules/fileshipper' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-fileshipper.git' dockerweb2-temp
	# v1.1.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/fileshipper/' c800286277fbd7676573a17026071ebc1c85de7e |tar -x
fi

if [ ! -e 'icingaweb2/modules/graphite' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-graphite.git' dockerweb2-temp
	# v1.1.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/graphite/' cb2a94397529f5a4b73d423fe89fabf2b0f064a6 |tar -x
fi

if [ ! -e 'icingaweb2/modules/icingadb' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingadb-web.git' dockerweb2-temp
	# v1.0.0-rc1+
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/icingadb/' 2c0662c420617712bd26234da550dcf8d4afcdb8 |tar -x
fi

if [ ! -e 'icingaweb2/modules/idoreports' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-idoreports.git' dockerweb2-temp
	# v0.9.1
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/idoreports/' cdeecede5faeba71b9d83a64be019a0592e5f296 |tar -x
fi

if [ ! -e 'icingaweb2/modules/incubator' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-incubator.git' dockerweb2-temp
	# v0.5.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/incubator/' f24a26f51d37688e85617da713be54c4e853e462 |tar -x
fi

if [ ! -e 'icingaweb2/modules/ipl' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-ipl.git' dockerweb2-temp
	# v0.5.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/ipl/' dd3e987a4b7967d087e1a69f6ebeca4ed4a5d89d |tar -x
fi

if [ ! -e 'icingaweb2/modules/pdfexport' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-pdfexport.git' dockerweb2-temp
	# v0.9.1
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/pdfexport/' 94f00d13b842ffe68de032b216c721957917ed0e |tar -x
fi

if [ ! -e 'icingaweb2/modules/reactbundle' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-reactbundle.git' dockerweb2-temp
	# v0.7.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/reactbundle/' 8b8c9689e5883cd890fb92b7ca22659af56b2c94 |tar -x
fi

if [ ! -e 'icingaweb2/modules/reporting' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-reporting.git' dockerweb2-temp
	# v0.9.2
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/reporting/' 5d59f5001ad8cfe316f9e1570f8ebbdad08b9261 |tar -x
fi

if [ ! -e 'icingaweb2/modules/vspheredb' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-vspheredb.git' dockerweb2-temp
	# v1.1.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/vspheredb/' 5bc3546ce53f59c37814e8572823a2556b0507a7 |tar -x
fi

if [ ! -e 'icingaweb2/modules/x509' ]; then
	rm -rf dockerweb2-temp
	git clone --bare 'https://github.com/Icinga/icingaweb2-module-x509.git' dockerweb2-temp
	# v1.0.0
	git -C dockerweb2-temp archive '--prefix=icingaweb2/modules/x509/' 0997bf734b54b62582b3a000c4f04980a583a9e2 |tar -x
fi

rm -rf dockerweb2-temp
