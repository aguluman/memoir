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
    (* Preload critical fonts for faster rendering - only the Regular weight for initial load *)
    link
      ~rel:[ `Other "preload" ]
      ~href:"/static/fonts/JetBrainsMono-Regular.woff2"
      ~a:
        [
          a_user_data "as" "font";
          a_user_data "type" "font/woff2";
          a_user_data "crossorigin" "anonymous";
        ]
      ();
    (* Ultra-fast theme application - runs before any CSS to prevent flicker *)
    script
      (txt
         "(function() {\n\
         \      const theme = localStorage.getItem('theme');\n\
         \      if (theme === 'dark') {\n\
         \        document.documentElement.setAttribute('data-theme', 'dark');\n\
         \        document.documentElement.style.colorScheme = 'dark';\n\
         \      } else if (theme === 'light') {\n\
         \        document.documentElement.setAttribute('data-theme', 'light');\n\
         \        document.documentElement.style.colorScheme = 'light';\n\
         \      }\n\
         \    })();");
    (* Main stylesheet *)
    link ~rel:[ `Stylesheet ] ~href:"/static/css/main.css" ();
    (* Highlight CSS *)
    link ~rel:[ `Stylesheet ] ~href:"/static/css/highlight.css" ();
    (* Favicon *)
    link ~rel:[ `Icon ] ~href:"/static/images/favicon.svg"
      ~a:[ a_mime_type "image/svg+xml" ]
      ();
    (* Main JavaScript *)
    script ~a:[ a_src "/static/js/main.js"; a_defer () ] (txt "");
    (* Theme toggle JavaScript *)
    script ~a:[ a_src "/static/js/theme-toggle.js"; a_defer () ] (txt "");
    (* Highlight.js — synchronous so hljs is defined before deferred main.js runs *)
    script ~a:[ a_src "/static/js/highlight.min.js" ] (txt "");
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
           ~a:
             [
               a_class [ "theme-toggle" ];
               a_title "Toggle dark/light mode";
               a_user_data "aria-label" "Toggle dark/light mode";
             ]
           [
             span ~a:[ a_class [ "sun-icon" ] ] [ txt "☀️" ];
             span ~a:[ a_class [ "moon-icon" ] ] [ txt "🌙" ];
           ];
         header ~a:[ a_class [ "site-header" ] ] header_content;
         main content;
         footer ~a:[ a_class [ "site-footer" ] ] footer_content;
       ])
