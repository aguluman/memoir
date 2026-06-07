(** Site navigation component. *)

open Tyxml

module Navigation : sig
  (** Main navigation bar. [current_path] marks the matching link active. *)
  val make : ?current_path:string -> unit -> [> Html_types.nav ] Html.elt
end
