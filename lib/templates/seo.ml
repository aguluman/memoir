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

  (** Generate complete SEO metadata for a page *)
  let make_head ~title_text ~description ~url
      ?(image = "/static/images/default-og.jpg") ?(type_ = "website") () =
    open_graph_meta ~title_text ~description ~url ~image ~type_ ()
end
