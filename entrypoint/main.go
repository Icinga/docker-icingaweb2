package main

import (
	"bufio"
	"fmt"
	"github.com/go-ini/ini"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

const confDir = "/data/etc/icingaweb2"
const dirMode = 0750

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

	if os.Getpid() == 1 {
		logf("info", "Initializing /data as we're the init process")

		logf("debug", "Creating %#v", enModsDir)
		if errMA := os.MkdirAll(enModsDir, dirMode); errMA != nil {
			return errMA
		}

		logf("debug", "Translating env vars to .ini config")

		cfgs := map[string]*ini.File{}
		var enabledModules map[string]struct{} = nil

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
							file := path.Join(directive[:len(directive)-2]...)
							cfg, ok := cfgs[file]

							if !ok {
								cfg = ini.Empty()
								cfgs[file] = cfg
							}

							_, errNK := cfg.Section(directive[len(directive)-2]).NewKey(
								strings.ToLower(directive[len(directive)-1]), kv[1],
							)
							if errNK != nil {
								return errNK
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

				errSl := os.Symlink(path.Join("/usr/share/icingaweb2/modules", mod), path.Join(enModsDir, mod))
				if errSl != nil {
					return errSl
				}
			}
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

var out = bufio.NewWriter(os.Stderr)

func logf(severity, format string, a ...interface{}) {
	_, _ = fmt.Fprintf(out, "[%s] ", time.Now().Format("Mon Jan 2 15:04:05.999999999 2006"))
	_, _ = fmt.Fprintf(out, "[docker_entrypoint:%s] [pid %d] DOCKERE: ", severity, os.Getpid())
	_, _ = fmt.Fprintf(out, format, a...)

	_, _ = fmt.Fprintln(out)
	_ = out.Flush()
}
