(* Basic configuration type for the static site generator *)
type config =
  { site_title : string
  ; site_description : string
  ; author : string
  ; base_url : string
  ; output_dir : string
  ; content_dir : string
  ; template_dir : string
  ; static_dir : string
  }

(* Page metadata from frontmatter *)
type page_metadata =
  { title : string
  ; date : string option
  ; tags : string list
  ; summary : string option
  ; draft : bool
  }

(* Processed page content *)
type page =
  { metadata : page_metadata
  ; content : string
  ; url : string
  ; source_path : string
  }

(* Default empty metadata *)
let empty_metadata =
  { title = "Untitled"; date = None; tags = []; summary = None; draft = false }
;;

(* Parse YAML frontmatter from markdown content *)
let parse_frontmatter content =
  try
    (* Check if content starts with "---" *)
    let content_length = String.length content in
    if content_length > 6 && String.sub content 0 3 = "---"
    then (
      (* Find the end of frontmatter (second "---") *)
      let rec find_end i =
        if i + 2 >= content_length
        then None
        else if String.sub content i 3 = "---"
        then Some i
        else find_end (i + 1)
      in
      match find_end 3 with
      | Some end_pos ->
        let frontmatter = String.sub content 3 (end_pos - 3) in
        let remaining = String.sub content (end_pos + 3) (content_length - end_pos - 3) in
        (* Parse the YAML *)
        (try
           let _yaml = Yaml.of_string frontmatter in
           (* Convert to metadata *)
           (* This is a basic implementation - expand with proper error handling *)
           empty_metadata, remaining
         with
         | _ -> empty_metadata, content)
      | None -> empty_metadata, content)
    else empty_metadata, content
  with
  | _ -> empty_metadata, content
;;

(* Process markdown with frontmatter *)
let process_content file_path =
  try
    let content =
      Sys.readdir file_path |> ignore;
      "TODO: Implement file reading"
    in
    let metadata, _markdown = parse_frontmatter content in
    let html = "TODO: Convert markdown to HTML" in
    Some { metadata; content = html; url = "/TODO/url"; source_path = file_path }
  with
  | _ -> None
;;

(* Utility functions - to be implemented *)
let generate_rss_feed _pages _config =
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss version=\"2.0\"></rss>"
;;
