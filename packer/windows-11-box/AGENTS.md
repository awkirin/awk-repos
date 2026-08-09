# Repository Guidelines

## Project Structure & Module Organization

This repository builds a Windows 11 25H2 Pro RU Vagrant box for VirtualBox. `windows11.pkr.hcl` defines the Packer source, provisioning order, and Vagrant post-processor. Root PowerShell entry points orchestrate the workflow: `Build-Box.ps1` builds the box, `Test-Box.ps1` performs a first-boot smoke test, and the remaining root scripts prepare installation media. Guest provisioning lives in `scripts/`; unattended setup templates live in `answer_files/`; `vagrant/Vagrantfile.template` supplies box defaults. Treat `.generated/`, `output/`, `output-*`, `packer_cache/`, and `.smoke-test/` as disposable generated content.

## Build, Test, and Development Commands

- `./Build-Box.ps1` validates the ISO checksum, initializes and validates Packer, then creates `output/windows11-25h2-pro-ru-virtualbox.box`.
- `./Build-Box.ps1 -EditionIndex <n>` skips automatic DISM-based edition discovery.
- `./Build-Box.ps1 -Force` replaces an existing build artifact.
- `packer fmt -check .` checks HCL formatting without changing files.
- `packer validate -var "edition_index=<n>" .` performs a quick configuration check; a valid local ISO and answer-media variables may still be required.
- `./Test-Box.ps1` adds the built box temporarily, boots it with Vagrant, checks guest settings over WinRM, and cleans up.

Building requires Packer 1.14+, Vagrant 2.4.9+, VirtualBox 7.2+, and the checksum-matched Windows ISO documented in the configuration.

## Coding Style & Naming Conventions

Use two-space indentation in PowerShell, HCL, and Ruby templates. PowerShell scripts should set `$ErrorActionPreference = "Stop"`, use approved Verb-Noun names, camelCase local variables, PascalCase parameters, and `-LiteralPath` for known paths. Keep Packer files formatted with `packer fmt`. Name provisioning scripts with lowercase kebab-case verbs, such as `scripts/configure-windows.ps1`.

## Testing Guidelines

There is no unit-test framework or coverage target. Changes to provisioning must extend `scripts/verify.ps1` with explicit failure messages. Run the full build before `./Test-Box.ps1`; the smoke test is destructive only to its temporary Vagrant box and `.smoke-test/` directory.

## Commit & Pull Request Guidelines

Recent commit messages are placeholders (`123`), so no reliable historical convention exists. Use concise imperative subjects, preferably Conventional Commit style, for example `fix: preserve WinRM after sysprep`. Pull requests should explain image behavior changes, list validation commands, link relevant issues, and include screenshots only for visible Windows UI changes.

## Security & Configuration Tips

Never commit Windows ISOs, generated boxes, caches, or credentials. The `vagrant`/`vagrant` account and unencrypted WinRM are intentional only for trusted local development; do not present this image as production-hardened.
