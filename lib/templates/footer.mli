(** Footer components. *)

open Tyxml

module Footer : sig
  (** Copyright notice paragraph. *)
  val copyright :
    ?year:int -> ?name:string -> unit -> [> Html_types.p ] Html.elt
end
