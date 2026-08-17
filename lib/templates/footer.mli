open Tyxml

module Footer : sig
  val copyright :
    ?year:int -> ?name:string -> unit -> [> Html_types.p ] Html.elt
end
