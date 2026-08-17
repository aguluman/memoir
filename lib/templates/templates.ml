open Template_base
open Navigation
open Seo
open Webring
open Footer

let create_page ?(lang = "en") ?(current_path = "/") ?(page_class = "page")
    ?(year = 0000) ?(author = "Site Author") ?image ?modified ~title_text
    ~description ~content ~url () =
  let open Tyxml in
  let nav = Navigation.make ~current_path () in

  let seo_head =
    Seo.make_head ~title_text ~description ~url
      ~type_:(if current_path = "/" then "website" else "article")
      ?image ?modified ~author ()
  in

  let content =
    content @ [ (Webring.navigation () : Html_types.flow5 Html.elt) ]
  in

  let html_output =
    layout ~lang ~title_text ~description ~page_class ~additional_head:seo_head
      ~header_content:[ Html.div [ nav ] ]
      ~content
      ~footer_content:
        [
          Html.div
            ~a:[ Html.a_class [ "footer-bottom" ] ]
            [ Footer.copyright ~year ~name:author () ];
        ]
      ()
  in

  Format.asprintf "%a" (Html.pp ()) html_output
