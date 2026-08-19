# Diwali Exhibition Sale 2026

Single-page site for the Diwali Exhibition Sale — Sunday 25 October 2026,
Campbelltown Function Centre, 172 Montacute Rd, Rostrevor SA 5073.

- **Organised by** Hello Goodies & Curious Cook's Diary
- **Powered by** Mortgage Choice – Jags Lakhani
- **Supported by** Ronny's Photography & Video

## Files

| Path | What it is |
|---|---|
| `index.html` | The site. Plain HTML/CSS/JS — no framework, no build step. Exhibitor list is `const EXHIBITORS` in the script. |
| `assets/` | Logos and photos. See `assets/README.md`. |
| `build-single-file.py` | Produces `dist/index.html` with every image inlined. |
| `dist/index.html` | Generated. One self-contained file, no `assets/` needed. |

## Hosting — Cloudflare Pages + GitHub

Live at **https://diwaliexhibitionsale.com.au/**

This is the setup in use. Push to GitHub and Cloudflare Pages rebuilds and
publishes automatically.

### Cloudflare Pages settings

There is no build step — the repo *is* the site.

| Setting | Value |
|---|---|
| Framework preset | **None** |
| Build command | *(leave empty)* |
| Build output directory | `/` |

If Cloudflare insists on a build command, `echo "no build"` is fine.

**Do not point the output at `dist/`.** That folder is the single-file bundle
for emailing around; it inlines every image as base64 and is roughly 5× the
page weight. Serve the root, where `index.html` loads `assets/` normally and
Cloudflare can cache each image separately.

### Publishing a change

```bash
git add -A
git commit -m "Add new stall"
git push
```

Live in under a minute. Cloudflare keeps every previous deployment, so you can
roll back from the dashboard if something looks wrong.

### Files that must stay at the repo root

`robots.txt`, `sitemap.xml` and `llms.txt` have to be served from the domain
root to work. They're already in the right place — just don't move them into a
subfolder.

### Cloudflare settings worth turning on

- **Always Use HTTPS** — SSL/TLS → Edge Certificates
- **Auto Minify** for HTML/CSS/JS — Speed → Optimization
- **Redirect www to non-www** (or the reverse) so only one address answers.
  The canonical tag in the page points at the non-www version.

### Other options

The site is plain files, so any static host works — upload `index.html` **and**
the `assets/` folder together, keeping `assets/` beside the HTML.

#### Netlify

Free, and re-publishing takes about thirty seconds — which matters when you're
adding exhibitors every week.

