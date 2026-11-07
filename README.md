# C# Add-On Boilerplate for Alibre Design

[![CI](https://github.com/k4kfh/alibre-csharp-addon-boilerplate/actions/workflows/ci.yml/badge.svg)](https://github.com/k4kfh/alibre-csharp-addon-boilerplate/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A starting point for open-source Alibre Design add-ons, with reliable builds, installers and versioning already
set up. **The build system is the point of this repository.** The add-on itself is a dummy: one button on the
ribbon that opens a welcome window, ready to be replaced with yours.

## What you get

- **Automated builds:** GitHub Actions compiles your add-on on GitHub's own machines, with no server to maintain.
- **A real installer:** a Setup program with a proper uninstall, and a portable ZIP for manual installs.
- **Installer tests:** every build really installs, upgrades and uninstalls on a clean Windows machine.
- **One-command releases:** push a version tag, and CI compiles, tests and publishes the release with
  checksums and notes from your changelog.
- **One place for details:** your add-on's name, links, copyright and GUIDs live in [`project.psd1`](project.psd1).
  The version comes from the release tag.
- **No Alibre files in your public repository:** see [BUILD-SYSTEM.md](BUILD-SYSTEM.md) for how that works.

## Start your add-on

1. On GitHub, choose **Use this template** to create your repository, then clone it.
2. Set it up with your details, which also creates your own GUIDs:

   ```powershell
   ./scripts/new-project.ps1 -AddOnName GearTools -FriendlyName "Gear Tools" -Repository you/gear-tools -Description "Creates gears."
   ```

3. Review the changes with `git diff`, then commit and push. CI should pass straight away, testing the
   installer with a placeholder DLL.
4. Replace the button and window in [`src/AddOn/AddOnInterface.cs`](src/AddOn/AddOnInterface.cs) with your add-on.
5. Follow [Setting up compiling in CI](BUILD-SYSTEM.md#setting-up-compiling-in-ci) so CI can compile the real add-on.

Until step 5 is done, CI can't compile your add-on or publish releases.

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

## What's documented and what isn't

The add-on uses Alibre's documented `IAlibreAddOn` interfaces for its button, and nothing else from Alibre.

**One part isn't described in Alibre's documentation: how Alibre loads a C# add-on.** Alibre's docs name C# as a
supported language, but their integrated add-on guide and samples use C++. This boilerplate uses
`<DLL type="Managed">` in the `.adc` file with a class named `AlibreAddOnAssembly.AlibreAddOn`. Alibre's own Alibre
Script add-on loads this way, and so do community add-ons, so it's in real use, but a future Alibre version could
change it.

This has been tested on Alibre Design V28 only.

## License

[MIT](LICENSE). Your copy can use any license you like, once you update `LICENSE` and `project.psd1`.

Alibre and Alibre Design are trademarks of their owners. This project isn't affiliated with or endorsed by
Alibre, LLC. It includes no Alibre files, and needs your own licensed copy of Alibre Design to run.
