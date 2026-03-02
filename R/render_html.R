feed_css <- function() {
  "
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #f0f2f5;
    color: #1a1a1a;
    line-height: 1.5;
  }
  .feed-header {
    max-width: 640px;
    margin: 2rem auto 1rem;
    padding: 0 1rem;
  }
  .feed-header h1 {
    font-size: 1.75rem;
    font-weight: 700;
    color: #0085ff;
  }
  .feed-header .subtitle {
    color: #666;
    font-size: 0.9rem;
    margin-top: 0.25rem;
  }
  .feed { max-width: 640px; margin: 0 auto; padding: 0 1rem 2rem; }
  .card {
    background: #fff;
    border-radius: 12px;
    padding: 1rem 1.25rem;
    margin-bottom: 0.75rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    border-left: 3px solid #0085ff;
  }
  .card-header {
    display: flex;
    align-items: center;
    gap: 0.625rem;
    margin-bottom: 0.5rem;
  }
  .avatar {
    width: 42px;
    height: 42px;
    border-radius: 50%;
    object-fit: cover;
    flex-shrink: 0;
  }
  .author-info { flex: 1; min-width: 0; }
  .display-name {
    font-weight: 600;
    font-size: 0.95rem;
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .handle {
    color: #888;
    font-size: 0.8rem;
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .timestamp {
    color: #888;
    font-size: 0.8rem;
    text-decoration: none;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .timestamp:hover { text-decoration: underline; }
  .post-text {
    font-size: 0.95rem;
    white-space: pre-wrap;
    word-wrap: break-word;
  }
  .post-images {
    margin-top: 0.75rem;
    display: grid;
    gap: 0.5rem;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  }
  .post-image {
    width: 100%;
    border-radius: 8px;
    max-height: 400px;
    object-fit: cover;
  }
  .reply-badge {
    display: inline-block;
    font-size: 0.7rem;
    color: #666;
    background: #eee;
    padding: 0.1rem 0.4rem;
    border-radius: 4px;
    margin-left: 0.35rem;
    vertical-align: middle;
    font-weight: 500;
  }
  .card-footer {
    margin-top: 0.5rem;
    text-align: right;
  }
  .view-link {
    font-size: 0.8rem;
    color: #0085ff;
    text-decoration: none;
  }
  .view-link:hover { text-decoration: underline; }
  .empty-message {
    text-align: center;
    color: #888;
    padding: 3rem 1rem;
    font-size: 1.1rem;
  }
  @media (max-width: 480px) {
    .feed-header { margin-top: 1rem; }
    .feed-header h1 { font-size: 1.4rem; }
    .card { padding: 0.875rem 1rem; }
  }
  "
}

post_card <- function(post) {
  post_url <- bskyr::bs_uri_to_url(post$uri)
  timestamp <- format(
    as.POSIXct(post$indexed_at, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC"),
    "%b %d, %Y %H:%M UTC"
  )

  avatar_url <- post$author_avatar
  avatar <- if (!is.null(avatar_url) && !is.na(avatar_url) && nchar(avatar_url) > 0) {
    htmltools::tags$img(
      src     = avatar_url,
      class   = "avatar",
      alt     = post$author_handle,
      loading = "lazy"
    )
  }

  # Reply badge
  reply_badge <- if (isTRUE(post$is_reply)) {
    htmltools::tags$span(class = "reply-badge", "reply")
  }

  # Build image gallery if post has images
  imgs <- post$image_urls[[1]]
  images <- if (length(imgs) > 0 && !all(is.na(imgs))) {
    htmltools::tags$div(
      class = "post-images",
      lapply(imgs[!is.na(imgs)], function(url) {
        htmltools::tags$img(src = url, class = "post-image", loading = "lazy")
      })
    )
  }

  htmltools::tags$article(
    class = "card",
    htmltools::tags$div(
      class = "card-header",
      avatar,
      htmltools::tags$div(
        class = "author-info",
        htmltools::tags$span(
          class = "display-name",
          post$author_display_name,
          reply_badge
        ),
        htmltools::tags$span(class = "handle", paste0("@", post$author_handle))
      ),
      htmltools::tags$a(
        href   = post_url,
        target = "_blank",
        rel    = "noopener",
        class  = "timestamp",
        timestamp
      )
    ),
    htmltools::tags$p(class = "post-text", post$post_text),
    images,
    htmltools::tags$div(
      class = "card-footer",
      htmltools::tags$a(
        href   = post_url,
        target = "_blank",
        rel    = "noopener",
        class  = "view-link",
        "View on Bluesky \u2192"
      )
    )
  )
}

build_feed_cards <- function(posts) {
  if (nrow(posts) == 0) {
    return(htmltools::tags$p(class = "empty-message", "No posts found."))
  }
  htmltools::tagList(
    lapply(seq_len(nrow(posts)), function(i) post_card(posts[i, ]))
  )
}

render_feed_html <- function(posts, output_path = "output/index.html") {
  updated <- format(Sys.time(), "%B %d, %Y %H:%M %Z")

  page <- htmltools::tags$html(
    lang = "en",
    htmltools::tags$head(
      htmltools::tags$meta(charset = "UTF-8"),
      htmltools::tags$meta(
        name    = "viewport",
        content = "width=device-width, initial-scale=1.0"
      ),
      htmltools::tags$title("NICAR 2026 Bluesky Feed"),
      htmltools::tags$style(htmltools::HTML(feed_css()))
    ),
    htmltools::tags$body(
      htmltools::tags$header(
        class = "feed-header",
        htmltools::tags$h1("NICAR 2026 on Bluesky"),
        htmltools::tags$p(
          class = "subtitle",
          glue::glue("{nrow(posts)} posts | Updated {updated}")
        )
      ),
      htmltools::tags$main(
        class = "feed",
        build_feed_cards(posts)
      )
    )
  )

  htmltools::save_html(page, file = output_path, libdir = NULL)
  message(glue::glue("HTML written to {output_path}"))
}

render_feed_fragment <- function(posts, output_path = "output/feed-fragment.html") {
  fragment <- htmltools::tagList(
    htmltools::tags$style(htmltools::HTML(feed_css())),
    htmltools::tags$div(
      class = "feed",
      build_feed_cards(posts)
    )
  )

  writeLines(as.character(fragment), output_path)
  message(glue::glue("Fragment written to {output_path}"))
}

render_feed_json <- function(posts, output_path = "output/feed.json") {
  out <- posts |>
    dplyr::transmute(
      post_url = purrr::map_chr(uri, bskyr::bs_uri_to_url),
      author_handle,
      author_display_name,
      author_avatar,
      post_text,
      indexed_at,
      image_urls
    )

  jsonlite::write_json(out, output_path, pretty = TRUE, auto_unbox = TRUE)
  message(glue::glue("JSON written to {output_path}"))
}

render_feed_rss <- function(posts, output_path = "output/feed.xml",
                            site_url = "", feed_url = "") {
  build_date <- format(Sys.time(), "%a, %d %b %Y %H:%M:%S %z", tz = "UTC")

  items <- purrr::map_chr(seq_len(nrow(posts)), function(i) {
    post <- posts[i, ]
    post_url <- bskyr::bs_uri_to_url(post$uri)
    pub_date <- format(
      as.POSIXct(post$indexed_at, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC"),
      "%a, %d %b %Y %H:%M:%S +0000"
    )
    # Author line for title
    author <- paste0(post$author_display_name, " (@", post$author_handle, ")")

    # Build image HTML for description and media:content elements
    imgs <- post$image_urls[[1]]
    imgs <- if (length(imgs) > 0) imgs[!is.na(imgs)] else character(0)

    img_html <- if (length(imgs) > 0) {
      paste0(
        "<br/><br/>",
        paste0('<img src="', imgs, '" style="max-width:100%;" />', collapse = " ")
      )
    } else {
      ""
    }

    media_xml <- if (length(imgs) > 0) {
      paste0(
        "\n",
        paste0('  <media:content url="', xml_escape(imgs),
               '" medium="image" type="image/jpeg" />', collapse = "\n")
      )
    } else {
      ""
    }

    glue::glue(
      "    <item>
      <title>{xml_escape(author)}</title>
      <link>{xml_escape(post_url)}</link>
      <guid isPermaLink=\"true\">{xml_escape(post_url)}</guid>
      <pubDate>{pub_date}</pubDate>
      <description><![CDATA[{post$post_text}{img_html}]]></description>{media_xml}
    </item>"
    )
  })

  atom_link <- if (nchar(feed_url) > 0) {
    glue::glue('    <atom:link href="{xml_escape(feed_url)}" rel="self" type="application/rss+xml"/>')
  } else {
    ""
  }

  site_link <- if (nchar(site_url) > 0) site_url else "https://bsky.app"

  items_xml <- paste(items, collapse = "\n")

  rss <- glue::glue(
    '<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
  <channel>
    <title>NICAR 2026 Bluesky Feed</title>
    <link>{xml_escape(site_link)}</link>
    <description>Bluesky posts about the NICAR 2026 conference (#NICAR26, #NICAR2026)</description>
    <language>en</language>
    <lastBuildDate>{build_date}</lastBuildDate>
{atom_link}
{items_xml}
  </channel>
</rss>'
  )

  writeLines(rss, output_path, useBytes = TRUE)
  message(glue::glue("RSS written to {output_path}"))
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x <- gsub("'", "&apos;", x, fixed = TRUE)
  x
}
