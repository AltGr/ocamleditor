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


#cd "tools"
#use "scripting.ml"

open Printf

let prefix   = ref "/usr/local"
let ext      = if is_win32 then ".exe" else ""
let gmisclib = ref false
let nsis     = ref false

let install () =
  if !gmisclib then begin
    let libname = "gmisclib" in
    let cmas = ["../" ^ libname] in
    let ar = String.concat " " (List.map (fun x -> x ^ (if Sys.os_type = "Win32" then ".lib" else ".a")) cmas) in
    let find ext =
      let files = Array.to_list (Sys.readdir ".") in
      let files = List.filter (fun x -> Filename.check_suffix x ext) files in
      String.concat " " files
    in
    let cmas = List.map (fun x -> [x ^ ".cma"; x ^ ".cmxa"]) cmas in
    let cmas = String.concat " " (List.flatten cmas) in
    (*  *)
    pushd libname;
    ignore (kprintf Sys.command "ocamlfind remove %s" libname);
    ignore (kprintf Sys.command "ocamlfind install %s META %s %s %s %s" libname cmas ar (find ".cmi") (find ".mli"));
    popd();
  end else if !nsis then begin
    let exit_code = kprintf Sys.command "\"%s\" ..\\ocamleditor.nsi" (Filename.quote "%ProgramFiles(x86)%\\NSIS\\makensis") in
    match exit_code with
      | 0 ->
        let version = match get_lines_from_file ~filename:"../VERSION" [1] with (_, x) :: [] -> x | _ -> assert false in
        let cmd = sprintf "..\\ocamleditor-%s" version in
        ignore (Sys.command cmd)
      | _ -> prerr_endline "This script is not available under Windows.
To install OCamlEditor, please use the included ocamleditor.nsi script.
You will need the free NSIS install system (http://nsis.sourceforge.net).";
  end else begin
    let exe = if Sys.os_type = "Win32" then ".exe" else "" in
    let icons = sprintf "%s/share/ocamleditor/icons" !prefix in
    mkdir_p icons;
    kprintf run "cp -vru ../icons/* %s" icons;
    if Sys.readdir "../plugins" <> [||] then begin
      let plugins = sprintf "%s/share/ocamleditor/plugins" !prefix in
      mkdir_p plugins;
      kprintf run "cp -vru ../plugins/* %s" plugins
    end;
    let bin = sprintf "%s/bin" !prefix in
    mkdir_p bin;
    let filename = if Sys.file_exists ("ocamleditor.opt" ^ exe) then ("ocamleditor.opt" ^ exe) else ("ocamleditor" ^ exe) in
    kprintf run "cp -v %s %s/ocamleditor%s" filename bin exe;
    let filename = if Sys.file_exists ("oebuild/oebuild.opt" ^ exe) then ("oebuild/oebuild.opt" ^ exe) else ("oebuild/oebuild" ^ exe) in
    kprintf run "cp -v %s %s" filename bin;
  end;;

let _ = main ~dir:"../src" ~default_target:install ~options:[
  "-prefix",   Set_string prefix,   (sprintf " Installation prefix (Unix only, default is %s)" !prefix);
  "-gmisclib", Set gmisclib,        (sprintf " Install gmisclib");
  "-nsis",     Set nsis,            (sprintf " Create a Win32 installer with NSIS");
] ()
