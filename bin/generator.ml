(* Configuration type *)
type config_type = {
  site_title : string;
  site_description : string;
  author : string;
  base_url : string;
  output_dir : string;
  content_dir : string;
  template_dir : string;
  static_dir : string;
}

(* Configuration *)
let config =
  {
    site_title = "Here Lies My Thoughts and Convictions";
    site_description = "A modern portfolio and memoir website built with OCaml";
    author = "Chukwuma Akunyili";
    base_url = "https://aguluman.github.io/memoir/";
    output_dir = "_site";
    content_dir = "content";
    template_dir = "templates";
    static_dir = "static";
  }

(* File utilities *)
let ensure_directory_exists dir =
  if not (Sys.file_exists dir) then Sys.mkdir dir 0o755
  else if not (Sys.is_directory dir) then
    failwith (Printf.sprintf "%s exists but is not a directory" dir)

let read_file path =
  let ic = open_in path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

let write_file path content =
  ensure_directory_exists (Filename.dirname path);
  let oc = open_out path in
  output_string oc content;
  close_out oc

(* Process markdown content *)
let process_markdown content =
  let open Omd in
  let md = of_string content in
  to_html md

(* Copy static assets *)
let copy_static_assets () =
  let rec copy_dir src_dir dst_dir =
    ensure_directory_exists dst_dir;
    let entries = Sys.readdir src_dir in
    Array.iter
      (fun entry ->
        let src_path = Filename.concat src_dir entry in
        let dst_path = Filename.concat dst_dir entry in
        if Sys.is_directory src_path then copy_dir src_path dst_path
        else
          let content = read_file src_path in
          write_file dst_path content)
      entries
  in
  let src = config.static_dir in
  let dst = Filename.concat config.output_dir "static" in
  if Sys.file_exists src then copy_dir src dst

(* Render HTML page *)
let render_page ~title:_ ~content =  (* TODO: Use [title] when ready *)
  let open Tyxml.Html in
  let doc =
    html
      (head
        (title (txt "Thoughts and Tiny-Experiments"))         [
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

(* Generate site *)
let generate_site () =
  print_endline "Starting site generation...";
  (* Ensure output directory exists *)
  ensure_directory_exists config.output_dir;
  (* Copy static assets *)
  copy_static_assets ();
  print_endline "Static assets copied.";
  (* TODO: Process content files *)
  (* TODO: Generate index page *)
  (* TODO: Generate RSS feed *)
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
