(** File-based content loader system *)

open Base
open Stdio
open Content_types

(** Load content from a file path *)
let load_file path =
  try
    let content = In_channel.read_all path in
    Ok content
  with _ -> Error (Printf.sprintf "Failed to read file: %s" path)

(** Check if a file has a supported content extension *)
let is_content_file path =
  let supported_extensions = [ ".md"; ".markdown" ] in
  let ext = Stdlib.Filename.extension path in
  List.exists supported_extensions ~f:(String.equal ext)

(** Load all content files from a directory recursively *)
let rec load_directory_content ~content_dir ~base_dir =
  try
    let dir_contents = Stdlib.Sys.readdir base_dir |> Array.to_list in
    List.concat_map dir_contents ~f:(fun entry ->
        let full_path = Stdlib.Filename.concat base_dir entry in
        if Stdlib.Sys.is_directory full_path then
          load_directory_content ~content_dir ~base_dir:full_path
        else if is_content_file full_path then
          let relative_path =
            String.drop_prefix full_path (String.length content_dir + 1)
          in
          match load_file full_path with
          | Ok content ->
              [
                Markdown_parser.parse_markdown_file ~path:relative_path ~content;
              ]
          | Error _ -> []
        else [])
  with Sys_error _ -> []

(** Load all content from the content directory *)
let load_all_content ~content_dir =
  if Stdlib.Sys.file_exists content_dir && Stdlib.Sys.is_directory content_dir
  then load_directory_content ~content_dir ~base_dir:content_dir
  else []

(** Group content pages by content type *)
let group_by_content_type pages =
  List.fold pages
    ~init:(Map.empty (module String))
    ~f:(fun acc page ->
      let content_type =
        let dir = Stdlib.Filename.dirname page.path in
        if String.equal dir "." then "pages"
        else if String.is_prefix dir ~prefix:"blog" then "posts"
        else if String.is_prefix dir ~prefix:"projects" then "projects"
        else "pages"
      in

      let existing = Map.find acc content_type |> Option.value ~default:[] in
      Map.set acc ~key:content_type ~data:(page :: existing))

(** Filter content pages (e.g., to exclude drafts) *)
let filter_pages ?(include_drafts = false) pages =
  List.filter pages ~f:(fun page ->
      include_drafts || not page.frontmatter.draft)

(** Sort content pages by date (newest first) *)
let sort_pages_by_date pages =
  let compare_dates a b =
    match (a.frontmatter.date, b.frontmatter.date) with
    | Some date_a, Some date_b -> String.compare date_b date_a
    | Some _, None -> -1
    | None, Some _ -> 1
    | None, None -> 0
  in
  List.sort pages ~compare:compare_dates
