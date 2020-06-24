package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
)

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
