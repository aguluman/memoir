let read_file path = In_channel.with_open_bin path In_channel.input_all

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

let list_markdown_files dir =
  if Sys.file_exists dir && Sys.is_directory dir then
    Sys.readdir dir |> Array.to_list
    |> List.filter (fun f ->
        Filename.extension f = ".md"
        && f <> "index.md"
        && not (Sys.is_directory (Filename.concat dir f)))
    |> List.map (Filename.concat dir)
  else []

type entry = {
  title : string;
  date : Content_types.Date.t option;
  description : string option;
  url : string;
}

let list_entries ~dir ~url_prefix =
  list_markdown_files dir
  |> List.map (fun path ->
      let fm = Markdown_parser.frontmatter_of_content (read_file path) in
      let slug = Filename.remove_extension (Filename.basename path) in

      {
        title =
          (match fm with
          | Some f when f.Content_types.title <> "Untitled" ->
              f.Content_types.title
          | _ -> slug);
        date =
          (match fm with
          | Some f -> f.Content_types.date
          | None -> None);
        description =
          (match fm with
          | Some f -> f.Content_types.description
          | None -> None);
        url = url_prefix ^ slug;
      })
  |> List.sort (fun a b ->
      match (a.date, b.date) with
      | None, None -> String.compare a.title b.title
      | _ -> Content_types.Date.compare_opt_desc a.date b.date)
