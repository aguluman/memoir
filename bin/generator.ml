(* Configuration type *)
type config_type = {
  _site_title : string; (* TODO: Remove underscore when used *)
  _site_description : string; (* TODO: Remove underscore when used *)
  author : string;
  _base_url : string; (* TODO: Remove underscore when used *)
  output_dir : string;
  content_dir : string;
  _template_dir : string; (* TODO: Remove underscore when used *)
  static_dir : string;
}

(* Configuration *)
let config =
  {
    _site_title = "Here Lies My Thoughts and Convictions";
    _site_description = "A modern portfolio and memoir website built with OCaml";
    author = "Chukwuma Akunyili";
    _base_url = "https://aguluman.github.io/memoir/";
    output_dir = "_site";
    content_dir = "content";
    _template_dir = "templates";
    static_dir = "static";
  }

(* File utilities *)
let normalize_path path =
  let rec normalize acc = function
    | [] -> acc
    | "." :: rest -> normalize acc rest
    | ".." :: rest -> (
        match acc with
        | _ :: parent -> normalize parent rest
        | [] -> normalize [] rest)
    | x :: rest -> normalize (x :: acc) rest
  in
  let parts = Str.split (Str.regexp_string Filename.dir_sep) path in
  let normalized = normalize [] parts |> List.rev in
  String.concat Filename.dir_sep normalized

let ensure_directory_exists dir =
  let normalized_dir = normalize_path dir in
  try
    if not (Sys.file_exists normalized_dir) then
      let rec make_dir path =
        if not (Sys.file_exists path) then (
          make_dir (Filename.dirname path);
          Printf.printf "Creating directory: %s\n" path;
          Sys.mkdir path 0o755)
      in
      make_dir normalized_dir
    else if not (Sys.is_directory normalized_dir) then
      failwith
        (Printf.sprintf "%s exists but is not a directory" normalized_dir)
  with Sys_error msg ->
    failwith
      (Printf.sprintf "Failed to create directory %s: %s" normalized_dir msg)

let read_file path =
  let normalized_path = normalize_path path in
  try
    let ic = open_in normalized_path in
    try
      let len = in_channel_length ic in
      let content = really_input_string ic len in
      close_in ic;
      content
    with e ->
      close_in ic;
      raise
        (Failure
           (Printf.sprintf "Failed to read file %s: %s" normalized_path
              (Printexc.to_string e)))
  with Sys_error msg ->
    raise
      (Failure (Printf.sprintf "Failed to open file %s: %s" normalized_path msg))

let write_file path content =
  let normalized_path = normalize_path path in
  try
    ensure_directory_exists (Filename.dirname normalized_path);
    Printf.printf "Writing file: %s\n" normalized_path;
    let oc = open_out normalized_path in
    try
      output_string oc content;
      close_out oc
    with e ->
      close_out oc;
      raise
        (Failure
           (Printf.sprintf "Failed to write to file %s: %s" normalized_path
              (Printexc.to_string e)))
  with Sys_error msg ->
    raise
      (Failure
         (Printf.sprintf "Failed to create file %s: %s" normalized_path msg))

(* File type detection *)
type file_type =
  | HTML
  | CSS
  | JavaScript
  | Image
  | Other

let determine_file_type path =
  match String.lowercase_ascii (Filename.extension path) with
  | ".html" | ".htm" -> HTML
  | ".css" -> CSS
  | ".js" -> JavaScript
  | ".png" | ".jpg" | ".jpeg" | ".gif" | ".svg" | ".webp" -> Image
  | _ -> Other

let write_output_file ~content ~path =
  let dir = Filename.dirname path in
  ensure_directory_exists dir;
  let file_type = determine_file_type path in
  let oc =
    match file_type with
    | Image -> open_out_bin path (* Binary mode for images *)
    | _ -> open_out path (* Text mode for other files *)
  in
  output_string oc content;
  close_out oc;
  Printf.printf "Written: %s\n" path

(* Process markdown content *)
let _process_markdown content =
  (* TODO: Remove underscore when used *)
  let open Omd in
  let md = of_string content in
  to_html md

(* Enhanced static asset copying with content type detection *)
let copy_static_assets () =
  let rec copy_dir src_dir dst_dir =
    Printf.printf "Copying directory: %s -> %s\n" src_dir dst_dir;
    ensure_directory_exists dst_dir;
    try
      let entries = Sys.readdir src_dir in
      Array.iter
        (fun entry ->
          if
            not
              (List.mem entry [ ".git"; "_site"; "node_modules"; ".DS_Store" ])
          then
            let src_path = Filename.concat src_dir entry in
            let dst_path = Filename.concat dst_dir entry in
            if Sys.is_directory src_path then copy_dir src_path dst_path
            else (
              Printf.printf "Copying file: %s\n" entry;
              let content = read_file src_path in
              write_output_file ~content ~path:dst_path))
        entries
    with Sys_error msg ->
      raise
        (Failure (Printf.sprintf "Failed to copy directory %s: %s" src_dir msg))
  in
  let src = config.static_dir in
  let dst = Filename.concat config.output_dir "static" in
  if Sys.file_exists src then copy_dir src dst
  else Printf.printf "Warning: Static directory %s does not exist\n" src

