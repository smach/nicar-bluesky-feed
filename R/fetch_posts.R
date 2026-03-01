fetch_nicar_posts <- function(days_back = 30, limit = 200) {
  since <- format(Sys.time() - as.difftime(days_back, units = "days"), "%Y-%m-%dT%H:%M:%SZ")

  auth <- bskyr::bs_auth(
    user = bskyr::get_bluesky_user(),
    pass = bskyr::get_bluesky_pass()
  )

  message("Searching for #NICAR26...")
  raw_tag1 <- bskyr::bs_search_posts(
    query = "NICAR26",
    tag   = "NICAR26",
    sort  = "latest",
    since = since,
    limit = limit,
    auth  = auth,
    clean = FALSE
  )

  message("Searching for #NICAR2026...")
  raw_tag2 <- bskyr::bs_search_posts(
    query = "NICAR2026",
    tag   = "NICAR2026",
    sort  = "latest",
    since = since,
    limit = limit,
    auth  = auth,
    clean = FALSE
  )

  message("Searching for NICAR (text)...")
  raw_text <- bskyr::bs_search_posts(
    query = "NICAR",
    sort  = "latest",
    since = since,
    limit = limit,
    auth  = auth,
    clean = FALSE
  )

  # Extract post lists from raw API responses (each is a list of paginated responses)
  posts_tag1 <- extract_raw_posts(raw_tag1)
  posts_tag2 <- extract_raw_posts(raw_tag2)
  posts_text <- extract_raw_posts(raw_text)

  # Deduplicate tag results by URI, then flatten
  tag_posts <- c(posts_tag1, posts_tag2)
  tag_uris <- purrr::map_chr(tag_posts, "uri")
  tag_posts <- tag_posts[!duplicated(tag_uris)]
  tag_flat <- flatten_posts(tag_posts)

  # Flatten text results and apply case-sensitive filter
  text_flat <- flatten_posts(posts_text) |>
    dplyr::filter(stringr::str_detect(post_text, "\\bNICAR\\b"))

  # Combine and deduplicate
  all_posts <- dplyr::bind_rows(tag_flat, text_flat) |>
    dplyr::distinct(uri, .keep_all = TRUE) |>
    dplyr::arrange(dplyr::desc(indexed_at))

  message(
    glue::glue(
      "Found: {length(posts_tag1)} #NICAR26, ",
      "{length(posts_tag2)} #NICAR2026, ",
      "{nrow(text_flat)} NICAR (text, case-filtered). ",
      "{nrow(all_posts)} unique after dedup."
    )
  )

  all_posts
}

extract_raw_posts <- function(resp) {
  # clean = FALSE returns a list of paginated response objects
  # Each element has a $posts field; combine them all
  out <- purrr::list_c(purrr::map(resp, "posts"))
  if (is.null(out)) list() else out
}

flatten_posts <- function(raw_posts) {
  if (length(raw_posts) == 0) {
    return(dplyr::tibble(
      uri = character(),
      indexed_at = character(),
      post_text = character(),
      author_handle = character(),
      author_display_name = character(),
      author_avatar = character(),
      like_count = integer(),
      repost_count = integer(),
      reply_count = integer(),
      is_reply = logical(),
      image_urls = list()
    ))
  }

  dplyr::tibble(
    uri                 = purrr::map_chr(raw_posts, "uri"),
    indexed_at          = purrr::map_chr(raw_posts, "indexedAt"),
    post_text           = purrr::map_chr(raw_posts, \(p) p$record$text %||% NA_character_),
    author_handle       = purrr::map_chr(raw_posts, \(p) p$author$handle %||% NA_character_),
    author_display_name = purrr::map_chr(raw_posts, \(p) p$author$displayName %||% NA_character_),
    author_avatar       = purrr::map_chr(raw_posts, \(p) p$author$avatar %||% NA_character_),
    like_count          = purrr::map_int(raw_posts, \(p) p$likeCount %||% 0L),
    repost_count        = purrr::map_int(raw_posts, \(p) p$repostCount %||% 0L),
    reply_count         = purrr::map_int(raw_posts, \(p) p$replyCount %||% 0L),
    is_reply            = purrr::map_lgl(raw_posts, \(p) !is.null(p$record$reply)),
    image_urls          = purrr::map(raw_posts, extract_image_urls)
  )
}

extract_image_urls <- function(post) {
  tryCatch({
    embed <- post$embed
    if (is.null(embed)) return(character(0))

    embed_type <- embed$`$type` %||% NA_character_
    if (is.na(embed_type)) return(character(0))

    if (embed_type == "app.bsky.embed.images#view") {
      images <- embed$images
      if (is.null(images) || length(images) == 0) return(character(0))
      purrr::map_chr(images, \(img) img$thumb %||% NA_character_)
    } else if (embed_type == "app.bsky.embed.recordWithMedia#view") {
      media <- embed$media
      if (is.null(media) || is.null(media$images)) return(character(0))
      purrr::map_chr(media$images, \(img) img$thumb %||% NA_character_)
    } else {
      character(0)
    }
  }, error = function(e) character(0))
}
