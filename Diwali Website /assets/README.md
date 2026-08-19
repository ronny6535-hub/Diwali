# Assets

Images used by `index.html`. Anything missing degrades gracefully to a styled
text lockup, so the site never shows a broken image.

## All logos are in

| File | What it is |
|---|---|
| `hello-goodies.png` | Hello Goodies logo (organiser) |
| `curious-cooks-diary.png` | Curious Cook's Diary logo (organiser) |
| `mortgage-choice-jags.png` | Mortgage Choice – Jags Lakhani logo (powered by) |
| `ronnys-photography.png` | Ronny's Photography & Video logo (supported by) |
| `team-2025.jpg` | Group photo, Diwali Exhibition Sale 2025 |
| `stalls-2025.jpg` | Stallholders and visitors, 2025 |

All images are resized for the web. If you replace one with a full-resolution
original, shrink it again or the page gets slow — around 400px on the long edge
is plenty for a logo.

The Hello Goodies logo has its own dark green background baked in, so it's
displayed as a filled tile (`.logo-plate--bleed`) rather than floating on
white. If you ever get a transparent-background version, drop the `--bleed`
class from its two plates in `index.html`.

## Adding more

Sponsor and exhibitor logos both drop straight in — see "Keeping it updated"
in the top-level `README.md` for exactly where each goes.

More past-event photos are welcome too — add them as `gallery-1.jpg`,
`gallery-2.jpg`, … and add a matching `<figure>` in the `#gallery` section.

## Rebuilding the single-file version

`index.html` loads these over the network, which is what you want for a normal
deploy. To produce a single self-contained file (every image inlined as a data
URI) for sharing or previewing:

```bash
python3 build-single-file.py
```

That writes `dist/index.html`, which works with no `assets/` folder at all.
