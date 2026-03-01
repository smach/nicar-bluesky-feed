# NICAR 2026 Bluesky Feed

This projects aggregates Bluesky posts about the NICAR conference and creates a static HTML feed page to display them. The data updates automatically via an R script and GitHub Actions. Each post links back to the original on Bluesky, and replies are labeled with a `[reply]` badge.

This was created based on idea of mine and a lot of back and forth between me and Claude Opus 4.5, but almost all the code was written by Claude. As was most of the following README, lightly edited by me and OpenAI Codex (I'm experimenting with different LLMs).

## What it searches for

- **#NICAR26** — hashtag (case insensitive)
- **#NICAR2026** — hashtag (case insensitive)
- **NICAR** — full word, case sensitive (must be all caps)

Results are deduplicated and sorted newest-first.

## Output files

| File | Description |
|------|-------------|
| `output/index.html` | Full standalone HTML page |
| `output/feed-fragment.html` | Just the feed cards + CSS — embed in an existing page |
| `output/feed.json` | Structured JSON for use in Quarto or custom JS |
| `output/feed.xml` | RSS 2.0 feed — subscribe in any RSS reader |

## Setup

### Running locally

If running locally: Create a `.Renviron` file in the project root (or your home directory):

```
BLUESKY_APP_USER=yourhandle.bsky.social
BLUESKY_APP_PASS=your-app-password
```

You can generate an app password at: https://bsky.app/settings/app-passwords

You will need to either manually run the `run.R` script to update the data or set up some sort of automated cron job on your system.

```bash
Rscript run.R
```

Then open `output/index.html` in your browser to the HTML file.

### Running on GitHub with GitHub Actions (automated)

Add these secrets to your repo under Settings > Secrets and variables > Actions:

- `BLUESKY_APP_USER` — your Bluesky handle
- `BLUESKY_APP_PASS` — your app password

The workflow is set to run every 20 minutes from 7am–midnight Eastern (conference mode). Edit as you like. To switch to post-conference mode, edit `.github/workflows/update-feed.yml` and change the cron to `0 */3 * * *`.

The workflow automatically deploys `output/` to GitHub Pages. To enable it:

1. Go to your repo's **Settings > Pages**
2. Under **Source**, select **GitHub Actions**

Your site will be live at:

`https://<username>.github.io/<repo-name>/`

The RSS XML feed URL is:

`https://<username>.github.io/<repo-name>/feed.xml`

Example:

`https://smachlis.github.io/nicar-bluesky-feed/feed.xml`

### Add the feed to an RSS reader

1. Copy your `feed.xml` URL (the GitHub Pages URL above, not the GitHub repo file URL).
2. In your RSS app, choose **Add feed**, **Subscribe**, or **Add by URL**.
3. Paste `https://<username>.github.io/<repo-name>/feed.xml` and save.

Common mistake to avoid: do not use the GitHub repo path like `https://github.com/<username>/<repo>/blob/main/output/feed.xml`; many readers will not treat that as a valid RSS endpoint.

## R dependencies

bskyr, dplyr, stringr, htmltools, jsonlite, glue, purrr
