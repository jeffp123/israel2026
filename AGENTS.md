# israel2026

A photo journal of the Peck family's 2026 trip to Israel, built with Astro. Deployed
automatically via GitHub Actions (`.github/workflows/deploy.yml`) to GitHub Pages at
https://jeffp123.github.io/israel2026/ on every push to `main`.

This is the current state of the project as of 2026-09-04. The import workflow and existing
entries are expected to keep changing as the trip and the site evolve — treat what's below as
a snapshot to verify against the actual code, not a fixed spec.

## Content model

Journal entries live in `src/content/entries/*.mdx` as an Astro content collection
(schema in `src/content.config.ts`). Frontmatter fields:

- `title` (string)
- `date` (coerced to `Date`)
- `location` (string, optional)
- `dek` (string, optional) — subtitle/summary shown under the title
- `cover` (image, optional) — path into `src/assets/...`

Routing is dynamic: `src/pages/entries/[...slug].astro` renders every entry through
`src/layouts/EntryLayout.astro` using the MDX filename as the slug. `src/pages/index.astro`
lists all entries sorted by date. There's no need to register new pages when adding an entry
— just add the `.mdx` file.

## Photos: import pipeline and folder convention

Photos/videos are dropped onto an "Import to israel2026" droplet app, which runs
`scripts/import-photos.sh`. That script:

- Resizes photos (ImageMagick, max 2400px edge, quality 82) and copies videos through as-is.
- Reads the true capture date/time from embedded metadata (EXIF `DateTimeOriginal` for
  photos, QuickTime creation date for videos), falling back to the parent folder name (if
  `YYYY-MM-DD`) or the file's local modification time.
- Writes to `src/assets/<YYYY-MM-DD>/<HHMMSS>.<ext>`, suffixing `-2`, `-3`, etc. on same-second
  collisions (e.g. burst shots).

So each `src/assets/<date>/` folder is a chronological dump of that day's media, named by
capture time. Subfolders (e.g. `2026-07-27/ricotta/`, `2026-07-27/train/`) are created
manually when curating an entry, to group a batch of photos for a `<Gallery>` or
`<Carousel>`.

When writing an entry, reference images from these date folders — either individual files
(`import('/src/assets/2026-07-27/091626.jpg')`) or a subfolder glob
(`import.meta.glob('/src/assets/2026-07-27/train/*.jpg', { eager: true })`).

## Writing an entry

Look at `src/content/entries/second-wave.mdx` as the reference example. Import the
components you need at the top of the MDX body:

```mdx
import Photos from '../../components/Photos.astro';
import Figure from '../../components/Figure.astro';
import Gallery from '../../components/Gallery.astro';
import Carousel from '../../components/Carousel.astro';
import Video from '../../components/Video.astro';
```

- `<Photos glob="/src/assets/2026-07-27/train/*.jpg" />` or
  `<Photos sources={["/src/assets/2026-07-05/123.jpg", "/src/assets/2026-07-05/456.jpg"]} />`
  — **the default choice for a batch of photos.** No `import()`/`import.meta.glob()` needed in
  the MDX (it resolves paths internally, since Vite's `import.meta.glob` requires a literal
  pattern at the call site — it globs everything under `src/assets` once and filters at
  runtime). No alt text needed either — it derives a plain factual alt string from each file's
  date-folder/capture-time path (e.g. "Photo from July 27, 2026, 9:16 AM"). It auto-picks the
  layout based on count: 1–4 photos render as full, uncropped, framed figures stacked in
  sequence (like `<Figure variant="framed">` below); 5+ render as the centered thumbnail grid
  with a PhotoSwipe lightbox (like `<Gallery>` below). `sources` order is preserved as given;
  `glob` matches are sorted by path (chronological, since filenames are capture-time HHMMSS).
- `<Figure src={import('...')} alt="..." caption="..." variant="inline|left|right|framed|wide|full" />`
  — a single photo needing a real caption, or a non-framed variant (`left`/`right`/`wide`/`full`)
  that `<Photos>` doesn't cover. Requires manual `import()` and `alt` text.
- `<Gallery images={import.meta.glob('/src/assets/.../*.jpg', { eager: true })} />` (or an
  array of `import(...)` calls) — a grid of thumbnails with a PhotoSwipe lightbox on click.
  Superseded by `<Photos>` for new entries; kept for cases needing manual captions per image
  (the `captions` prop). All three existing entries have been migrated off `<Gallery>` to
  `<Photos>` — `Gallery.astro` itself is still kept around for that captions case, but nothing
  currently imports it.
- `<Carousel images={...} />` — a swipeable slideshow (Swiper). A deliberate UX choice, not
  something photo count should auto-select, so `<Photos>` doesn't produce this — use `Carousel`
  directly when you want it.
- `<Video src="/clip.mp4" poster="..." />` or `<Video embed="..." />` for an embedded player.

The `.gallery` grid (used by both `<Gallery>` and `<Photos>`'s grid tier) centers itself via
`justify-content:center` with a fixed max column width — a trailing partial row (e.g. 2 photos)
centers instead of stretching/left-packing. If it ever looks off-center again, that CSS rule in
`src/styles/global.css` is the place to check first.

`## H2` headings in an entry automatically populate the on-page table of contents
(`EntryLayout.astro` / `Toc.astro`), with scroll-spy highlighting the current section.

Note: `machane-yehuda.mdx` has several commented-out `<Figure>`/`<Photos>`/`<Carousel>`
placeholders with `"TODO"` sources or stale image paths — it's a draft awaiting photo
curation, not a template to copy literally.

## Development

When starting the dev server, use background mode:

```
astro dev --background
```

Manage the background server with `astro dev stop`, `astro dev status`, and `astro dev logs`.

## Documentation

Full documentation: https://docs.astro.build

Consult these guides before working on related tasks:

- [Adding pages, dynamic routes, or middleware](https://docs.astro.build/en/guides/routing/)
- [Working with Astro components](https://docs.astro.build/en/basics/astro-components/)
- [Using React, Vue, Svelte, or other framework components](https://docs.astro.build/en/guides/framework-components/)
- [Adding or managing content](https://docs.astro.build/en/guides/content-collections/)
- [Adding styles or using Tailwind](https://docs.astro.build/en/guides/styling/)
- [Supporting multiple languages](https://docs.astro.build/en/guides/internationalization/)
