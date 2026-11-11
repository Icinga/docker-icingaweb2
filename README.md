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
option = "value"
```

Icinga Web 2 itself renders these files. It always quotes the values
and escapes any `"` and `\` in them, so special characters need no INI quoting.
`icingaweb.roles.Administrators.permissions='*'` from the example above becomes:

```ini
[Administrators]
permissions = "*"
```

Consult the [Icinga Web 2 configuration documentation]
on which .ini files there are.

#### `ICINGAWEB_SERIALIZER_COMPAT`

Older images wrote the .ini files with a different serializer
which Icinga Web 2 didn't always interpret as intended.
For example, a value containing a backtick ended up with extra `""` at both ends.
`ICINGAWEB_SERIALIZER_COMPAT` chooses which serializer to use:

* `0`: Icinga Web 2 renders the .ini files as described above.
  This is the default for images with Icinga Web 2 v2.15.0 or later.
* `1`: The old serializer renders the .ini files.
  This is the default for images with older Icinga Web 2 versions,
  so that rebuilds of them don't change their behavior.

With `1`, the container logs a warning for every option
which Icinga Web 2 would interpret differently with `0`, for example:

`Icinga Web would interpret option "password" in section "icingaweb_db" of "resources.ini" differently with v2.15 or ICINGAWEB_SERIALIZER_COMPAT=0`

To not leak secrets, the warning doesn't show the values.

#### Migrating to `ICINGAWEB_SERIALIZER_COMPAT=0`

1. Start the container with `ICINGAWEB_SERIALIZER_COMPAT=1` and check the log for the warnings above.
2. If you put INI quote characters into values to work around the old serializer,
   e.g. `password="123456"` with the `"` being part of the value, remove them.
   Icinga Web 2 quotes all values by itself and would keep such characters as part of the value.
3. Start the container with `ICINGAWEB_SERIALIZER_COMPAT=0` (or without it, as of v2.15.0).

Shell or YAML quoting is a different thing. Your shell or YAML parser removes it,
so it never reaches the container. Keep it where your shell or YAML needs it:

```bash
# The shell removes the single quotes. The value is 123#456. Keep them.
-e 'icingaweb.resources.icingaweb_db.password=123#456'
# The value is "123#456" including the double quotes. Remove these.
-e 'icingaweb.resources.icingaweb_db.password="123#456"'
```

```yaml
environment:
  # YAML removes the single quotes. The value is *. Keep them.
  icingaweb.roles.Administrators.permissions: '*'
```

#### Known limitation: leading and trailing whitespace

Icinga Web 2 strips leading and trailing whitespace from values when rendering .ini files.
This includes passwords, e.g. `icingaweb.resources.icingaweb_db.password`.
So with `ICINGAWEB_SERIALIZER_COMPAT=0`, ` 123456 ` becomes `123456`.
Avoid such values.

### External authentication

When using `icingaweb.authentication.autologin.backend: external`, the Username needs to be passed in the `X-Remote-User` header.

## Build it yourself

```bash
git clone https://github.com/Icinga/icingaweb2.git
#pushd icingaweb2
#git checkout v2.9.0
#popd

./build.bash ./icingaweb2
```

To use a Docker-compatible CLI other than `docker`, e.g. Podman,
pass it as the fifth argument:

```bash
./build.bash ./icingaweb2 release local test podman
```

[Icinga Web 2]: https://github.com/Icinga/icingaweb2
[Docker]: https://www.docker.com
[Icinga Web 2 configuration documentation]: https://icinga.com/docs/icingaweb2/latest/doc/03-Configuration/
