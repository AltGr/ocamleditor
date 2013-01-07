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


open Miscellanea
open Printf

let filename = "oebuild_script.ml"

module Comments = struct
  let pat = regexp "\\((\\*\\)\\|\\(\\*)\\)"
  let lineend = regexp "$"
  let search_f_pat = Str.search_forward pat

  let scan_locale txt =
    (* Non vengono considerate le stringhe *)
    let rec f acc pos start =
      begin
        try
          let p = search_f_pat txt pos in
          begin
            try
              ignore (Str.matched_group 1 txt);
              f acc (p + 2) (p :: start);
            with Not_found -> begin
              ignore (Str.matched_group 2 txt);
              (match start with
                | [] -> f acc (p + 2) []
                | [start] -> f ((start, (p + 2), (txt.[start + 2] = '*')) :: acc) (p + 2) []
                | _::prev -> f acc (p + 2) prev)
            end
          end
        with Not_found -> acc
      end
    in
   List.rev (f [] 0 [])

  let scan txt = scan_locale txt
end

module Util = struct
  let join_lines =
    let re = Str.regexp "[\r\n]+ *" in
    fun buf ->
      let comments = Comments.scan buf in
      List.iter begin fun (b, e, _) ->
        let len = e - b in
        String.blit (String.make len ' ') 0 buf b len
      end comments;
      let buf = Str.global_replace re " " buf in
      buf;;

  let header = ref ""

  let replace_header buf =
    let header_re = Str.regexp_string !header in
    Str.replace_first header_re "" (Buffer.contents buf)

  let test () =
    let cmd = sprintf "ocaml %s" filename in
    Printf.printf "Testing %s...\n  %s\n%!" filename cmd;
    let exit_code = Sys.command cmd in
    if exit_code > 0 then failwith "Test failed"
end

let create_script () =
  let ochan = open_out_bin filename in
  let finally () = close_out_noerr ochan in
  try
    output_string ochan "#directory \"+threads\" ";
    output_string ochan "#load \"str.cma\" ";
    output_string ochan "#load \"unix.cma\" ";
    output_string ochan "#load \"threads.cma\"\n";
    output_string ochan "let split re = Str.split (Str.regexp re)\n";
    let modules = [
      "../common/quote";
      "../common/argc";
      "../common/cmd";
      "../common/app_config";
      "../common/ocaml_config";
      "../common/dep";
      "../common/cmd_line_args";
      "../task";
      "../build_script_command";
      "oebuild_util";
      "oebuild_table";
      "oebuild";
      "../build_script_util";
    ] in
    List.iter begin fun name ->
      let buf = Util.replace_header (File.read (name ^ ".ml")) in
      let buf = Util.join_lines buf in
      let name = Filename.basename name in
      fprintf ochan "module %s = struct " (String.capitalize name);
      output_string ochan buf;
      output_string ochan "end\n";
    end modules;
    output_string ochan "\nopen Oebuild\nopen Build_script_util\n";
    finally();
    Util.test();
  with ex -> (finally(); raise ex);;

let code_of_script () =
  let buf = File.read filename in
  let ochan = open_out_bin filename in
  let finally () = close_out_noerr ochan in
  try
    output_string ochan !Util.header;
    kprintf (output_string ochan) "let code = %S" (Buffer.contents buf);
    finally();
  with ex -> (finally());;

let _ =
  pushd "oebuild";
  Util.header := Buffer.contents (File.read (".."//".."//"header"));
  create_script ();
  code_of_script();
  let new_filename = ".."//filename in
  if Sys.file_exists new_filename then (Sys.remove new_filename);
  Sys.rename filename new_filename;
  popd ()










