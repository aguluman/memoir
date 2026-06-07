(** Main templates module that re-exports all template components *)

open Footer
open Navigation
open Seo
open Template_base
open Webring

(** Convenient function to create a page with all components.

    [image] sets the Open Graph image, [modified] the article modified-time;
    both are optional and only meaningful on article pages. *)
let create_page ?(lang = "en") ?(current_path = "/") ?(page_class = "page")
    ?(year = 0000) ?(author = "Site Author") ?image ?modified ~title_text
    ~description ~content ~url () =
  let open Tyxml in
  let nav = Navigation.make ~current_path () in

  (* SEO head content: canonical link + Open Graph tags (no title element,
     which the layout emits separately). The homepage is a website; every other
     page is an article carrying author/modified metadata. *)
  let seo_head =
    Seo.make_head ~title_text ~description ~url
      ~type_:(if current_path = "/" then "website" else "article")
      ?image ?modified ~author ()
  in

  (* Webring navigation is appended to every page's content (single source of
     truth lives in Webring; previously this was an inline string in the
     generator). The annotation pins the element list to flow content so the
     public signature stays a simple closed type. *)
  let content =
    content @ [ (Webring.navigation () : Html_types.flow5 Html.elt) ]
  in

  (* Add navigation, page content, and footer to the layout *)
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

  (* Convert to string *)
  let html_string = doctype ^ Format.asprintf "%a" (Html.pp ()) html_output in
  html_string
