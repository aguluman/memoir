(** Path resolution and routing.

    Single source of truth for mapping a content file to its canonical site URL
    and its generated output path, and for classifying a file's content type.
    Consumed by [bin/generator.ml]. *)

(* Drop a leading [prefix] from [s] if present. *)
let chop_prefix ~prefix s =
  let pl = String.length prefix in
  if String.length s >= pl && String.sub s 0 pl = prefix then
    String.sub s pl (String.length s - pl)
  else s

(* Strip the file extension and the "content/" then "pages/" wrappers, and
   normalise Windows separators to forward slashes. Works on full paths
   ("content/pages/blog/foo.md") and bare relative ones ("about.md") alike. *)
let clean_base path =
  Filename.remove_extension path
  |> chop_prefix ~prefix:"content/"
  |> chop_prefix ~prefix:"pages/"
  |> String.map (function
    | '\\' -> '/'
    | c -> c)

(** Canonical site URL for a content file:
    - "content/pages/index.md" -> "/"
    - "content/pages/about/index.md" -> "/about"
    - "content/pages/blog/foo.md" -> "/blog/foo"

    Section index files canonicalize to their directory (no trailing "/index"),
    and the result never has a doubled leading slash. *)
let path_to_url_path content_path =
  let base = clean_base content_path in
  let url = if base = "index" then "/" else "/" ^ base in
  if String.ends_with ~suffix:"/index" url then Filename.dirname url else url

(** Output file path under [output_dir] for a content file:
    - root index -> output_dir/index.html
    - section index-> output_dir/<section>/index.html
    - normal page -> output_dir/<path>/index.html *)
let path_to_output_path content_path ~output_dir =
  let base = clean_base content_path in
  if Filename.basename base = "index" then
    if base = "index" then Filename.concat output_dir "index.html"
    else Filename.concat output_dir (Filename.dirname base ^ "/index.html")
  else Filename.concat output_dir (base ^ "/index.html")

(** Classify a content file by the directory it lives in. Matches the project's
    [content/pages/<section>/...] layout (and the flatter [content/<section>]
    form for resilience). Extension-less files are treated as raw assets. *)
let classify path =
  match Filename.dirname path with
  | "content/blog" | "content/pages/blog" -> Content_types.Post
  | "content/projects" | "content/pages/projects" -> Content_types.Project
  | "content/journal" | "content/pages/journal" -> Content_types.Journal
  | "content/pages" | "content" -> Content_types.Page
  | _ when Filename.extension path = "" -> Content_types.Asset
  | _ -> Content_types.Page
