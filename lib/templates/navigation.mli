open Tyxml

module Navigation : sig
  val make : ?current_path:string -> unit -> [> Html_types.nav ] Html.elt
end
