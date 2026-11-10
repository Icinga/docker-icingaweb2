package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strconv"

	"github.com/go-ini/ini"
	"github.com/wk8/go-ordered-map/v2"
)

func renderConfigs(cfgs map[string]*orderedmap.OrderedMap[string, map[string]string]) error {
	tempDir, errMT := os.MkdirTemp("", "")
	if errMT != nil {
		return errMT
	}
	defer os.RemoveAll(tempDir)

	webConfig := path.Join(tempDir, "rendered-config")
	legacyConfig := path.Join(tempDir, "legacy-config")
	icingawebConfigdir := path.Join(tempDir, "bootstrap-config")
	enModsDir := path.Join(icingawebConfigdir, "enabledModules")
	env := append(os.Environ(), "ICINGAWEB_CONFIGDIR="+icingawebConfigdir)

	for _, dir := range []string{enModsDir, webConfig, legacyConfig} {
		if err := os.MkdirAll(dir, dirMode); err != nil {
			return err
		}
	}

	if err := os.Symlink("/entrypoint-db-init", path.Join(enModsDir, "dockerentrypoint")); err != nil {
		return err
	}

	for name, cfg := range cfgs {
		relative := name + ".ini"
		absolute := path.Join(webConfig, relative)
		legacy := path.Join(legacyConfig, relative)

		logf("trace1", "Rendering %#v", relative)

		for _, dir := range []string{absolute, legacy} {
			if err := os.MkdirAll(path.Dir(dir), dirMode); err != nil {
				return err
			}
		}

		jsn := &bytes.Buffer{}
		webCfg := &bytes.Buffer{}

		if err := json.NewEncoder(jsn).Encode(cfg); err != nil {
			return err
		}

		cmd := exec.Command("icingacli", "dockerentrypoint", "config", "render")

		cmd.Env = env
		cmd.Stdin = jsn
		cmd.Stdout = webCfg
		cmd.Stderr = os.Stderr

		if err := cmd.Run(); err != nil {
			return err
		}

		if err := os.WriteFile(absolute, webCfg.Bytes(), 0o640); err != nil {
			return err
		}

		legacyIni := ini.Empty()

		for pair := cfg.Oldest(); pair != nil; pair = pair.Next() {
			section := legacyIni.Section(pair.Key)

			for k, v := range pair.Value {
				if _, err := section.NewKey(k, v); err != nil {
					return err
				}
			}
		}

		if err := legacyIni.SaveTo(legacy); err != nil {
			return err
		}
	}

	compat := os.Getenv("ICINGAWEB_SERIALIZER_COMPAT")
	if compat == "" {
		atLeast215, err15 := icingawebAtLeast(2, 15)
		if err15 != nil {
			return err15
		}

		if atLeast215 {
			compat = "0"
		} else {
			compat = "1"
		}
	}

	switch compat {
	case "1":
		return installConfigs(cfgs, legacyConfig)
	case "0":
		return installConfigs(cfgs, webConfig)
	default:
		return fmt.Errorf("bad ICINGAWEB_SERIALIZER_COMPAT (expected 1 or 0): %#v", compat)
	}
}

// installConfigs copies the rendered .ini files from renderedConfig to confDir.
// Neither chmod existing directories nor existing files.
func installConfigs(cfgs map[string]*orderedmap.OrderedMap[string, map[string]string], renderedConfig string) error {
	for name := range cfgs {
		relative := name + ".ini"

		content, errRF := os.ReadFile(path.Join(renderedConfig, relative))
		if errRF != nil {
			return errRF
		}

		file := path.Join(confDir, relative)
		logf("trace1", "Installing %#v", file)

		if err := os.MkdirAll(path.Dir(file), dirMode); err != nil {
			return err
		}

		if err := os.WriteFile(file, content, 0o640); err != nil {
			return err
		}
	}

	return nil
}

var icingawebVersion = regexp.MustCompile(`\Av(\d+)\.(\d+)\.`)

// icingawebAtLeast tells whether the installed Icinga Web is at least major.minor.
func icingawebAtLeast(major, minor int) (bool, error) {
	file := "/usr/share/icingaweb2/VERSION"

	version, errRF := os.ReadFile(file)
	if errRF != nil {
		return false, errRF
	}

	match := icingawebVersion.FindSubmatch(version)
	if match == nil {
		return false, fmt.Errorf("can't find Icinga Web version in %#v", file)
	}

	// The regex guarantees valid numbers
	actualMajor, _ := strconv.Atoi(string(match[1]))
	actualMinor, _ := strconv.Atoi(string(match[2]))

	return actualMajor > major || actualMajor == major && actualMinor >= minor, nil
}
