# {{Title}}

[![CI](https://github.com/{{Repository}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{Repository}}/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/{{Repository}}?include_prereleases)](https://github.com/{{Repository}}/releases)

{{Description}}

## Requirements

- Alibre Design V28 or later on 64-bit Windows.
- Administrator rights to install.

## Install

1. Download `{{AddOnName}}-Setup-vX.Y.Z.exe` from [Releases](https://github.com/{{Repository}}/releases).
2. Save your work and close Alibre Design.
3. Run the installer and approve the Windows prompt.
4. Start Alibre Design. {{FriendlyName}} is on the ribbon's Add-ons tab.

The installer isn't code-signed, so Windows SmartScreen may warn you. To check your download, compare this
command's output with the matching line in the release's `SHA256SUMS.txt`:

```powershell
Get-FileHash .\{{AddOnName}}-Setup-vX.Y.Z.exe -Algorithm SHA256
```

## Uninstall

Close Alibre Design, then uninstall **{{Title}}** from Windows **Installed apps**.

## Build from source

You need Visual Studio with .NET desktop development, .NET Framework 4.8, and Alibre Design installed.

```powershell
./scripts/build.ps1 -Version 0.0.0
./scripts/verify-binary.ps1 -Version 0.0.0
```

See [BUILD-SYSTEM.md](BUILD-SYSTEM.md) for how the build and releases work.

## License

See [LICENSE](LICENSE).

Alibre and Alibre Design are trademarks of their owners. This project isn't affiliated with or endorsed by
Alibre, LLC. It includes no Alibre files, and needs your own licensed copy of Alibre Design to run.
