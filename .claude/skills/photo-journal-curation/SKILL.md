---
name: photo-journal-curation
description: Group, re-group, move, or rename photo/video subfolders under src/assets/<date>/ and keep the matching journal-<date>.mdx entry (headings, descriptions, <Photos>/<Video> blocks, cover) in sync. Use whenever the user asks to move photos around, split/merge event groups, fix a wrong folder name/description, curate a newly-imported day, or reorganize entries independently of date folders.
---

# Photo journal curation

This project (`israel2026`) stores each day's photos under `src/assets/<YYYY-MM-DD>/`, split
into `<HHMMSS>-<slug>/` subfolders — one per real-world event (a meal, a site visit, a walk).
Every day from `2026-07-29` through `2026-08-24` has already been through this process once;
this skill is for redoing it on a new import, fixing a mistake, or reorganizing further.

## The core loop

1. **Extract timestamp + GPS** for every file in the target folder:
   ```
   mdls -raw -name kMDItemContentCreationDate -name kMDItemLatitude -name kMDItemLongitude <file>
   ```
   - Trust the **filename's `HHMMSS`** for ordering — it's the camera-local capture time (from
     EXIF `DateTimeOriginal` for photos, QuickTime creation date for videos), already correct
     and consistent even when `mdls`'s `kMDItemContentCreationDate` reports something else
     (e.g. a video's on-disk copy time, or a different UTC offset than expected).
   - `mdls` GPS works for both photos and videos and is the main location signal.
   - Some files will have **null or garbage GPS/time** — most often AirDropped or otherwise
     re-saved photos that lost their original EXIF (their `kMDItemContentCreationDate` reads
     as today's date). When that happens, place the file by visual match to its neighbors
     instead of trusting metadata.

2. **Cluster into events** using judgment, not a rigid rule: a time gap of roughly 20–30
   minutes or a GPS move of roughly 150–200m is a starting signal for a new group, but the
   real test is what's actually in the photos. Merge a "new" cluster back in if it's clearly
   the same continuous event (a long guided tour, a meal, a museum visit can run 30–90+ minutes
   with GPS barely moving — that's one group, not several). Don't force splits on a day with
   only a few photos.

3. **Watch for physically-impossible GPS jumps** (kilometers in seconds) — this is a stale or
   cached location fix, not real movement. Trust the visual content of the photo over the
   outlier coordinate.

4. **Look at the photos before naming the folder**, not after. Pick one representative photo
   per candidate group (more if it's large or ambiguous) and actually view it — the slug and
   the `.mdx` description both come from what's visible (signage, landmarks, activity), not
   from GPS coordinates alone and never from guessing. Getting this order backwards is exactly
   how mistakes happen: on this project two folders were named before their photos were
   checked and ended up describing the wrong thing entirely (a folder called "back at the
   apartment" that was actually a nighttime laser show; one called "back at the Kotel" that was
   actually a wine shop). Don't assert a specific real-world place name (a restaurant, a store)
   unless it's confirmed by on-screen text/signage — describe generically otherwise.

5. **Create the subfolder and move files**:
   ```
   mkdir "<HHMMSS>-<short-kebab-slug>"
   mv <files for this group> "<HHMMSS>-<short-kebab-slug>/"
   ```
   Move both photos and videos that belong to the same event together.

6. **Update the `.mdx`.** Each event group gets, in chronological order:
   ```mdx
   ## <Heading matching the slug>

   <One factual sentence of context.>

   <Photos glob="/src/assets/<date>/<folder>/*.jpg" />
   ```
   For any `.mov` in the group, import it with the `?url` suffix (required — a bare
   `/src/assets/...` path string works in `astro dev` but silently breaks in the production
   static build) and add a short video callout after the Photos block:
   ```mdx
   import clipXXXXXX from '../../assets/<date>/<folder>/<file>.mov?url';
   ...
   Here's a video of that!

   <Video src={clipXXXXXX} />
   ```
   Update the entry's `cover` frontmatter if it pointed at a file that moved.

7. **Verify with a real build**, not just `astro dev` — `<Photos glob>` throws at build time
   if a glob matches zero files, so `astro build` (from the project root) is a cheap, complete
   check that every glob in every entry still resolves. Don't run `astro dev`/`astro build`
   concurrently from multiple parallel agents working on different days — they'll collide on
   the shared dev server/`dist` output; let one process own the verification step.

## Reorganizing entries independently of dates

Entries don't have to map 1:1 with `src/assets/<date>/` folders. Splitting a day across two
entries, merging days, or pulling a standalone reflection into its own `.mdx` is fine — the
only thing that has to stay correct is that every `<Photos glob>` (and `cover`) still points at
a real path. Moving or renaming an asset subfolder means finding and updating every `.mdx` that
referenced its old path.

## Delegating large batches

For a full day with 50+ files, or several days at once, consider using the Agent tool with
`subagent_type: "fork"` (if forking your own context) or a fresh agent (if not) per day or
small batch of days, each running this same loop — that keeps the heavy image-viewing and
bash output out of the main conversation. Give each one this file's content or point it here,
tell it explicitly not to run `astro dev`/`astro build` while others are still working, and
verify the result (folder names actually match photo content, build passes) yourself afterward
rather than trusting a self-report at face value — a background agent that gets cut off
mid-run (e.g. by a session rate limit) may report partial or misleading completion status.
