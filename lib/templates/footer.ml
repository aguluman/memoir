open Tyxml

(** Footer component for all pages *)
module Footer = struct
  (** Copyright notice *)
  let copyright ?(year = 0000) ?(name = "Your Name") () =
    let open Html in
    p
      ~a:[ a_class [ "copyright" ] ]
      [ Html.txt (Printf.sprintf "© %d %s. All rights reserved." year name) ]
end
