POWERSHELL ?= powershell.exe

.NOTPARALLEL:
.PHONY: help test build rebuild smoke verify

help:
	@$(POWERSHELL) -NoLogo -NoProfile -Command "Write-Host 'make test     Fast project checks'; Write-Host 'make build    Build the box'; Write-Host 'make rebuild  Force rebuild'; Write-Host 'make smoke    Test an existing box'; Write-Host 'make verify   Rebuild and smoke-test'"

test:
	$(POWERSHELL) -NoLogo -NoProfile -File .\tests\Test-Project.ps1

build:
	$(POWERSHELL) -NoLogo -NoProfile -File .\tools\Build-Box.ps1

rebuild:
	$(POWERSHELL) -NoLogo -NoProfile -File .\tools\Build-Box.ps1 -Force

smoke:
	$(POWERSHELL) -NoLogo -NoProfile -File .\tests\Test-Box.ps1

verify: test rebuild smoke