1. Go to [app.netlify.com/drop](https://app.netlify.com/drop) and drag this
   whole folder onto the page. It goes live immediately on a temporary address
   like `sparkly-diya-1234.netlify.app`.
2. Create a free account so the site is saved to it.
3. **Site configuration → Domain management → Add a domain**, enter the domain
   you bought, and Netlify shows you the DNS records to set.
4. At your registrar (GoDaddy, Crazy Domains, VentraIP, Namecheap…), open the
   DNS settings and add those records. Allow a few hours to take effect.
5. HTTPS switches itself on once the domain resolves.

**To update after that:** edit the files, then drag the folder onto your
site's *Deploys* tab. The new version replaces the old one in seconds, and
Netlify keeps every past deploy so you can roll back if something breaks.

### If your domain came with hosting (cPanel)

Australian registrars often bundle hosting. Open **cPanel → File Manager**,
go into `public_html`, and upload `index.html` plus the `assets/` folder. Same
again for each update — overwrite the old files. Turn on the free SSL
certificate (usually "Let's Encrypt" or "AutoSSL") so the site is on https.

### Other options

**Vercel** and **Cloudflare Pages** work the same way as Netlify.
**GitHub Pages** is free and gives you a full history of every change, but you
need to be comfortable with Git.

### A single file, no folder

If you ever need one file with the images baked in — to email, or for a host
that won't take folders:

```bash
python3 build-single-file.py
```

That writes `dist/index.html`, which works entirely on its own.

## Keeping it updated

### Adding exhibitors

Open `index.html` and find `const EXHIBITORS` near the top of the `<script>`
block, close to the bottom of the file. Add a line per stall:

```js
const EXHIBITORS = [
  { name: 'Saree Sansaar', category: 'Ethnic wear' },
  { name: 'Mithai Ghar',   category: 'Sweets' },
  { name: 'New Stall Co.', category: 'Candles' },     // ← added
];
```

The scrolling row rebuilds itself — the badge takes their initials, the
duplicate copy that makes it loop is generated, and "Your stall here" stays at
the end. Don't add that one yourself.

Got their logo? Save it in `assets/` and point at it:

```js
{ name: 'Mithai Ghar', category: 'Sweets', logo: 'assets/mithai-ghar.png' }
```

If the file is missing or misnamed, it quietly falls back to initials rather
than showing a broken image.

### Adding sponsors

Sponsor logos live in the partner band, in the HTML. Copy an existing block and
change the three marked values:

```html
<div class="logo-plate">
  <img src="assets/their-logo.png" alt="Their Name"
       data-brand="Their Name" data-brand-sub="What they do">
</div>
```

`data-brand` and `data-brand-sub` are the text shown if the image is missing,
so the page never breaks while you're waiting on a logo file. Drop it inside
the `partner__logos` div of whichever tier they belong to.

To add a whole new tier, copy an entire `<div class="partner">` block and give
it its own `partner__role` heading.

### Image sizes

Shrink logos to roughly 400px on the long edge before adding them. Full-camera
images will make the page slow to load on a phone.

## The forms

Both forms post to Formspree at `https://formspree.io/f/xqpzzzpn` using
`fetch()`, so visitors stay on the page and keep the on-page confirmation.

There are two of them:

| Form | Where | Fields |
|---|---|---|
| Mystery gift entry | `#raffle` | name, mobile, email (optional) |
| Stall / sponsorship enquiry | `#contact` | name, email, topic, message |

### Telling them apart

They share one endpoint, so each sends a hidden `form_type` field —
`Mystery gift entry` or `Stall / sponsorship enquiry`. It arrives as a column
in the export and as the email subject, so you can filter one from the other.

Each form also carries a hidden `_gotcha` honeypot. Bots fill it in, people
never see it, and Formspree drops those submissions.

### Getting entries into a spreadsheet

Formspree keeps every submission in your dashboard. From there:

1. **CSV export** — download from the form's submissions page and open in
   Excel or Google Sheets. Sort or filter by the `form_type` column to split
   raffle entries from stall enquiries.
2. **Live Google Sheets sync** — Formspree offers this as a plugin/integration,
   and Zapier or Make can do the same. Both depend on your Formspree plan, so
   check what yours includes before relying on it.

If you'd rather keep the two completely separate, create a second form in
Formspree and swap its ID into the raffle form's `action`. That gives each its
own inbox and its own export, and it's a one-line change:

```html
<form class="stub" id="raffleForm" action="https://formspree.io/f/YOUR_SECOND_ID" method="POST">
```

### Confirmed working

Both forms were tested against the live endpoint on 4 August 2026 — Formspree
returned `200 {"ok": true}` for each. **Two test submissions are sitting in your
Formspree inbox** (both named "TEST — Claude Code"); delete them so they don't
end up in your real entry list.

**Test on the deployed site, not from a `file://` page** — the browser blocks
cross-origin posts from local files, and the form will report that it couldn't
reach the server.

## Event details, in one place

Date, venue and hours appear in several spots. If they change, update:

| What | Where |
|---|---|
| Doors / countdown target | `CONFIG.eventDate` in the script |
| Calendar entry | `CONFIG.calendar` in the script |
| Hero date line | `.hero__where` |
| Fact strip | `.facts` |
| Contact block | `.details` |

Currently: **Sunday 25 October 2026, 9:00am – 6:00pm**, free entry.

## Still to do

Nothing blocking — all logos, contact details and hours are in. Ongoing work
is exhibitors and sponsors as they confirm; see "Keeping it updated" above.
