open Content_types

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

let frontmatter_of_content content =
  match extract_frontmatter content with
  | Some yaml, _ -> Some (parse_yaml_frontmatter yaml)
  | None, _ -> None

let parse_markdown content =
  Omd.to_html ~auto_identifiers:true (Omd.of_string content)

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
