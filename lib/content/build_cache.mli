(** Incremental-build cache: maps each source file to a content hash so
    unchanged files can be skipped on rebuild. *)

type t

(** Load the cache from [cache_file]; empty if the file is absent or unreadable.
*)
val load : cache_file:string -> t

(** An empty cache that will persist to [cache_file] (used for a forced full
    rebuild). *)
val empty : cache_file:string -> t

(** Whether [file] must be rebuilt: true if it has no recorded hash, its content
    changed since last build, or it is an aggregating section index (which is
    always rebuilt). *)
val needs_rebuild : t -> string -> bool

(** Record [file]'s current content hash, and invalidate the section index that
    aggregates it (so blog/journal listings regenerate). *)
val record : t -> string -> t

(** Persist the cache to its file. *)
val save : t -> unit
