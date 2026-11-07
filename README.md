# Boilerplate for C# Alibre Design Add-Ons, with Automated Builds!

**An easy starting point for developing your own Alibre Design add-on using C#, _with_ proper automated builds/releases, _without_ self-hosted runners _or_ unauthorized publishing of proprietary Alibre DLLs!**

[![CI](https://github.com/k4kfh/alibre-csharp-addon-boilerplate/actions/workflows/ci.yml/badge.svg)](https://github.com/k4kfh/alibre-csharp-addon-boilerplate/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This repository contains a dummy add-on for Alibre Design, written in C#, with reliable builds, installers and versioning already set up. **This is not a useful add-on! It's a starting point for you to build your own open-source Alibre Design add-ons, with some convenient build/test automations already set up.**

## What you get

- **Automated builds:** GitHub Actions compiles your add-on on GitHub's own machines, with no server to maintain.
- **A real installer:** a Setup program with a proper uninstall, and a portable ZIP for manual installs. These assets are generated consistently for every release.
- **Installer tests:** every build really installs, upgrades and uninstalls on a clean Windows machine. This ensures nothing ever goes sideways with the installer/uninstaller system without you knowing.
- **One-command releases:** push a version tag, and CI compiles, tests and publishes the release with checksums and notes from your changelog.
- **One place for details:** your add-on's name, links, copyright and GUIDs live in [`project.psd1`](project.psd1).
  The version comes from the release tag.
- **No need to expose proprietary DLLs (like ``AlibreX.dll``) in your public repository:** see [BUILD-SYSTEM.md](BUILD-SYSTEM.md) for how that works.

## How to Start Your Own Add-On with this Repository

1. On GitHub, choose **Use this template** to create your repository, then clone it.
2. Run the included setup script to set it up with your add-on's details, which also creates your own GUIDs:

   ```powershell
   ./scripts/new-project.ps1 -AddOnName GearTools -FriendlyName "Gear Tools" -Repository you/gear-tools -Description "Creates gears."
   ```

3. Review the changes with `git diff`, then commit and push. CI should pass straight away, testing the installer with a placeholder DLL.
4. Replace the button and window in [`src/AddOn/AddOnInterface.cs`](src/AddOn/AddOnInterface.cs) with your add-on's real functionality.
5. Follow [Setting up compiling in CI](BUILD-SYSTEM.md#setting-up-compiling-in-ci) so CI can compile the real add-on.

Until step 5 is done, CI can't compile your add-on or publish releases. After that, [RELEASING.md](RELEASING.md)
walks through publishing a release.

## Try the dummy add-on

You need Visual Studio with .NET desktop development, .NET Framework 4.8, and Alibre Design V28 or later.

```powershell
./scripts/build.ps1 -Version 0.0.0
./scripts/verify-binary.ps1 -Version 0.0.0
```

Close Alibre Design, then run this from an administrator PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\install.ps1
```

Start Alibre. **Dummy Add-On** is on the ribbon's Add-ons tab. To remove it, close Alibre and run
`deploy\uninstall.ps1` the same way.

## Licensing

This boilerplate repository is released under the [MIT License](LICENSE). Any add-ons you develop using this repo can use any license you like, and doesn't even have to be open source. Just make sure you update `LICENSE` and `project.psd1` to reflect your licensing choices.

Alibre and Alibre Design are trademarks of their owners. This project isn't affiliated with or endorsed by
Alibre, LLC. It includes no Alibre files, and needs your own licensed copy of Alibre Design to run.
