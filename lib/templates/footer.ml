open Tyxml

(** Footer component for all pages *)
module Footer = struct
  (** Social media links *)
  let social_links =
    let open Html in
    [
      li
        [
          a
            ~a:
              [
                a_href "https://github.com";
                a_title "GitHub";
                a_rel [ `Noopener; `Noreferrer ];
                a_target "_blank";
              ]
            [ Html.txt "GitHub" ];
        ];
      li
        [
          a
            ~a:
              [
                a_href "https://twitter.com";
                a_title "Twitter";
                a_rel [ `Noopener; `Noreferrer ];
                a_target "_blank";
              ]
            [ Html.txt "Twitter" ];
        ];
      li
        [
          a
            ~a:
              [
                a_href "https://linkedin.com";
                a_title "LinkedIn";
                a_rel [ `Noopener; `Noreferrer ];
                a_target "_blank";
              ]
            [ Html.txt "LinkedIn" ];
        ];
    ]

  (** Footer navigation links *)
  let footer_nav_links =
    let open Html in
    [
      li [ a ~a:[ a_href "/" ] [ Html.txt "Home" ] ];
      li [ a ~a:[ a_href "/about" ] [ Html.txt "About" ] ];
      li [ a ~a:[ a_href "/privacy" ] [ Html.txt "Privacy Policy" ] ];
      li [ a ~a:[ a_href "/terms" ] [ Html.txt "Terms of Use" ] ];
      li [ a ~a:[ a_href "/journal" ] [ Html.txt "Journal" ] ];
      (* Daily Entry: a recollection of how my day was spent *)
    ]

  (** Copyright notice *)
  let copyright ?(year = 2023) ?(name = "Your Name") () =
    let open Html in
    p
      ~a:[ a_class [ "copyright" ] ]
      [ Html.txt (Printf.sprintf "© %d %s. All rights reserved." year name) ]

  (** Complete footer component *)
  let make ?(year = 2023) ?(name = "Your Name") () =
    let open Html in
    footer
      ~a:[ a_class [ "site-footer" ] ]
      [
        div
          ~a:[ a_class [ "container" ]; a_class [ "footer-container" ] ]
          [
            div
              ~a:[ a_class [ "footer-section" ] ]
              [
                h3 [ Html.txt "Connect" ];
                ul ~a:[ a_class [ "social-links" ] ] social_links;
              ];
            div
              ~a:[ a_class [ "footer-section" ] ]
              [
                h3 [ Html.txt "Site Links" ];
                ul ~a:[ a_class [ "footer-nav" ] ] footer_nav_links;
              ];
            div
              ~a:[ a_class [ "footer-section" ] ]
              [
                h3 [ Html.txt "Subscribe" ];
                p
                  [
                    Html.txt
                      "Stay updated with my latest projects and articles.";
                  ];
                div
                  ~a:[ a_class [ "footer-form" ] ]
                  [
                    (* Placeholder for subscription form *)
                    p [ Html.txt "Subscription form coming soon" ];
                  ];
              ];
          ];
        div ~a:[ a_class [ "footer-bottom" ] ] [ copyright ~year ~name () ];
      ]
end
