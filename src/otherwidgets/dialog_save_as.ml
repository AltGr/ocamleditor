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

(** write_file *)
let write_file ~editor ~page ~text ~filename window =
  File_util.write filename text;
  page#revert();
  (*editor#close page;*)
  match editor#open_file ~active:true ~scroll_offset:0 ~offset:0 ?remote:None filename with
    | Some page ->
      editor#load_page ?scroll:None page;
      editor#goto_view page#view;
      window#destroy()
    | _ ->
      Dialog.info ~title:"Error" ~message_type:`ERROR
        ~message:(sprintf "Cannot open file %s" filename) window

(** window *)
let window ~editor ~page () =
  let window = GWindow.file_chooser_dialog
    ~action:`SAVE ~icon:Icons.oe
    ~title:(sprintf "Save \xC2\xAB%s\xC2\xBB as..." (Filename.basename page#get_filename))
    ~position:`CENTER ~modal:true ~show:false ()
  in
  window#set_select_multiple false;
  window#add_select_button_stock `OK `OK;
  window#add_button_stock `CANCEL `CANCEL;
  window#set_default_response `OK;
  ignore (window#set_filename page#get_filename);
  let rec run () =
    match window#run () with
      | `OK ->
        Gaux.may window#filename ~f:begin fun filename ->
          let buffer : GText.buffer = page#buffer#as_text_buffer#as_gtext_buffer in
          let write () =
            write_file ~editor ~page ~text:(buffer#get_text()) ~filename window
          in
          if Sys.file_exists filename then begin
            let overwrite () =
              if Sys.os_type = "Win32" then begin
                (* Because of the Win32 case insensitiveness of filenames
                   we delete the target file and close the editor page of
                   the target file *)
                Sys.remove filename;
                let lc_filename = String.lowercase filename in
                List_opt.may_find (fun p -> String.lowercase p#get_filename = lc_filename)
                  editor#pages editor#close ();
              end;
              write()
            in
            Dialog_rename.ask_overwrite ~run ~overwrite ~filename window
          end else (write())
        end;
      | _ -> window#destroy()
  in run()





