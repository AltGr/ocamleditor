(*

  OCamlEditor
  Copyright (C) 2010-2013 Francesco Tovagliari

  This file is part of OCamlEditor.

  OCamlEditor is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  OCamlEditor is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.

*)

open Printf
open Miscellanea

let re_tmp = Miscellanea.regexp (sprintf "File \"..[\\/]%s[\\/]" Project.tmp)
let (!!) = Filename.quote

(** replace_output_file *)
let replace_output_file project tmp rel_filename ext =
  let rel_file_ext = rel_filename ^ ext in
  let tmp_ext = tmp // rel_file_ext in
  if Sys.file_exists tmp_ext then begin
    let src_ext = (Project.path_src project) // rel_file_ext in
    try
      if Sys.file_exists src_ext then (Sys.remove src_ext);
      Sys.rename tmp_ext src_ext (* TODO: Sys_error("Permission denied") *)
    with Sys_error _ as ex ->
      Printf.eprintf "File \"autocomp.ml\": %s\n%s\n%!" (Printexc.to_string ex) (Printexc.get_backtrace());
  end

(** compile_buffer *)
let compile_buffer ~project ~editor ~page ?(join=false) () =
  (*Prf.crono Prf.prf_compile_buffer (fun () ->*)
  let activity_name = "Compiling " ^ page#get_filename ^ "..." in
  Activity.add Activity.Compile_buffer activity_name;
  let filename = page#get_filename in
  try
    match page#buffer#save_buffer() with
      | _, None -> ()
      | _, Some (tmp, relpath) ->
        (* Compile *)
        let command = sprintf "%s %s -I ../%s %s ../%s/%s %s"
          project.Prj.autocomp_compiler
          project.Prj.autocomp_cflags
          Project.tmp
          (Project.get_search_path_i_format project)
          Project.tmp
          relpath
          (if App_config.application_debug then redirect_stderr else "")
        in
        let compiler_output = Buffer.create 101 in
        let process_err ~stderr =
          let line = input_line stderr in
          let line = Str.replace_first re_tmp "File \"" line in
          Buffer.add_string compiler_output (Miscellanea.rtrim line);
          Buffer.add_char compiler_output '\n';
        in
        let at_exit () =
          (* Replace output files and update the table of compilation times of oebuild *)
          let rel_filename = match project.Prj.in_source_path filename with
            | Some x -> Filename.chop_extension x | _ -> assert false
          in
          replace_output_file project tmp rel_filename ".annot";
          replace_output_file project tmp rel_filename ".cmi";
    (*      if false && commit && exit_code = 0 then begin
            let current_time = (Unix.time () +. 1.) in
            replace_output_file project basename ".cmo";
            let oebuild_times = Oebuild.read_cache () in
            Hashtbl.remove oebuild_times basename;
            Hashtbl.add oebuild_times basename (current_time(*, false*));
            Oebuild.write_cache oebuild_times;
          end;*)
          let errors = Error.parse_string (Buffer.contents compiler_output) in
          GtkThread2.async page#error_indication#apply_tag errors;
          (** Outline *)
          let no_errors = errors.Oe.er_errors = [] in
          if editor#show_outline then begin
            Gmisclib.Idle.add ~prio:100 begin fun () ->
              match page#outline with
                | None ->
                  let ol = new Cmt_view.widget ~editor ~page () in
                  ol#load ();
                  Gaux.may page#outline ~f:(fun x -> x#destroy());
                  page#set_outline (Some ol);
                  editor#with_current_page begin fun current_page ->
                    if current_page#get_oid = page#get_oid then (editor#pack_outline ol#coerce)
                  end;
                | Some ol ->
                  (*if no_errors then (Timeout.set tout (fun () -> ol#parse ?force:None ())) (*else (ol#add_markers ~kind:`Error ())*);*)
                  if no_errors then (*(Timeout.set tout (fun () ->*) ol#load ()(* )) *) (*else (ol#add_markers ~kind:`Error ())*);
            end
          end;
          Activity.remove activity_name;
        in
        let exit_code = Oebuild_util.exec ~verbose:App_config.application_debug ~join (*false*) ~at_exit ~process_err command in
        ()
    (*end ()*)
  with ex -> begin
    eprintf "%s\n%s\n%!" (Printexc.to_string ex) (Printexc.get_backtrace ());
    ()
  end (* ) () *)















