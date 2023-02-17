// Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/go-ini/ini"
	"io/fs"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

const wwwdataUid = 33
const dataVolume = "/data"
const modsDir = "/usr/share/icingaweb2/modules"
const dirMode = 0750

var confDir = path.Join(dataVolume, "etc", "icingaweb2")

var enModsDir = path.Join(confDir, "enabledModules")

func main() {
	if err := entrypoint(); err != nil {
		logf("crit", "%s", err.Error())
		os.Exit(1)
	}
}

func entrypoint() error {
	if len(os.Args) < 2 {
		logf("warn", "Nothing to do.")
		return nil
	}

	if os.Getuid() == 0 {
		logf("info", "Giving %s to the www-data user as we're root", dataVolume)

		_ = filepath.WalkDir(dataVolume, func(path string, _ fs.DirEntry, err error) error {
			if err == nil {
				err = os.Lchown(path, wwwdataUid, wwwdataUid)
			}

			if err != nil {
				logf("warn", "Can't chown %s: %s", path, err.Error())
				return filepath.SkipDir
			}

			return nil
		})

		for _, stdio := range [...]string{"/dev/stdout", "/dev/stderr"} {
			logf("info", "Giving %s to the www-data user as we're root", stdio)

			file, err := os.Open(stdio)
			if err != nil {
				return err
			}

			if err := syscall.Fchown(int(file.Fd()), wwwdataUid, wwwdataUid); err != nil {
				return err
			}

			_ = file.Close()
		}

		logf("info", "Dropping privileges as we're root")

		if err := syscall.Setgid(wwwdataUid); err != nil {
			return err
		}

		if err := syscall.Setuid(wwwdataUid); err != nil {
			return err
		}
	}

	if os.Getpid() == 1 {
		logf("info", "Initializing %s as we're the init process", dataVolume)

		for _, dir := range []string{enModsDir, path.Join(dataVolume, "var", "lib", "icingaweb2")} {
			logf("debug", "Creating %#v", dir)
			if errMA := os.MkdirAll(dir, dirMode); errMA != nil {
				return errMA
			}
		}

		logf("debug", "Translating env vars to .ini config")

		cfgs := map[string]*ini.File{}
		var enabledModules map[string]struct{} = nil
		passwords := map[string]map[string]string{}

	EnvVars:
		for _, env := range os.Environ() {
			if kv := strings.SplitN(env, "=", 2); len(kv) == 2 {
				if strings.HasPrefix(kv[0], "icingaweb") {
					if kv[0] = strings.TrimPrefix(kv[0], "icingaweb"); len(kv[0]) > 0 {
						directive := strings.Split(kv[0][1:], kv[0][:1])
						for _, component := range directive {
							if component == "" {
								continue EnvVars
							}
						}

						if len(directive) == 1 {
							if directive[0] == "enabledModules" {
								if enabledModules == nil {
									enabledModules = map[string]struct{}{}
								}

								for _, mod := range strings.Split(kv[1], ",") {
									if mod = strings.TrimSpace(mod); mod != "" {
										enabledModules[mod] = struct{}{}
									}
								}
							}
						} else if len(directive) >= 3 {
							if len(directive) == 3 && directive[0] == "passwords" {
								users, ok := passwords[directive[1]]
								if !ok {
									users = map[string]string{}
									passwords[directive[1]] = users
								}

								users[directive[2]] = kv[1]
							} else {
								file := path.Join(directive[:len(directive)-2]...)
								cfg, ok := cfgs[file]

								if !ok {
									cfg = ini.Empty()
									cfgs[file] = cfg
								}

								_, errNK := cfg.Section(directive[len(directive)-2]).NewKey(
									directive[len(directive)-1], kv[1],
								)
								if errNK != nil {
									return errNK
								}
							}
						}
					}
				}
			}
		}

		for file, cfg := range cfgs {
			file = path.Join(confDir, file+".ini")
			logf("trace1", "Writing %#v", file)

			if errMA := os.MkdirAll(path.Dir(file), dirMode); errMA != nil {
				return errMA
			}

			if errST := cfg.SaveTo(file); errST != nil {
				return errST
			}
		}

		if enabledModules != nil {
			logf("debug", "Enabling/disabling modules")

			mods, errRD := ioutil.ReadDir(enModsDir)
			if errRD != nil {
				return errRD
			}

			for _, mod := range mods {
				mod := mod.Name()
				if _, ok := enabledModules[mod]; ok {
					delete(enabledModules, mod)
				} else {
					logf("trace1", "Disabling module %#v", mod)
					if errRm := os.Remove(path.Join(enModsDir, mod)); errRm != nil {
						return errRm
					}
				}
			}

			for mod := range enabledModules {
				logf("trace1", "Enabling module %#v", mod)

				errSl := os.Symlink(path.Join(modsDir, mod), path.Join(enModsDir, mod))
				if errSl != nil {
					return errSl
				}
			}
		}

		if errID := initDb(passwords); errID != nil {
			return errID
		}
	}

	path := os.Args[1]
	if filepath.Base(path) == path {
		logf("info", "Looking up %#v in $PATH", path)

		abs, errLP := exec.LookPath(path)
		if errLP != nil {
			return errLP
		}

		path = abs
	}

	logf("info", "Running %#v", path)
	return syscall.Exec(path, os.Args[1:], os.Environ())
}

