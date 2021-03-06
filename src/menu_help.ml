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

let about editor () =
  let dialog = GWindow.about_dialog
      ~type_hint:(if Sys.os_type = "Win32" then `SPLASHSCREEN else `DIALOG)
      ~modal:true
      ~width:300
      ~position:`CENTER
      ~icon:Icons.oe
      ~name:About.program_name
      ~version:About.version
      ~copyright:About.copyright
      ~logo:Icons.logo
      ~license:"OCamlEditor is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OCamlEditor is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>."
      ~show:false
      ()
  in
  (*dialog#misc#modify_bg [`NORMAL, `WHITE];*)
  dialog#set_skip_taskbar_hint true;
  dialog#set_skip_pager_hint true;
  Gaux.may (GWindow.toplevel editor) ~f:(fun x -> dialog#set_transient_for x#as_window);
  let vbox = dialog#vbox in
  let align = GBin.alignment ~xalign:0.5 ~packing:vbox#add ~show:false () in
  let hbox = GPack.hbox ~spacing:3 ~packing:align#add () in
  let spinner = GMisc.image ~file:(App_config.application_icons // "spinner_16.gif") ~packing:hbox#pack () in
  let label = GMisc.label ~text:"Checking for updates..." ~height:22 ~packing:hbox#pack () in
  let modify_label label =
    label#misc#modify_fg [`NORMAL, `NAME "#808080"];
    label#misc#modify_font_by_name "Sans 7";
  in
  modify_label label;
  let check_for_updates () =
    try
      spinner#set_stock `DIALOG_INFO;
      spinner#set_icon_size `MENU;
      if try int_of_string (List.assoc "debug" App_config.application_param) >= 1 with Not_found -> false then (raise Exit);
      begin
        match Check_for_updates.check About.version () with
        | Some ver ->
          label#misc#hide();
          let text = sprintf "A new version of %s is available (%s)" About.program_name ver in
          let button = GButton.button ~packing:vbox#pack () in
          let label = GMisc.label ~text ~packing:button#add () in
          modify_label label;
          button#set_relief `NONE;
          ignore (button#connect#clicked ~callback:begin fun () ->
              dialog#misc#hide();
              let url = Check_for_updates.url in
              let cmd = if Sys.os_type = "Win32" then "start " ^ url else "xdg-open " ^ url in
              ignore (GMain.Idle.add (fun () -> ignore (Sys.command cmd); false));
              dialog#destroy();
            end);
        | None -> label#set_text "There are no updates available."
      end;
    with ex -> begin
        kprintf label#set_text "Unable to contact server for updates (%s)." (Printexc.to_string ex);
        spinner#set_pixbuf Icons.warning_14;
        (*spinner#misc#hide()*)
      end
  in
  ignore (dialog#misc#connect#show ~callback:begin fun () ->
      let count = ref 0in
      ignore (GMain.Timeout.add ~ms:600 ~callback:begin fun () ->
          if !count = 1 then begin
            align#misc#show();
            (*ehbox#misc#show();*)
          end else if !count = 2 then (check_for_updates());
          incr count;
          true
        end)
    end);
  match dialog#run() with _ -> dialog#destroy()
