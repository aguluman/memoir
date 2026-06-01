(** File-based content loading.

    Single source of truth for enumerating content files and building the
    blog/journal listing entries injected into section index pages. (The
    RSS-feed loader lives in {!Memoir_lib}.) *)

(** A listing entry rendered onto blog/journal index pages. *)
type entry = {
  title : string;
  date : Content_types.Date.t option;
  description : string option;
  url : string;
}

(** Every file under the given root directory, recursively, skipping the
    generated [_site] directory. *)
val walk_files : string -> string list

(** Listing entries for the markdown files directly in [dir] (excluding
    [index.md]), each URL prefixed with [url_prefix], sorted newest-first
    (undated entries fall back to title order; titles missing from frontmatter
    fall back to the file's slug). *)
val list_entries : dir:string -> url_prefix:string -> entry list