func initDb(passwords map[string]map[string]string) error {
	logf("info", "Checking database resources used as backends")

	{
		enMod := path.Join(enModsDir, "dockerentrypoint")
		if errSl := os.Symlink("/entrypoint-db-init", enMod); errSl != nil {
			return errSl
		}

		defer os.Remove(enMod)
	}

	{
		enMod := path.Join(enModsDir, "setup")

		errSl := os.Symlink(path.Join(modsDir, "setup"), enMod)
		if errSl != nil {
			if le, ok := errSl.(*os.LinkError); !ok || !os.IsNotExist(le.Err) {
				return errSl
			}
		}

		if errSl == nil {
			defer os.Remove(enMod)
		}
	}

	var resources []string
	if errIJ := icingacliJson(&resources, "dockerentrypoint", "db", "backends"); errIJ != nil {
		return errIJ
	}

	for _, resource := range resources {
		logf("debug", "Checking database resource %#v", resource)

		var initialized uint8

		errIJ := icingacliJson(&initialized, "dockerentrypoint", "db", "initialized", "--resource="+resource)
		if errIJ != nil {
			return errIJ
		}

		if initialized == 0 {
			logf("debug", "Importing schema into database resource %#v", resource)

			cmd := exec.Command("icingacli", "dockerentrypoint", "db", "init", "--resource="+resource)
			cmd.Stdout = os.Stderr
			cmd.Stderr = os.Stderr

			if errRn := cmd.Run(); errRn != nil {
				return errRn
			}
		}
	}

	for backend, users := range passwords {
		for name, password := range users {
			logf(
				"info", `Ensuring database authentication backend %#v to have a user %#v with the password "***"`,
				backend, name,
			)

			cmd := exec.Command("icingacli", "dockerentrypoint", "db", "user", "--backend="+backend, "--name="+name)
			cmd.Stdout = os.Stderr
			cmd.Stderr = os.Stderr
			cmd.Env = append(os.Environ(), "PASSWORD="+password)

			if errRn := cmd.Run(); errRn != nil {
				return errRn
			}
		}
	}

	return nil
}

func icingacliJson(v interface{}, arg ...string) error {
	cmd := exec.Command("icingacli", arg...)
	var out bytes.Buffer

	cmd.Stdout = &out
	cmd.Stderr = os.Stderr

	if errRn := cmd.Run(); errRn != nil {
		return errRn
	}

	return json.Unmarshal(out.Bytes(), v)
}

var out = bufio.NewWriter(os.Stderr)

func logf(severity, format string, a ...interface{}) {
	_, _ = fmt.Fprintf(out, "[%s] ", time.Now().Format("Mon Jan 2 15:04:05.999999999 2006"))
	_, _ = fmt.Fprintf(out, "[docker_entrypoint:%s] [pid %d] DOCKERE: ", severity, os.Getpid())
	_, _ = fmt.Fprintf(out, format, a...)

	_, _ = fmt.Fprintln(out)
	_ = out.Flush()
}
