# BlasterMC Mobile 11.0 — ATLAS

A complete active SwiftUI screen redesign with an independent layout system:
- New ATLAS navigation shell, splash, secure login/MFA, home, world, store, season, profile, news and admin center.
- Light stone and porcelain surfaces, navy/blue, copper and amber. No green/purple UI palette, no fake voxel island image.
- Fixed the prior root cause of overlapping/invisible text: the shared legacy StudioPanel also now explicitly wraps multiple children in a VStack. ATLAS cards, banners and screens all use explicit vertical layout and natural text heights.
- Real API content preserved for profile, credit, products, news, rankings, status and admin endpoints. No invented products or payment functionality.
- Season prize schedule shown independent of API reward payload: 1st ₺5,000; 2nd ₺1,500; 3rd ₺1,000. Total ₺7,500.
- Profile logout always above bottom navigation, admin route visible only for server-confirmed isAdmin, admin operations continue to require backend authorization.
- Public news never exposes notification preferences; those appear in the admin control room only.
- iOS 17+, bundle com.blastermc.mobile, version 11.0.0 (110).
- CI compilation does not substitute for on-device layout/accessibility testing.
