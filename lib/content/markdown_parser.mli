(** Markdown parsing with YAML frontmatter support. *)

(** Split raw file content into [(Some yaml, body)] when it begins with a [---]
    frontmatter block, or [(None, content)] otherwise. *)
val extract_frontmatter : string -> string option * string

(** Parse a YAML frontmatter string into a {!type:Content_types.frontmatter}.
    Raises [Failure] on malformed YAML (the metadata is never silently dropped).
*)
val parse_yaml_frontmatter : string -> Content_types.frontmatter

(** Parse the frontmatter from raw file content. [None] means the file has no
    frontmatter block at all. Raises [Failure] on malformed YAML. *)
val frontmatter_of_content : string -> Content_types.frontmatter option

(** Render markdown body text to an HTML string. *)
val parse_markdown : string -> string

(** Parse a markdown file (frontmatter + body) into a content page with its HTML
    rendered. *)
val parse_markdown_file :
  path:string -> content:string -> Content_types.content_page
