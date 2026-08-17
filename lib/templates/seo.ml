open Tyxml

module Seo = struct
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

  let canonical_link ~url =
    let open Html in
    link ~rel:[ `Other "canonical" ] ~href:url ()

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
