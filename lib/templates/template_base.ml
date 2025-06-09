open Tyxml

(** Base HTML templates and components *)

(** Generate HTML doctype *)
let doctype = "<!DOCTYPE html>"

(** Meta tags for SEO and responsiveness *)
let meta_tags ~description =
  let open Html in
  [
    meta ~a:[ a_charset "utf-8" ] ();
    meta
      ~a:
        [ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ]
      ();
    meta ~a:[ a_name "description"; a_content description ] ();
    link ~rel:[ `Stylesheet ] ~href:"/static/css/main.css" ();
    (* Favicon *)
    link ~rel:[ `Icon ] ~href:"/static/images/favicon.png"
      ~a:[ a_mime_type "image/png" ]
      ();
    (* Include any JavaScript *)
    script ~a:[ a_src "/static/js/main.js"; a_defer () ] (txt "");
    script ~a:[ a_src "/static/js/theme-toggle.js"; a_defer () ] (txt "");
  ]

(** Base HTML layout to be used by all pages *)
let layout ?(lang = "en") ~title_text ~description ~page_class
    ?(additional_head = []) ~header_content ~content ~footer_content () =
  let open Html in
  let meta_content = meta_tags ~description @ additional_head in

  html
    ~a:[ a_lang lang ]
    (head (title (txt title_text)) meta_content)
    (body
       ~a:[ a_class [ page_class ] ]
       [
         (* Theme toggle button *)
         button
           ~a:[ 
             a_class [ "theme-toggle" ]; 
             a_title "Toggle dark/light mode";
             a_user_data "aria-label" "Toggle dark/light mode"
           ]
           [
             span ~a:[ a_class [ "sun-icon" ] ] [ txt "☀️" ];
             span ~a:[ a_class [ "moon-icon" ] ] [ txt "🌙" ];
           ];
         header ~a:[ a_class [ "site-header" ] ] header_content;
         main content;
         footer ~a:[ a_class [ "site-footer" ] ] footer_content;
       ])
