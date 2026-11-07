# Everything that identifies this add-on, in one place. The build copies these into the .adc file, the DLL's
# properties, the installer and the portable ZIP. The version isn't here: it comes from the release tag.
# scripts\new-project.ps1 rewrites this file for a new project.
@{
    # File name for the DLL, .adc and installer, and the install folder's name. Letters and digits only.
    AddOnName        = 'DummyAddOn'
    # The name shown in Alibre's ribbon and Add-On Manager.
    FriendlyName     = 'Dummy Add-On'
    # The name shown by the installer and in Windows' Installed apps list.
    Title            = 'Dummy Add-On for Alibre Design'
    Description      = 'A minimal example add-on with one button that opens a welcome window.'
    Publisher        = 'k4kfh'
    # The notice must also appear in LICENSE; scripts\verify-binary.ps1 checks that it does.
    Copyright        = 'Copyright (c) 2026 k4kfh'
    # The Copyright field in Alibre's Add-On Manager. It must include the notice above. Change it if your add-on
    # uses another license, or its source code isn't public.
    CopyrightText    = 'Copyright (c) 2026 k4kfh. Released under the MIT License. See https://github.com/k4kfh/alibre-csharp-addon-boilerplate for the full source code and license text.'
    # Lines for the Add-On Manager's description, after Description and the version line. Use @() for none.
    DescriptionDetails = @(
        'Add-On Documentation and Source Code : https://github.com/k4kfh/alibre-csharp-addon-boilerplate'
        'To Report a Problem : https://github.com/k4kfh/alibre-csharp-addon-boilerplate/issues/new'
    )
    SourceUrl       = 'https://github.com/k4kfh/alibre-csharp-addon-boilerplate'
    ReportProblemUrl = 'https://github.com/k4kfh/alibre-csharp-addon-boilerplate/issues/new'
    ReleasesUrl      = 'https://github.com/k4kfh/alibre-csharp-addon-boilerplate/releases'

    # Each add-on needs its own GUIDs. Never change them after your first release: upgrades and uninstalls
    # depend on them, and two add-ons sharing an Identifier overwrite each other in Alibre.
    Identifier       = '{46C80F03-8F3F-41B3-9615-9DF167D2C195}'
    InstallerAppId   = '{AC4A1311-1246-4798-90C2-7429A6AB2C74}'

    # Which files to use from the private repository holding Alibre's DLLs. See BUILD-SYSTEM.md. That
    # repository's name isn't here: it's in the ALIBRE_SDK_REPOSITORY secret, so it stays out of public view.
    # SdkCommit is a full commit SHA, so a build can't change Alibre versions without an edit here.
    SdkCommit       = 'dc0a0f00f15fee69f617eae072721a7260008cb4'
    SdkFolder        = 'v28'
}
