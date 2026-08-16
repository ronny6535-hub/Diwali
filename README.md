# Stall logos

Drop each stallholder's logo in **this folder** using the exact filename below.
Until the file exists, that stall shows a neat initials badge instead — nothing
looks broken, so there is no rush and no code change needed.

| Filename | Stall |
|---|---|
| `smv-jewellers.png` | SMV Jewellers |
| `aalam-boutique.png` | Aalam Boutique |
| `aaurum-on-trend.png` | Aaurum On Trend |
| `amrit-australia.png` | Amrit Australia |
| `rr-collections.png` | R R Collections Adelaide |
| `indikraft.png` | Indikraft |
| `gujjus-spice-kitchen.png` | Gujju's Spice Kitchen |
| `flavourful-fusion.png` | Flavourful Fusion |
| `karma-konnections.png` | Karma Konnections |
| `plants-by-joseph.png` | Plants by Joseph |
| `luthra-tiles.png` | Luthra Tiles |
| `tan-levida.png` | Tan Levida |
| `kathy-skin-health.png` | Kathy Skin Health Science |
| `boffo-real-estate.png` | Boffo Real Estate |

Kangaroo Disability Services has no logo listed — add
`kangaroo-disability.png` here and swap its `<span class="plate__mark">` for an
`<img>` in `index.html` if you get one.

## Before you add them

These render as a **44px circle**, so:

- Save at about **150×150px** — bigger just slows the page down.
- **Square crops work best.** A wide logo will be centre-cropped.
- Transparent PNG is ideal. A logo with its own background (like Hello Goodies)
  still works — it just fills the circle.

macOS Preview will do it: Tools → Adjust Size, set 150px, then File → Export
as PNG.

## Filenames are case-sensitive

Netlify and every Linux host treat `Logo.PNG` and `logo.png` as different
files, even though your Mac does not. Use **lowercase `.png`** exactly as
listed above, or the logo will work locally and 404 once deployed.
