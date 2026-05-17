(** Main templates module that re-exports all template components *)

open Footer
open Navigation
open Seo
open Template_base

(** Convenient function to create a page with all components *)
let create_page ?(lang = "en") ?(current_path = "/") ?(page_class = "page")
    ?(year = 0000) ?(author = "Site Author") ~title_text ~description ~content
    ~url () =
  let open Tyxml in
  let nav = Navigation.make ~current_path () in

  (* Get Open Graph  SEO meta content without the title element *)
  let open_graph =
    Seo.open_graph_meta ~title_text ~description ~url
      ~type_:(if current_path = "/" then "website" else "article")
      ()
  in

  (* Add navigation, page content, and footer to the layout *)
  let html_output =
    layout ~lang ~title_text ~description ~page_class
      ~additional_head:open_graph
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

  (* Convert to string *)
  let html_string = doctype ^ Format.asprintf "%a" (Html.pp ()) html_output in
  html_string
