open Tyxml

let meta_tags ~description =
  let open Html in
  [
    meta ~a:[ a_charset "utf-8" ] ();
    meta
      ~a:
        [ a_name "viewport"; a_content "width=device-width, initial-scale=1.0" ]
      ();
    meta ~a:[ a_name "description"; a_content description ] ();
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
    script
      (txt
         "(function() {\n\
         \      const theme = localStorage.getItem('theme')\n\
         \        || (matchMedia('(prefers-color-scheme: dark)').matches ? \
          'dark' : 'light');\n\
         \      document.documentElement.setAttribute('data-theme', theme);\n\
         \      document.documentElement.style.colorScheme = theme;\n\
         \    })();");
    link ~rel:[ `Stylesheet ] ~href:"/static/css/main.css" ();
    link ~rel:[ `Stylesheet ] ~href:"/static/css/highlight.css" ();
    link ~rel:[ `Icon ] ~href:"/static/images/favicon.svg"
      ~a:[ a_mime_type "image/svg+xml" ]
      ();
    script ~a:[ a_src "/static/js/main.js"; a_defer () ] (txt "");
    script ~a:[ a_src "/static/js/theme-toggle.js"; a_defer () ] (txt "");
    script ~a:[ a_src "/static/js/highlight.min.js" ] (txt "");
  ]

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