(* Render HTML page *)
let _render_page ~title:_ ~content =
  (* TODO: Remove underscore when used *)
  let open Tyxml.Html in
  let doc =
    html
      (head
         (title (txt "Thoughts and Tiny-Experiments"))
         [
           meta ~a:[ a_charset "utf-8" ] ();
           meta
             ~a:
               [
                 a_name "viewport";
                 a_content "width=device-width, initial-scale=1";
               ]
             ();
           link ~rel:[ `Stylesheet ] ~href:"/static/css/main.css" ();
         ])
      (body
         [
           header [ h1 [ txt "Doing It Scared" ] ];
           main [ Tyxml.Html.Unsafe.data content ];
           footer
             [
               small
                 [
                   txt
                     ("© "
                     ^ string_of_int
                         ((Unix.localtime (Unix.time ())).Unix.tm_year + 1900)
                     ^ " " ^ config.author);
                 ];
             ];
         ])
  in
  Format.asprintf "%a" (pp ()) doc

(* Route and URL mapping types *)
type route = {
  url_path : string;
  file_path : string;
  content_type : content_type;
}

and content_type =
  | Page
  | BlogPost
  | Project
  | Journal
  | Asset

type route_metadata = {
  title : string option;
  (* Keeping these fields for future use *)
  _date : string option;
  _description : string option;
  _tags : string list;
}

let extract_route_metadata file_path =
  let _content = read_file file_path in
  (* TODO: Implement YAML frontmatter parsing *)
  { title = None; _date = None; _description = None; _tags = [] }

let process_route route =
  let output_path =
    match route.content_type with
    | Asset ->
        Filename.concat config.output_dir
          (String.sub route.url_path 1 (String.length route.url_path - 1))
    | _ ->
        if route.url_path = "/" then
          Filename.concat config.output_dir "index.html"
        else
          Filename.concat config.output_dir
            (String.sub route.url_path 1 (String.length route.url_path - 1)
            ^ "/index.html")
  in
  let metadata = extract_route_metadata route.file_path in
  let content = read_file route.file_path in
  match route.content_type with
  | Asset -> write_output_file ~content ~path:output_path
  | _ ->
      let html_content = _process_markdown content in
      let page =
        _render_page
          ~title:(Option.value metadata.title ~default:"Untitled")
          ~content:html_content
      in
      write_output_file ~content:page ~path:output_path

(* URL path mapping *)
let clean_url_path path =
  let path = Filename.remove_extension path in
  let path = if path = "index" then "/" else "/" ^ path in
  String.map
    (function
      | '\\' -> '/'
      | c -> c)
    path

let content_type_of_path path =
  match Filename.dirname path with
  | "content/blog" -> BlogPost
  | "content/projects" -> Project
  | "content/journal" -> Journal
  | "content/pages" -> Page
  | _ when Filename.extension path = "" -> Asset
  | _ -> Page

let collect_routes () =
  let routes = ref [] in
  let add_route ~url_path ~file_path ~content_type =
    routes := { url_path; file_path; content_type } :: !routes
  in
  let rec process_dir dir =
    if Sys.file_exists dir then
      Array.iter
        (fun entry ->
          let path = Filename.concat dir entry in
          if entry <> "." && entry <> ".." && entry <> "_site" then
            if Sys.is_directory path then process_dir path
            else
              let rel_path =
                let prefix_len = String.length config.content_dir + 1 in
                String.sub path prefix_len (String.length path - prefix_len)
              in
              let url_path = clean_url_path rel_path in
              let content_type = content_type_of_path path in
              add_route ~url_path ~file_path:path ~content_type)
        (Sys.readdir dir)
  in
  process_dir config.content_dir;
  List.rev !routes

(* Cache for incremental builds *)
type build_cache = {
  last_modified : (string * float) list;
  cache_file : string;
}

let load_build_cache () =
  let cache_file = Filename.concat config.output_dir ".build-cache" in
  try
    let content = read_file cache_file in
    let lines = String.split_on_char '\n' content in
    let last_modified =
      List.filter_map
        (fun line ->
          match String.split_on_char '|' line with
          | [ path; time ] -> Some (path, float_of_string time)
          | _ -> None)
        lines
    in
    { last_modified; cache_file }
  with _ -> { last_modified = []; cache_file }

let save_build_cache cache =
  let content =
    String.concat "\n"
      (List.map
         (fun (path, time) -> Printf.sprintf "%s|%f" path time)
         cache.last_modified)
  in
  write_file cache.cache_file content

let is_file_modified file_path cache =
  try
    let stat = Unix.stat file_path in
    match List.assoc_opt file_path cache.last_modified with
    | Some last_mtime -> stat.Unix.st_mtime > last_mtime
    | None -> true
  with Unix.Unix_error _ -> true

let update_cache_entry file_path cache =
  try
    let stat = Unix.stat file_path in
    let last_modified =
      (file_path, stat.Unix.st_mtime)
      :: List.filter (fun (p, _) -> p <> file_path) cache.last_modified
    in
    { cache with last_modified }
  with Unix.Unix_error _ -> cache

(* Generate site *)
let generate_site () =
  print_endline "Starting site generation...";

  (* Load build cache *)
  let cache = load_build_cache () in

  (* Ensure output directory exists *)
  ensure_directory_exists config.output_dir;

  (* Copy static assets *)
  copy_static_assets ();
  print_endline "Static assets copied.";

  (* Collect and process routes *)
  let routes = collect_routes () in
  Printf.printf "Collected %d routes\n" (List.length routes);

  (* Process each route *)
  let final_cache =
    List.fold_left
      (fun acc route ->
        if is_file_modified route.file_path acc then (
          Printf.printf "Processing modified route: %s -> %s\n" route.file_path
            route.url_path;
          process_route route;
          update_cache_entry route.file_path acc)
        else (
          Printf.printf "Skipping unmodified route: %s\n" route.file_path;
          acc))
      cache routes
  in

  (* Save updated cache *)
  save_build_cache final_cache;

  print_endline "Site generation complete!";
  ()

(* Entry point *)
let () =
  print_endline "Memoir Generation - OCaml Static Site Generator";
  try
    generate_site ();
    exit 0
  with e ->
    prerr_endline ("Error: " ^ Printexc.to_string e);
    exit 1
