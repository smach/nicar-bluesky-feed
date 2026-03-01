source("R/fetch_posts.R")
source("R/render_html.R")

num_days_back <- as.integer(Sys.Date() - as.Date("2026-01-01"))

posts <- fetch_nicar_posts(days_back = num_days_back, limit = 800)

if (nrow(posts) == 0) {
  message("No posts found. Exiting.")
  quit(status = 0)
}

if (!dir.exists("output")) {
  dir.create("output")
}

render_feed_html(posts)
render_feed_fragment(posts)
render_feed_json(posts)
render_feed_rss(posts)

message(glue::glue("Done. {nrow(posts)} posts rendered."))
