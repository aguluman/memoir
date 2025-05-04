(** Markdown parser with frontmatter support *)

open Base
open Content_types

(** Extract frontmatter from markdown content *)
let extract_frontmatter content =
  (* Pattern that uses simpler regex for line breaks *)
  let frontmatter_pattern = "^---\n\\(\\(.\\|\n\\)*?\\)\n---\n" in
  let re = Str.regexp frontmatter_pattern in

  if Str.string_match re content 0 then
    let yaml_content = Str.matched_group 1 content in
    let content_without_frontmatter =
      String.drop_prefix content (Str.match_end ())
    in
    (Some yaml_content, content_without_frontmatter)
  else (None, content)

(** Parse YAML frontmatter string into frontmatter record *)
let parse_yaml_frontmatter yaml_str =
  try
    match Yaml.of_string yaml_str with
    | Error _ -> empty_frontmatter
    | Ok yaml ->
        let get_string yaml key =
          match Yaml.Util.find key yaml with
          | Ok (Some (`String s)) -> Some s
          | _ -> None
        in

        let get_string_list yaml key =
          match Yaml.Util.find key yaml with
          | Ok (Some (`A lst)) ->
              List.filter_map lst ~f:(function
                | `String s -> Some s
                | _ -> None)
          | _ -> []
        in

        let get_bool yaml key =
          match Yaml.Util.find key yaml with
          | Ok (Some (`Bool b)) -> b
          | _ -> false
        in

        {
          title = get_string yaml "title" |> Option.value ~default:"Untitled";
          description = get_string yaml "description";
          date = get_string yaml "date";
          updated = get_string yaml "updated";
          tags = get_string_list yaml "tags";
          draft = get_bool yaml "draft";
          layout = get_string yaml "layout";
          slug = get_string yaml "slug";
          author = get_string yaml "author";
          featured_image = get_string yaml "featured_image";
        }
  with _ -> empty_frontmatter

(** Parse markdown content into HTML *)
let parse_markdown content =
  let html = Omd.of_string content |> Omd.to_html in
  html

(** Parse a markdown file with frontmatter into a content_page *)
let parse_markdown_file ~path ~content =
  let frontmatter_yaml, markdown_content = extract_frontmatter content in
  let frontmatter =
    match frontmatter_yaml with
    | Some yaml -> parse_yaml_frontmatter yaml
    | None -> empty_frontmatter
  in

  let html_content = parse_markdown markdown_content in
  let url_path =
    match frontmatter.slug with
    | Some slug -> slug
    | None ->
        (* Derive URL path from the file path *)
        let base_name = Stdlib.Filename.basename path in
        let without_ext = Stdlib.Filename.remove_extension base_name in
        let dir_path = Stdlib.Filename.dirname path in
        if String.equal dir_path "." then "/" ^ without_ext
        else "/" ^ dir_path ^ "/" ^ without_ext
  in

  {
    path;
    frontmatter;
    content = markdown_content;
    html_content = Some html_content;
    url_path;
  }
