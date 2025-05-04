(** Path resolution and routing system *)

open Base
open Content_types

(** Convert content path to URL path *)
let path_to_url_path content_path =
  let base_path = Stdlib.Filename.remove_extension content_path in
  let normalized =
    if String.equal base_path "index" then "/" else "/" ^ base_path
  in
  normalized

(** Convert content path to output file path *)
let path_to_output_path content_path ~output_dir =
  let base_path = Stdlib.Filename.remove_extension content_path in
  let html_file =
    if String.equal (Stdlib.Filename.basename base_path) "index" then
      base_path ^ ".html"
    else Stdlib.Filename.concat base_path "index.html"
  in
  Stdlib.Filename.concat output_dir html_file

(** Create a route for a content page *)
let create_route page ~output_dir =
  let content_type =
    let dir = Stdlib.Filename.dirname page.path in
    if String.is_prefix dir ~prefix:"blog" then Post
    else if String.is_prefix dir ~prefix:"projects" then Project
    else Page
  in

  let output_path = path_to_output_path page.path ~output_dir in

  {
    source_path = page.path;
    output_path;
    url_path = page.url_path;
    content_type;
  }

(** Generate routes for all content pages *)
let generate_routes pages ~output_dir =
  List.map pages ~f:(fun page -> create_route page ~output_dir)

(** Ensure output directory exists for a route *)
let ensure_output_directory route =
  let dir = Stdlib.Filename.dirname route.output_path in
  try
    let _ = Core_unix.mkdir_p dir in
    Ok ()
  with _ -> Error (Printf.sprintf "Failed to create directory: %s" dir)

(** Find a route by URL path *)
let find_route_by_url_path routes url_path =
  List.find routes ~f:(fun route -> String.equal route.url_path url_path)

(** Create a sitemap of all routes *)
let create_sitemap routes ~base_url =
  List.map routes ~f:(fun route ->
      Printf.sprintf "%s%s" base_url route.url_path)
