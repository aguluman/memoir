(** Markdown parser with frontmatter support *)

open Content_types

(** Extract frontmatter from markdown content *)
let extract_frontmatter content =
  let frontmatter_pattern = "^---\n\\([^-]\\|-[^-]\\)*\n---\n" in
  let re = Str.regexp frontmatter_pattern in
  if Str.string_match re content 0 then
    let yaml_content = String.sub content 4 (Str.match_end () - 8) in
    let content_start = Str.match_end () in
    let content_without_frontmatter =
      String.sub content content_start (String.length content - content_start)
    in
    (Some yaml_content, content_without_frontmatter)
  else (None, content)

(** Parse a YAML frontmatter string into a frontmatter record.

    Raises [Failure] on malformed YAML rather than silently returning an empty
    record (Leroy: surface the error so the build fails loudly instead of
    quietly dropping a page's metadata). A valid-but-keyless block still yields
    the field defaults (e.g. [title = "Untitled"]). *)
let parse_yaml_frontmatter yaml_str =
  match Yaml.of_string yaml_str with
  | Error (`Msg m) -> failwith (Printf.sprintf "invalid YAML frontmatter: %s" m)
  | Ok yaml ->
      let get_string yaml key =
        match Yaml.Util.find key yaml with
        | Ok (Some (`String s)) -> Some s
        | _ -> None
      in
      let get_string_list yaml key =
        match Yaml.Util.find key yaml with
        | Ok (Some (`A lst)) ->
            List.filter_map
              (function
                | `String s -> Some s
                | _ -> None)
              lst
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
        date = Option.bind (get_string yaml "date") Date.of_string;
        updated = Option.bind (get_string yaml "updated") Date.of_string;
        tags = get_string_list yaml "tags";
        draft = get_bool yaml "draft";
        layout = get_string yaml "layout";
        slug = get_string yaml "slug";
        author = get_string yaml "author";
        featured_image = get_string yaml "featured_image";
      }

(** Parse the frontmatter from raw file content.

    Returns [None] when the file has no frontmatter block at all — that absence
    is now explicit in the type rather than encoded as a [title = ""] sentinel
    (Minsky). A present-but-titleless block yields [Some] with the field
    defaults. Raises [Failure] (via {!parse_yaml_frontmatter}) on malformed
    YAML. *)
let frontmatter_of_content content =
  match extract_frontmatter content with
  | Some yaml, _ -> Some (parse_yaml_frontmatter yaml)
  | None, _ -> None

(** Parse markdown content into HTML with syntax highlighting support *)
let parse_markdown content =
  (* Convert to HTML with auto identifiers for headings. Omd already emits
     [<pre><code class="language-LANG">] for fenced blocks carrying an info
     string, which is exactly what highlight.js consumes.

     Two preprocessing passes (backtick-spacing and unterminated-fence repair)
     used to run here, plus a class-injection pass; all three were removed. Each
     drove [Str] with an anchored [string_match]/unsupported PCRE pattern, so
     they only fired when the input *began* with a fence — which post-frontmatter
     body text never does. They were no-ops that only added risk. *)
  Omd.to_html ~auto_identifiers:true (Omd.of_string content)

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
        let base_name = Filename.basename path in
        let without_ext = Filename.remove_extension base_name in
        let dir_path = Filename.dirname path in
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
