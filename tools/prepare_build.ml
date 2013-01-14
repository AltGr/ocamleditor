(*

  OCamlEditor
  Copyright (C) 2010-2012 Francesco Tovagliari

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


#cd "src"
#use "../tools/scripting.ml"

open Printf

let required_ocaml_version = "4.00.0"
let use_modified_gtkThread = ref false
let record_backtrace = ref true

let exe = if is_win32 then ".exe" else ""

let generate_oebuild_script () =
  run "ocaml -I common str.cma unix.cma common.cma generate_oebuild_script.ml";;

let test_rsvg () =
  let have_rsvg = Sys.command "ocamlfind query lablgtk2.rsvg" = 0 in
  if not have_rsvg then
    substitute ~filename:"ocamleditor_lib.ml" ~regexp:true
      ["[ ]+Dot_viewer.device := (module Dot_viewer_svg.SVG : Dot_viewer.DEVICE);",
        "  (\042Dot_viewer.device := (module Dot_viewer_svg.SVG : Dot_viewer.DEVICE);\042)"]
   else
    substitute ~filename:"ocamleditor_lib.ml" ~regexp:false
      ["  (\042Dot_viewer.device := (module Dot_viewer_svg.SVG : Dot_viewer.DEVICE);\042)",
        "  Dot_viewer.device := (module Dot_viewer_svg.SVG : Dot_viewer.DEVICE);"];;

let prepare_build () =
  if Sys.ocaml_version < required_ocaml_version then begin
    eprintf "You are using OCaml-%s but version %s is required." Sys.ocaml_version required_ocaml_version;
  end else begin
    cp ~echo:true (if !use_modified_gtkThread then "gtkThreadModified.ml" else "gtkThreadOriginal.ml") "gtkThread2.ml";
    if Sys.os_type = "Win32" then begin
      let pixmaps = ".." // "share" // "pixmaps" in
      let icons = [""] in
      let names = List.map (fun x -> "oe" ^ x ^ ".ico") icons in
      let filenames = List.map (fun x -> pixmaps // x) names in
      let finally () = List.iter remove_file names in
      try
        List.iter2 cp filenames names;
        run "rc resource.rc";
        run "cvtres /machine:x86 resource.res";
        finally()
      with Script_error _ -> finally()
    end;
    run "ocamllex err_lexer.mll";
    run "ocamlyacc err_parser.mly";
    test_rsvg();
    substitute ~filename:"oe_config.ml" ~regexp:true
      ["let _ = Printexc\\.record_backtrace \\(\\(true\\)\\|\\(false\\)\\)$",
       (sprintf "let _ = Printexc.record_backtrace %b" !record_backtrace)];
    try generate_oebuild_script() with Failure msg -> raise (Script_error 2)
  end;;

let _ = main ~default_target:prepare_build ~targets:[
  "-generate-oebuild-script", generate_oebuild_script, " (undocumented)";
]~options:[
  "-record-backtrace",       Bool (fun x -> record_backtrace := x), " Turn recording of exception backtraces on or off";
  "-use-modified-gtkThread", Set use_modified_gtkThread, " Set this flag if you have Lablgtk-2.14.2 or earlier
                            for using the included modified version of gtkThread.ml
                            to reduce CPU consumption";
] ()
