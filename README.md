# BlasterMC Mobile — public iOS build mirror

This repository contains **only** the iOS SwiftUI client and the files needed to produce an unsigned iPhone IPA for development with AltStore. The private working repository remains separate.

- App: BlasterMC Mobile v3.5
- Bundle ID: `com.blastermc.mobile`
- iOS: 17+
- GitHub Actions: select **iOS Build** → **Run workflow**, or push a change to relevant build files.
- After a successful run, download the **BlasterMCMobile-unsigned-IPA** artifact, unzip it, and install the contained `BlasterMCMobile-unsigned.ipa` with AltStore.

This repo does **not** contain the private PHP API implementation, website code, database, signing certificates, or server secrets. **Anything committed here is publicly visible, including Git history.** Keep all credentials in private storage; don't add them to iOS sources or workflow logs.

The IPA is unsigned; this workflow does not distribute a signed App Store build.
