open Tyxml

(** SEO and metadata components for page heads *)
module Seo = struct
  (** Generate Open Graph meta tags for social sharing *)
  let open_graph_meta ~title_text ~description ~url
      ?(image = "/static/images/default-og.jpg") ?(type_ = "website") () =
    let open Html in
    [
      meta ~a:[ a_property "og:title"; a_content title_text ] ();
      meta ~a:[ a_property "og:description"; a_content description ] ();
      meta ~a:[ a_property "og:url"; a_content url ] ();
      meta ~a:[ a_property "og:image"; a_content image ] ();
      meta ~a:[ a_property "og:type"; a_content type_ ] ();
    ]

  (** Canonical URL link for a page. Tyxml has no dedicated [`Canonical]
      linktype, so we use the [`Other] escape hatch (the same pattern as the
      preload link in {!Template_base}). Renders [<link rel="canonical" ...>].
  *)
  let canonical_link ~url =
    let open Html in
    link ~rel:[ `Other "canonical" ] ~href:url ()

  (** Generate complete SEO metadata for a page: a canonical link, the Open
      Graph tags, and — on [article] pages — [article:modified_time] and
      [article:author] when [modified]/[author] are supplied. *)
  let make_head ~title_text ~description ~url
      ?(image = "/static/images/default-og.jpg") ?(type_ = "website") ?modified
      ?author () =
    let open Html in
    let article_meta =
      if String.equal type_ "article" then
        List.filter_map Fun.id
          [
            Option.map
              (fun m ->
                meta ~a:[ a_property "article:modified_time"; a_content m ] ())
              modified;
            Option.map
              (fun a -> meta ~a:[ a_property "article:author"; a_content a ] ())
              author;
          ]
      else []
    in
    canonical_link ~url
    :: open_graph_meta ~title_text ~description ~url ~image ~type_ ()
    @ article_meta
end
