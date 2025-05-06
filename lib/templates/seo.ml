open Tyxml

(** SEO and metadata components for page heads *)
module Seo = struct
  (** Generate basic meta tags *)
  let basic_meta ~title_text ~description =
    let open Html in
    [
      meta ~a:[ a_charset "utf-8" ] ();
      meta
        ~a:
          [
            a_name "viewport"; a_content "width=device-width, initial-scale=1.0";
          ]
        ();
      meta ~a:[ a_name "description"; a_content description ] ();
      title (txt title_text);
    ]

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

  (** Generate Twitter Card meta tags *)
  let twitter_card_meta ~title_text ~description
      ?(image = "/static/images/default-og.jpg")
      ?(card_type = "summary_large_image") ?(twitter_handle = "@yourusername")
      () =
    let open Html in
    [
      meta ~a:[ a_name "twitter:card"; a_content card_type ] ();
      meta ~a:[ a_name "twitter:site"; a_content twitter_handle ] ();
      meta ~a:[ a_name "twitter:title"; a_content title_text ] ();
      meta ~a:[ a_name "twitter:description"; a_content description ] ();
      meta ~a:[ a_name "twitter:image"; a_content image ] ();
    ]

  (** Generate canonical URL meta tag *)
  let canonical_url ~url =
    let open Html in
    link ~rel:[ `Canonical ] ~href:url ()

  (** Generate article-specific metadata for blog posts *)
  let article_meta ~author ~date ~tags =
    let open Html in
    [
      meta ~a:[ a_property "article:author"; a_content author ] ();
      meta ~a:[ a_property "article:published_time"; a_content date ] ();
    ]
    @ List.map
        (fun tag -> meta ~a:[ a_property "article:tag"; a_content tag ] ())
        tags

  (** Generate schema.org JSON-LD structured data *)
  let schema_jsonld ~schema_type ~title_text ~description ~url
      ?(image = "/static/images/default-og.jpg") ?(additional_fields = []) () =
    let base_schema =
      [
        ("@context", `String "https://schema.org");
        ("@type", `String schema_type);
        ("name", `String title_text);
        ("description", `String description);
        ("url", `String url);
        ("image", `String image);
      ]
    in

    let full_schema = `Assoc (base_schema @ additional_fields) in
    let json_string = Yojson.Basic.to_string full_schema in

    Html.script
      ~a:[ Html.a_user_data "type" "application/ld+json" ]
      (Html.txt json_string)

  (** Generate complete SEO metadata for a page *)
  let make_head ~title_text ~description ~url
      ?(image = "/static/images/default-og.jpg") ?(type_ = "website")
      ?(twitter_handle = "@yourusername") ?(schema_type = "WebPage")
      ?(additional_fields = []) ?(additional_meta = []) () =
    basic_meta ~title_text ~description
    @ open_graph_meta ~title_text ~description ~url ~image ~type_ ()
    @ twitter_card_meta ~title_text ~description ~image ~twitter_handle ()
    @ [
        canonical_url ~url;
        schema_jsonld ~schema_type ~title_text ~description ~url ~image
          ~additional_fields ();
      ]
    @ additional_meta
end
