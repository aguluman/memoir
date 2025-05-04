(** Main templates module that re-exports all template components *)

open Header
open Footer
open Navigation
open Seo
open Template_base  (* Add this line to import layout and doctype *)

(** Convenient function to create a page with all components *)
let create_page ?(lang = "en") ?(current_path = "/") ?(page_class = "page")
    ?(year = 2023) ?(author = "Site Author") ?(twitter_handle = "@siteauthor")
    ?(additional_head = []) ~title ~description ~content ~url () =
  let open Tyxml in
  let nav = Navigation.make ~current_path () in

  (* Create header content directly instead of using Header.make *)
  let header_content =
    let open Html in
    [
      div
        ~a:[ a_class [ "container" ]; a_class [ "header-container" ] ]
        [
          Header.logo ();
          Header.nav_toggle ();
          Header.navigation ();
        ];
    ]
  in

  (* Create footer content directly instead of using Footer.make *)
  let footer_content =
    let open Html in
    [
      div
        ~a:[ a_class [ "container" ]; a_class [ "footer-container" ] ]
        [
          div
            ~a:[ a_class [ "footer-section" ] ]
            [
              h3 [ Html.txt "Connect" ];
              ul ~a:[ a_class [ "social-links" ] ] Footer.social_links;
            ];
          div
            ~a:[ a_class [ "footer-section" ] ]
            [
              h3 [ Html.txt "Site Links" ];
              ul ~a:[ a_class [ "footer-nav" ] ] Footer.footer_nav_links;
            ];
          div
            ~a:[ a_class [ "footer-section" ] ]
            [
              h3 [ Html.txt "Subscribe" ];
              p
                [ Html.txt "Stay updated with my latest projects and articles." ];
              div
                ~a:[ a_class [ "footer-form" ] ]
                [
                  (* Placeholder for subscription form *)
                  p [ Html.txt "Subscription form coming soon" ];
                ];
            ];
        ];
      div 
        ~a:[ a_class [ "footer-bottom" ] ] 
        [ Footer.copyright ~year ~name:author () ];
    ]
  in

  (* Get SEO meta content without the title element *)
  let seo_without_title =
    let open_graph = Seo.open_graph_meta ~title_text:title ~description ~url 
      ~type_:(if current_path = "/" then "website" else "article") () in
    let twitter_card = Seo.twitter_card_meta ~title_text:title ~description ~twitter_handle () in
    let canonical = [Seo.canonical_url ~url] in
    let schema = [Seo.schema_jsonld ~schema_type:"WebPage" ~title_text:title ~description ~url ()] in
    open_graph @ twitter_card @ canonical @ schema
  in

  (* Add header, navigation, page content, and footer to the layout *)
  let html_output = 
    layout 
      ~lang 
      ~title_text:title 
      ~description 
      ~page_class
      ~additional_head:(seo_without_title @ additional_head)
      ~header_content
      ~content:(nav :: content) 
      ~footer_content
      () 
  in
  doctype ^ Format.asprintf "%a" (Html.pp ()) html_output
