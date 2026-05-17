open Tyxml

(** Footer component for all pages *)
module Footer = struct
  (** Copyright notice *)
  let copyright ?(year = 2026) ?(name = "Your Name") () =
    let open Html in
    p
      ~a:[ a_class [ "copyright" ] ]
      [ Html.txt (Printf.sprintf "© %d %s. All rights reserved." year name) ]

  let make ?(year = 2026) ?(name = "Your Name") () =
    let open Html in
    footer
      ~a:[ a_class [ "site-footer" ] ]
      [ div ~a:[ a_class [ "footer-bottom" ] ] [ copyright ~year ~name () ] ]
end
