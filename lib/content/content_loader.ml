(** File-based content loading.

    Single source of truth for enumerating content files and building the
    blog/journal listing entries injected into section index pages. Consumed by
    [bin/generator.ml]; the RSS-feed loader lives in {!Memoir_lib}. *)

(* Binary-safe read; closes the channel even on exception. *)
let read_file path = In_channel.with_open_bin path In_channel.input_all

(** Every file under [root], recursively, skipping the generated [_site] dir. *)
let walk_files root =
  let rec go dir acc =
    if Sys.file_exists dir && Sys.is_directory dir then
      Array.fold_left
        (fun acc entry ->
          if entry = "." || entry = ".." || entry = "_site" then acc
          else
            let path = Filename.concat dir entry in
            if Sys.is_directory path then go path acc else path :: acc)
        acc (Sys.readdir dir)
    else acc
  in
  List.rev (go root [])

(** Renderable markdown files directly in [dir]: ".md" files, excluding
    "index.md" and any subdirectories. *)
let list_markdown_files dir =
  if Sys.file_exists dir && Sys.is_directory dir then
    Sys.readdir dir |> Array.to_list
    |> List.filter (fun f ->
        Filename.extension f = ".md"
        && f <> "index.md"
        && not (Sys.is_directory (Filename.concat dir f)))
    |> List.map (Filename.concat dir)
  else []

(** A listing entry rendered onto blog/journal index pages. *)
type entry = {
  title : string;
  date : Content_types.Date.t option;
  description : string option;
  url : string;
}

(** Listing entries for the markdown files in [dir], each URL prefixed with
    [url_prefix], sorted newest-first (undated entries fall back to title).
    Titles missing from frontmatter fall back to the file's slug. *)
let list_entries ~dir ~url_prefix =
  list_markdown_files dir
  |> List.map (fun path ->
      let fm = Markdown_parser.frontmatter_of_content (read_file path) in
      let slug = Filename.remove_extension (Filename.basename path) in
      {
        title =
          (match fm.Content_types.title with
          | "" | "Untitled" -> slug
          | t -> t);
        date = fm.Content_types.date;
        description = fm.Content_types.description;
        url = url_prefix ^ slug;
      })
  |> List.sort (fun a b ->
      match (a.date, b.date) with
      | None, None -> String.compare a.title b.title
      | _ -> Content_types.Date.compare_opt_desc a.date b.date)
