# BlasterMC Mobile 13.0 — REALM

REALM is a product redesign, not a palette-only update.

## Experience
- Rebuilt the home screen around a custom vector portal illustration, a live network console, a horizontal launch rail, a podium for the published cash prizes, and an editorial news preview.
- Replaced the ordinary floating tab bar with a dark Minecraft-inspired hotbar navigation rail.
- Rebuilt the store as a visual product gallery with a featured product, two-column catalog, category filters, favorites, sorting, and side-by-side comparison.
- Reworked the season into a centered winner's podium and visual leaderboard while preserving the published awards: 1st ₺5,000, 2nd ₺1,500, 3rd ₺1,000.
- Rebuilt the World section with selectable SkyBlock/Lobby/Community modes and a copy-to-clipboard command console.
- Rebuilt the player profile as an identity card with wallet, online-presence status, session security, admin-only control room, and a persistent logout action.
- Rebuilt public news as an editorial feed with featured story, filters, search and saved items.
- Redesigned the login and splash experience around the REALM portal artwork.
- Added a custom generated portal-and-voxel app icon, distinct from the original website wordmark.

## Preserved behavior
- Live player status, account data, credits, store products, season rankings and news continue to use the existing API.
- Favorites and news bookmarks remain local to the device.
- No fake products, purchases, or payment success states were added. Mobile checkout remains disabled until a verified backend flow exists.
- The administrator view remains gated by the server-confirmed isAdmin profile flag. Privileged operations still depend on backend authorization.
- Keychain token storage, MFA and session expiry remain intact.

## Build
- Version: 13.0.0
- Build: 130
- Minimum iOS: 17.0
- Bundle identifier: com.blastermc.mobile
- CI compilation is not a substitute for real-device layout, accessibility, or end-to-end testing.
