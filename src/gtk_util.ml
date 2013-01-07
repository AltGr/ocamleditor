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


let _ = Gtk_theme.set_theme()
let _ = Gmisclib.Util.fade_window_enabled := Oe_config.fade_window_enabled

let create_mark_name =
  let count = ref 0 in fun prefix ->
    incr count;
    prefix ^ (string_of_int !count);;

let esc_destroy_window window =
  ignore (window#event#connect#key_press ~callback:begin fun ev ->
    let key = GdkEvent.Key.keyval ev in
    if key = GdkKeysyms._Escape then (window#destroy(); true) else false
  end);;

(** window *)
let window widget ?parent ?(destroy_child=true) ?(fade=false) ?(focus=true) ?(escape=true) ?(show=true) ~x ~y () =
  let window = GWindow.window
    ~decorated:false
    ~border_width:1
    ~deletable:true
    ~focus_on_map:focus
    ~type_hint:(if Sys.os_type = "Win32" then `UTILITY else `DIALOG)
    ~show:false ()
  in
  let ebox = GBin.event_box ~packing:window#add () in
  ebox#add widget;
  let color = Color.set_value 0.62 (`NAME Preferences.preferences#get.Preferences.pref_bg_color_popup) in
  let _ = window#misc#modify_bg [`NORMAL, color] in
  let _ = ebox#misc#modify_bg [`NORMAL, `NAME Preferences.preferences#get.Preferences.pref_bg_color_popup] in
  ignore (window#event#connect#after#focus_out ~callback:begin fun _ ->
    if not destroy_child then (ebox#remove widget);
    window#destroy();
    true
  end);
  if escape then esc_destroy_window window;
  window#set_skip_pager_hint true;
  window#set_skip_taskbar_hint true;
  Gaux.may parent ~f:(fun parent -> Gaux.may (GWindow.toplevel parent) ~f:(fun x -> window#set_transient_for x#as_window));
  window#set_accept_focus focus;
  if show then begin
    if fade then (window#set_opacity 0.0);
    if Sys.os_type = "Win32" then (window#present());
    window#move ~x ~y;
    let alloc = window#misc#allocation in
    let x, y =
      (if x + alloc.Gtk.width > (Gdk.Screen.width()) then (Gdk.Screen.width() - alloc.Gtk.width) else x),
      (if y + alloc.Gtk.height > (Gdk.Screen.height()) then (Gdk.Screen.height() - alloc.Gtk.height) else y);
    in
    window#move ~x ~y;
    if fade then (Gmisclib.Util.fade_window window);
    if Sys.os_type <> "Win32" then (window#present());
  end;
  window

(** window_tooltip *)
let window_tooltip widget ?parent ?(fade=false) ~x ~y () =
  let window = GWindow.window
    ~decorated:false
    ~kind:(if Sys.os_type = "Win32" then `POPUP else `TOPLEVEL)
    ~type_hint:(if Sys.os_type = "Win32" then `MENU else `NORMAL)
    ~border_width:1
    ~show:false ()
  in
  let ebox = GBin.event_box ~packing:window#add () in
  ebox#add widget;
  let color = Color.set_value 0.62 (`NAME Preferences.preferences#get.Preferences.pref_bg_color_popup) in
  let _ = window#misc#modify_bg [`NORMAL, color] in
  let _ = ebox#misc#modify_bg [`NORMAL, `NAME Preferences.preferences#get.Preferences.pref_bg_color_popup] in
  window#set_skip_pager_hint true;
  window#set_skip_taskbar_hint true;
  window#set_accept_focus false;
  window#misc#set_can_focus false;
  window#set_focus_on_map false;
  Gaux.may parent ~f:(fun parent -> Gaux.may (GWindow.toplevel parent) ~f:(fun x -> window#set_transient_for x#as_window));
  if fade then (window#set_opacity 0.0);
  window#move ~x ~y;
  if fade then (Gmisclib.Util.fade_window window);
  if Sys.os_type <> "Win32" then (window#present());
  let alloc = window#misc#allocation in
  let x, y =
    (if x + alloc.Gtk.width > (Gdk.Screen.width()) then (Gdk.Screen.width() - alloc.Gtk.width) else x),
    (if y + alloc.Gtk.height > (Gdk.Screen.height()) then (Gdk.Screen.height() - alloc.Gtk.height) else y);
  in
  window#move ~x ~y;
  window

(** with_tag *)
let with_tag ~(buffer : GText.buffer) tag f =
  let m1 = buffer#create_mark(* ~name:(create_mark_name "Gtk_util.with_tag")*) (buffer#get_iter `INSERT) in
  f ();
  buffer#apply_tag tag ~start:(buffer#get_iter_at_mark (`MARK m1)) ~stop:(buffer#get_iter `INSERT);
  buffer#delete_mark (`MARK m1);;











