(** Markdown parsing with YAML frontmatter support. *)

(** Split raw file content into [(Some yaml, body)] when it begins with a [---]
    frontmatter block, or [(None, content)] otherwise. *)
val extract_frontmatter : string -> string option * string

(** Parse a YAML frontmatter string into a {!Content_types.frontmatter}.
    Malformed YAML yields {!Content_types.empty_frontmatter}. *)
val parse_yaml_frontmatter : string -> Content_types.frontmatter

(** Parse just the frontmatter record from raw file content; returns
    {!Content_types.empty_frontmatter} when no block is present. *)
val frontmatter_of_content : string -> Content_types.frontmatter

(** Render markdown body text to an HTML string. *)
val parse_markdown : string -> string

(** Parse a markdown file (frontmatter + body) into a content page with its HTML
    rendered. *)
val parse_markdown_file :
  path:string -> content:string -> Content_types.content_page
