#!/usr/bin/env node
// The npm package `camy` is a launcher. The binary itself ships in one of
// the platform packages listed as optional dependencies; npm installs only
// the one that matches this machine. Nothing is downloaded at install time.
"use strict";
const { spawnSync } = require("child_process");

const packages = {
  "darwin-arm64": "@camy/cli-darwin-arm64",
  "darwin-x64": "@camy/cli-darwin-x64",
  "linux-arm64": "@camy/cli-linux-arm64",
  "linux-x64": "@camy/cli-linux-x64",
};
const installer = "curl -fsSL https://camy.ai/cli/install.sh | sh";
const key = `${process.platform}-${process.arch}`;
const pkg = packages[key];
if (!pkg) {
  process.stderr.write(`camy: no npm build for ${key}. Use the installer instead: ${installer}\n`);
  process.exit(1);
}
let bin;
try {
  bin = require.resolve(`${pkg}/bin/camy`);
} catch {
  process.stderr.write(`camy: the platform package ${pkg} is missing. Reinstall with optional dependencies enabled (npm install -g @camy/cli), or use the installer: ${installer}\n`);
  process.exit(1);
}
const result = spawnSync(bin, process.argv.slice(2), { stdio: "inherit" });
if (result.error) {
  process.stderr.write(`camy: ${result.error.message}\n`);
  process.exit(1);
}
if (result.signal) {
  process.kill(process.pid, result.signal);
}
// Exit codes are a public API (docs/exit-codes.md); pass them through untouched.
process.exit(result.status === null ? 1 : result.status);
