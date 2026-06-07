(** Path resolution and routing.

    Single source of truth for mapping a content file to its canonical site URL
    and its generated output path, and for classifying a file's content type. *)

(** Canonical site URL for a content file. Strips the [content/] and [pages/]
    wrappers and the extension, normalises separators, and canonicalises section
    index files (no trailing ["/index"], no doubled leading slash):
    - ["content/pages/index.md"] {b ->} ["/"]
    - ["content/pages/about/index.md"] {b ->} ["/about"]
    - ["content/pages/blog/foo.md"] {b ->} ["/blog/foo"] *)
val path_to_url_path : string -> string

(** Output file path under [output_dir] for a content file:
    - root index {b ->} [output_dir/index.html]
    - section index {b ->} [output_dir/<section>/index.html]
    - normal page {b ->} [output_dir/<path>/index.html] *)
val path_to_output_path : string -> output_dir:string -> string

(** Classify a content file by the directory it lives in. Extension-less files
    are treated as raw assets ({!Content_types.Asset}). *)
val classify : string -> Content_types.content_type

(** Resolve a request URL to an existing file under [site_root] (the generated
    output directory), or [None] if nothing matches. The serve-time inverse of
    {!path_to_output_path}: same clean-URL → [<path>/index.html] convention, a
    [.html] fallback, and [static/]/[pages/] search subtrees. *)
val resolve_url : site_root:string -> string -> string option
