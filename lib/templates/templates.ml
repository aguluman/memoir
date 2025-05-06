(** Main templates module that re-exports all template components *)

open Header
open Footer
open Navigation
open Seo
open Template_base

(** Convenient function to create a page with all components *)
let create_page ?(lang = "en") ?(current_path = "/") ?(page_class = "page")
    ?(year = 2023) ?(author = "Site Author") ?(twitter_handle = "@siteauthor")
    ?(additional_head = []) ~title_text ~description ~content ~url () =
  let open Tyxml in
  let nav = Navigation.make ~current_path () in
  let header = Header.make () in
  let footer = Footer.make ~year ~name:author () in

  (* Get SEO meta content without the title element *)
  let seo_meta =
    let open_graph =
      Seo.open_graph_meta ~title_text ~description ~url
        ~type_:(if current_path = "/" then "website" else "article")
        ()
    in
    let twitter_card =
      Seo.twitter_card_meta ~title_text ~description ~twitter_handle ()
    in
    let canonical = [ Seo.canonical_url ~url ] in
    let schema =
      [
        Seo.schema_jsonld ~schema_type:"WebPage" ~title_text ~description ~url
          ();
      ]
    in
    open_graph @ twitter_card @ canonical @ schema
  in

  (* Add header, navigation, page content, and footer to the layout *)
  let html_output =
    layout ~lang ~title_text ~description ~page_class
      ~additional_head:(seo_meta @ additional_head)
      ~header_content:[ Html.div [ header ] ]
      ~content:(nav :: content)
      ~footer_content:[ Html.div [ footer ] ]
      ()
  in
  doctype ^ Format.asprintf "%a" (Html.pp ()) html_output
