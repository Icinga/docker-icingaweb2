<!-- Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+ -->

# Icinga Web 2 - Docker image

This image integrates [Icinga Web 2] into your [Docker] environment.

## Usage

```bash
docker run --rm -d \
	-p 8080:8080 \
	-v icingaweb:/data \
	-e icingaweb.enabledModules=icingadb \
	-e icingaweb.passwords.icingaweb2.icingaadmin=123456 \
	-e icingaweb.authentication.icingaweb2.backend=db \
	-e icingaweb.authentication.icingaweb2.resource=icingaweb_db \
	-e icingaweb.config.global.config_backend=db \
	-e icingaweb.config.global.config_resource=icingaweb_db \
	-e icingaweb.config.logging.log=php \
	-e icingaweb.groups.icingaweb2.backend=db \
	-e icingaweb.groups.icingaweb2.resource=icingaweb_db \
	-e icingaweb.modules.icingadb.config.icingadb.resource=icingadb \
	-e icingaweb.modules.icingadb.redis.redis1.host=2001:db8::192.0.2.18 \
	-e icingaweb.modules.icingadb.redis.redis1.port=6379 \
	-e icingaweb.modules.icingadb.commandtransports.icinga2.transport=api \
	-e icingaweb.modules.icingadb.commandtransports.icinga2.host=2001:db8::192.0.2.9 \
	-e icingaweb.modules.icingadb.commandtransports.icinga2.username=root \
	-e icingaweb.modules.icingadb.commandtransports.icinga2.password=123456 \
	-e icingaweb.resources.icingaweb_db.type=db \
	-e icingaweb.resources.icingaweb_db.db=mysql \
	-e icingaweb.resources.icingaweb_db.host=2001:db8::192.0.2.13 \
	-e icingaweb.resources.icingaweb_db.dbname=icingaweb \
	-e icingaweb.resources.icingaweb_db.username=icingaweb \
	-e icingaweb.resources.icingaweb_db.password=123456 \
	-e icingaweb.resources.icingaweb_db.charset=utf8mb4 \
	-e icingaweb.resources.icingadb.type=db \
	-e icingaweb.resources.icingadb.db=mysql \
	-e icingaweb.resources.icingadb.host=2001:db8::192.0.2.113 \
	-e icingaweb.resources.icingadb.dbname=icingadb \
	-e icingaweb.resources.icingadb.username=icingaweb \
	-e icingaweb.resources.icingadb.password=123456 \
	-e icingaweb.resources.icingadb.charset=utf8mb4 \
	-e icingaweb.roles.Administrators.users=icingaadmin \
	-e icingaweb.roles.Administrators.permissions='*' \
	-e icingaweb.roles.Administrators.groups=Administrators \
	icinga/icingaweb2
```

The container listens on port 8080 and expects a volume on `/data`.
To configure it, do one of the following:

* Run the setup wizard as usual.
  It will store all configuration in `/data/etc/icingaweb2`.
  Hint: `docker run --rm -v icingaweb:/data icinga/icingaweb2 icingacli setup token create`
* Provide configuration files in `/data/etc/icingaweb2` by yourself.
  Consult the [Icinga Web 2 configuration documentation]
  on which .ini files there are.
* Provide environment variables as shown above.

### Environment variables

`icingaweb.enabledModules` is a comma-separated set
of the only modules to be enabled.

Variables like `icingaweb.passwords.backend.user=pass`
ensures a user "user" with the password "pass" to be present
in the database authentication backend "backend".

Variables like `icingaweb.dir.subdir.file.section.option=value` create .ini
files like `/data/etc/icingaweb2/dir/subdir/file.ini` with content like this:

```ini
[section]
option = value
```

Consult the [Icinga Web 2 configuration documentation]
on which .ini files there are.

## Build it yourself

```bash
git clone https://github.com/Icinga/icingaweb2.git
#pushd icingaweb2
#git checkout v2.9.0
#popd

./build.bash ./icingaweb2
```

[Icinga Web 2]: https://github.com/Icinga/icingaweb2
[Docker]: https://www.docker.com
[Icinga Web 2 configuration documentation]: https://icinga.com/docs/icingaweb2/latest/doc/03-Configuration/
