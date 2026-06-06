(** Markdown parser with frontmatter support *)

open Base
open Content_types

(** Extract frontmatter from markdown content *)
let extract_frontmatter content =
  let frontmatter_pattern = "^---\n\\([^-]\\|-[^-]\\)*\n---\n" in
  let re = Str.regexp frontmatter_pattern in
  if Str.string_match re content 0 then
    let yaml_content = String.sub ~pos:4 ~len:(Str.match_end () - 8) content in
    let content_start = Str.match_end () in
    let content_without_frontmatter =
      String.sub ~pos:content_start
        ~len:(String.length content - content_start)
        content
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
          date = Option.bind (get_string yaml "date") ~f:Date.of_string;
          updated = Option.bind (get_string yaml "updated") ~f:Date.of_string;
          tags = get_string_list yaml "tags";
          draft = get_bool yaml "draft";
          layout = get_string yaml "layout";
          slug = get_string yaml "slug";
          author = get_string yaml "author";
          featured_image = get_string yaml "featured_image";
        }
  with _ -> empty_frontmatter

(** Parse just the frontmatter record from raw file content. Returns
    {!Content_types.empty_frontmatter} when no frontmatter block is present, so
    a completely empty record (title = "") signals "no frontmatter at all",
    while a present-but-titleless block yields the "Untitled" default. *)
let frontmatter_of_content content =
  match extract_frontmatter content with
  | Some yaml, _ -> parse_yaml_frontmatter yaml
  | None, _ -> empty_frontmatter

(** Parse markdown content into HTML with syntax highlighting support *)
let parse_markdown content =
  let preprocessed_content =
    let fix_backtick_spacing content =
      let backtick_regex = Str.regexp "```\\([^`\n]\\)" in
      let result = ref content in
      let pos = ref 0 in

      while Str.string_match backtick_regex !result !pos do
        let start_pos = Str.match_beginning () in

        (* Add a newline after the backticks *)
        let before = String.sub ~pos:0 ~len:(start_pos + 3) !result in
        let after =
          String.sub ~pos:(start_pos + 3)
            ~len:(String.length !result - (start_pos + 3))
            !result
        in
        result := before ^ "\n" ^ after;
        pos := start_pos + 4
      done;
      !result
    in

    (* Fix issue with improperly terminated code blocks *)
    let fix_unterminated_code_blocks content =
      let open_backtick_regex = Str.regexp "```[^\n]*\n" in
      let result = ref content in
      let positions = ref [] in
      let pos = ref 0 in

      (* Find all occurrences of opening triple backticks *)
      while Str.string_match open_backtick_regex !result !pos do
        let start_pos = Str.match_beginning () in
        let end_pos = Str.match_end () in
        positions := !positions @ [ start_pos ];
        pos := end_pos
      done;

      (* If we have an odd number of triple backticks, add a closing one *)
      if Int.rem (List.length !positions) 2 = 1 then
        result := !result ^ "\n```\n";

      !result
    in

    content |> fix_backtick_spacing |> fix_unterminated_code_blocks
  in

  let md = Omd.of_string preprocessed_content in

  (* Convert to HTML with auto identifiers for headings. Omd already emits
     [<pre><code class="language-LANG">] for fenced blocks carrying an info
     string, which is exactly what highlight.js consumes — so no post-hoc class
     injection is needed. (The previous regex pass tried to add these classes
     but used PCRE constructs [\s\S] and [*?] that OCaml's Str does not support,
     so it never matched a real code block and only added risk: removed.) *)
  Omd.to_html ~auto_identifiers:true md

(** Parse a markdown file with frontmatter into a content_page *)
let parse_markdown_file ~path ~content =
  let frontmatter_yaml, markdown_content = extract_frontmatter content in
  let frontmatter =
    match frontmatter_yaml with
    | Some yaml -> parse_yaml_frontmatter yaml
    | None -> empty_frontmatter
  in

  (* Process markdown after frontmatter *)
  let html_content = parse_markdown markdown_content in
  let url_path =
    match frontmatter.slug with
    | Some slug -> slug
    | None ->
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
