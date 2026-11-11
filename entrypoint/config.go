package main

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path"

	"github.com/wk8/go-ordered-map/v2"
)

func renderConfigs(cfgs map[string]*orderedmap.OrderedMap[string, map[string]string]) error {
	tempDir, errMT := os.MkdirTemp("", "")
	if errMT != nil {
		return errMT
	}
	defer os.RemoveAll(tempDir)

	renderedConfig := path.Join(tempDir, "rendered-config")
	icingawebConfigdir := path.Join(tempDir, "bootstrap-config")
	enModsDir := path.Join(icingawebConfigdir, "enabledModules")
	env := append(os.Environ(), "ICINGAWEB_CONFIGDIR="+icingawebConfigdir)

	for _, dir := range []string{enModsDir, renderedConfig} {
		if err := os.MkdirAll(dir, dirMode); err != nil {
			return err
		}
	}

	if err := os.Symlink("/entrypoint-db-init", path.Join(enModsDir, "dockerentrypoint")); err != nil {
		return err
	}

	for name, cfg := range cfgs {
		relative := name + ".ini"
		absolute := path.Join(renderedConfig, relative)

		logf("trace1", "Rendering %#v", relative)

		if err := os.MkdirAll(path.Dir(absolute), dirMode); err != nil {
			return err
		}

		jsn := &bytes.Buffer{}
		ini := &bytes.Buffer{}

		if err := json.NewEncoder(jsn).Encode(cfg); err != nil {
			return err
		}

		cmd := exec.Command("icingacli", "dockerentrypoint", "config", "render")

		cmd.Env = env
		cmd.Stdin = jsn
		cmd.Stdout = ini
		cmd.Stderr = os.Stderr

		if err := cmd.Run(); err != nil {
			return err
		}

		if err := os.WriteFile(absolute, ini.Bytes(), 0o640); err != nil {
			return err
		}
	}

	return installConfigs(cfgs, renderedConfig)
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
