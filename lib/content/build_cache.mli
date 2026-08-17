type t

val load : cache_file:string -> t
val empty : cache_file:string -> t
val needs_rebuild : t -> string -> bool
val record : t -> string -> t
val save : t -> unit
