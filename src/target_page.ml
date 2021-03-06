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
open Target
open GUtil
open Miscellanea

let mk_target_filenames project filenames =
  let filenames = Miscellanea.Xlist.filter_map project.Prj.in_source_path filenames in
  if Oe_config.is_win32 then begin
    List.map begin fun filename ->
      Miscellanea.filename_unix_implicit filename
    end filenames
  end else filenames

class view ~project ?packing () =
  let changed = new changed () in
  let xalign = 0.0 in
  let indent = 21 in
  let mainbox = GPack.vbox ~spacing:8 ?packing () in
  let entry_name = GEdit.entry ~packing:mainbox#pack () in
  let nb = GPack.notebook ~packing:mainbox#add () in

  (** Target Tab *)
  let vbox = GPack.vbox ~border_width:5 ~spacing:13 () in
  let _ = nb#append_page ~tab_label:(GMisc.label ~text:"Target Type" ())#coerce vbox#coerce in
  (** Library *)
  (* Build a library with the specified toplevel modules *)
  let mbox = GPack.vbox ~spacing:0 ~packing:(vbox#pack ~expand:false) () in
  let radio_archive = GButton.radio_button ~packing:mbox#add () in
  let label_radio_archive = GMisc.label ~markup:"Archive" () in
  let _ = radio_archive#add label_radio_archive#coerce in

  let align_lib = GBin.alignment ~padding:(0,0,indent,0) ~packing:mbox#add () in
  let lbox = GPack.vbox ~spacing:8 ~packing:align_lib#add () in

  (** Output kind *)
  let combo_kind, _ = GEdit.combo_box_text
    ~strings:["Library (-a)"; "Plugin (-shared)"; "Pack (-pack)"]
    (*~active:0*) ~packing:lbox#add () in
  (** Toplevel modules list *)
  let box = GPack.vbox ~packing:lbox#pack () in
  let _ = GMisc.label ~markup:"Toplevel modules" ~xalign:0.0 ~packing:box#pack () in

  let hbox = GPack.hbox ~spacing:3 ~packing:box#pack () in
  let entry_lib_modules = GEdit.entry ~editable:true ~packing:hbox#add () in
  let button_lib_modules = GButton.button ~label:"  ...  " ~packing:(hbox#pack ~expand:false) () in
  let _ = button_lib_modules#connect#clicked ~callback:begin fun () ->
    let chooser = GWindow.file_chooser_dialog ~title:"Choose the toplevel modules for the library..."
      ~action:`OPEN ~position:`CENTER ~show:false () in
    chooser#add_select_button_stock `OK `OK;
    chooser#add_button_stock `CANCEL `CANCEL;
    chooser#set_select_multiple true;
    chooser#set_filter (GFile.filter ~patterns:["*.ml"] ());
    chooser#add_filter (GFile.filter ~patterns:["*.ml"] ());
    match chooser#run () with
      | `OK ->
        let filenames = mk_target_filenames project chooser#get_filenames in
        entry_lib_modules#set_text (String.concat " " filenames);
        chooser#destroy()
      | _ -> chooser#destroy()
  end in
  (** Install path for library *)
  let box = GPack.vbox ~packing:lbox#pack () in
  let ocamllib = project.Prj.ocamllib in
  let markup = sprintf "Installation path, relative to the standard library directory (<small><tt>%s</tt></small>) " ocamllib in
  let _ = GMisc.label ~markup ~xalign:0.0 ~packing:box#pack () in
  let hbox = GPack.hbox ~spacing:3 ~packing:box#pack () in
  let entry_lib_install = GEdit.entry ~editable:true ~packing:hbox#add () in
  let button_lib_install = GButton.button ~label:"  ...  " ~packing:hbox#pack () in
  let _ = button_lib_install#misc#set_sensitive false in
(*  let _ = button_lib_install#connect#clicked ~callback:begin fun () ->
    let chooser = GWindow.file_chooser_dialog ~title:"Install path for the library"
      ~action:`SELECT_FOLDER ~position:`CENTER ~show:false () in
    chooser#add_select_button_stock `OK `OK;
    chooser#add_button_stock `CANCEL `CANCEL;
    chooser#set_select_multiple false;
    chooser#set_current_folder Oe_config.ocamllib;
    match chooser#run () with
      | `OK ->
        entry_lib_install#set_text (try List.hd chooser#get_filenames with Failure "hd" -> "");
        chooser#destroy()
      | _ -> chooser#destroy()
  end in*)
  (** Executable *)
  let mbox = GPack.vbox ~spacing:0 ~packing:(vbox#pack ~expand:false) () in
  let lmbox = GPack.hbox ~spacing:0 ~packing:mbox#pack () in
  let radio_executable = GButton.radio_button ~group:radio_archive#group ~packing:lmbox#pack () in
  let label_radio_executable = GMisc.label ~xalign:0.0 ~markup:"Executable." () in
  let _ = radio_executable#add label_radio_executable#coerce in
  let _ = GMisc.label ~xalign:0.0 ~markup:" Main module: " ~packing:lmbox#add () in
  let align_exec = GBin.alignment ~padding:(0,0,21,0) ~packing:mbox#add () in
  let box = GPack.vbox ~spacing:8 ~packing:align_exec#add () in
  let hbox = GPack.hbox ~spacing:3 ~packing:(box#pack ~expand:false) () in
  let entry_main_module = GEdit.entry ~editable:false ~packing:hbox#add () in
  let button_main_module = GButton.button ~label:"  ...  " ~packing:(hbox#pack ~expand:false) () in
  let _ = button_main_module#connect#clicked ~callback:begin fun () ->
    let chooser = GWindow.file_chooser_dialog ~title:"Choose the main module..."
      ~action:`OPEN ~position:`CENTER ~show:false () in
    chooser#add_select_button_stock `OK `OK;
    chooser#add_button_stock `CANCEL `CANCEL;
    chooser#set_select_multiple false;
    chooser#set_filter (GFile.filter ~patterns:["*.ml"] ());
    match chooser#run () with
      | `OK ->
        begin
          try
            let filename = List.hd (mk_target_filenames project chooser#get_filenames) in
            entry_main_module#set_text filename;
          with Failure "hd" -> ()
        end;
        chooser#destroy()
      | _ -> chooser#destroy()
  end in
  (** Radio External *)
  let mbox = GPack.vbox ~spacing:0 ~packing:(vbox#pack ~expand:false) () in
  let radio_external = GButton.radio_button ~group:radio_archive#group ~packing:mbox#add () in
  let label_radio_external = GMisc.label ~markup:"External tasks" () in
  let _ = radio_external#add label_radio_external#coerce in
  (** Outname *)
  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) () in
  let _ = GMisc.label ~markup:"Output file name <small><tt>(-o)</tt></small>" ~xalign ~packing:box#add () in
  let entry_outname = GEdit.entry ~packing:box#add () in

  (** Build Settings Tab *)
  let vbox = GPack.vbox ~width:640 ~border_width:5 ~spacing:13 () in
  let _ = nb#append_page ~tab_label:(GMisc.label ~text:"Build Settings" ())#coerce vbox#coerce in

  let box = GPack.hbox ~spacing:0 ~packing:vbox#pack () in
  let _ = GMisc.label ~text:"Compilation: " ~xalign:0.0 ~packing:box#pack () in
  let combo_comp, _ = GEdit.combo_box_text
    ~strings:["Bytecode"; "Native-code"; "Bytecode and native"]
    ~active:0 ~packing:box#add () in

  let check_inline = GButton.check_button ~label:"-inline: " ~packing:box#pack () in
  let adjustment_inline = GData.adjustment ~lower:0.0 ~upper:1000. ~page_size:0.0 () in
  let entry_inline = GEdit.spin_button ~adjustment:adjustment_inline ~rate:1.0 ~digits:0 ~numeric:true ~packing:box#pack () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) ~show:true () in
  let _ = GMisc.label ~markup:"Findlib packages <small><tt>(-package)</tt></small>" ~xalign ~packing:box#add () in
  let flbox = GPack.hbox ~spacing:3 ~packing:box#pack () in
  let entry_package = GEdit.entry ~packing:flbox#add () in
  let button_package = GButton.button ~label:"  ...  " ~packing:flbox#pack () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) () in
  let _ = GMisc.label ~markup:"Search path <small><tt>(-I)</tt></small>" ~xalign ~packing:box#add () in
  let entry_includes = GEdit.entry ~packing:box#add () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) () in
  let _ = GMisc.label ~markup:"Required libraries <small><tt>(-l)</tt></small>" ~xalign ~packing:box#add () in
  let entry_libs = GEdit.entry ~packing:box#add () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) ~show:false () in
  let _ = GMisc.label ~markup:"Other required object files <small><tt>(-m)</tt></small>" ~xalign ~packing:box#add () in
  let entry_mods = GEdit.entry ~packing:box#add () in

  let box = GPack.hbox ~packing:vbox#pack () in
  let check_thread = GButton.check_button ~label:"-thread" ~packing:box#add () in
  let check_vmthread = GButton.check_button ~label:"-vmthread" ~packing:box#add () in

  let box = GPack.vbox ~packing:vbox#pack () in
  let _ = GMisc.label ~markup:"Preprocessor <small><tt>(-pp)</tt></small>" ~xalign ~packing:box#add () in
  let entry_pp = GEdit.entry ~packing:box#add () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) () in
  let _ = GMisc.label ~text:"Compiler flags" ~xalign ~packing:box#add () in
  let entry_cflags = GEdit.entry ~packing:box#add () in

  let box = GPack.vbox ~packing:(vbox#pack ~expand:false) () in
  let _ = GMisc.label ~text:"Linker flags" ~xalign ~packing:box#add () in
  let entry_lflags = GEdit.entry ~packing:box#add () in

  let expander_more_settings = GBin.expander ~expanded:false ~label:"More Settings" ~packing:vbox#pack () in
  let more_vbox = GPack.vbox ~packing:expander_more_settings#add () in
  let check_nodep = GButton.check_button ~packing:more_vbox#pack () in
  let _ = check_nodep#add (GMisc.label ~markup:"Do not detect module dependencies (<tt>-no-dep</tt>)" ())#coerce in

  let check_dontlinkdep = GButton.check_button ~packing:more_vbox#pack () in
  let _ = check_dontlinkdep#add (GMisc.label ~markup:"Do not link module dependencies (<tt>-dont-link-dep</tt>)" ())#coerce in
  let _ = check_nodep#connect#toggled ~callback:begin fun () ->
    check_dontlinkdep#misc#set_sensitive (not check_nodep#active)
  end in

  (** Dependencies Tab *)
  let vbox = GPack.vbox ~border_width:5 ~spacing:8 () in
  let _ = nb#append_page ~tab_label:(GMisc.label ~text:"Target Dependencies" ())#coerce vbox#coerce in
  let widget_deps = Target_page_deps.create ~project ~packing:vbox#add () in

  (** Restrictions Tab *)
  let vbox = GPack.vbox ~width:550 ~border_width:5 ~spacing:8 () in
  let _ = nb#append_page ~tab_label:(GMisc.label ~text:"Conditions" ())#coerce vbox#coerce in
  let _ = GMisc.label ~xalign:0.0 ~line_wrap:true ~justify:`LEFT ~width:550
    ~text:"Specify the conditions that determine whether commands on this build \
configuration should run. The selected conditions will be verified at \
any attempt to perform a \"Clean\" or \"Build\" or any other external task, from \
both within the IDE and from the generated build script." ~packing:vbox#pack () in
  let align = GBin.alignment ~padding:(0,0,indent,0) ~packing:vbox#add () in
  let cbox = GPack.vbox ~spacing:3 ~packing:align#add () in
  let flbox = GPack.hbox ~spacing:5 ~packing:cbox#pack () in
  let check_fl_pkg = GButton.check_button ~label:"The following Findlib packages are installed:" ~packing:flbox#pack () in
  let entry_fl_pkg = GEdit.entry ~packing:flbox#add () in
  let _ = check_fl_pkg#connect#toggled ~callback:begin fun () ->
    entry_fl_pkg#misc#set_sensitive check_fl_pkg#active;
    if check_fl_pkg#active then entry_fl_pkg#misc#grab_focus()
  end; in
  let _ = entry_fl_pkg#misc#set_sensitive false in
  let check_unix = GButton.check_button ~label:"O.S. type is Unix" ~packing:cbox#pack () in
  let check_win32 = GButton.check_button ~label:"O.S. type is Win32" ~packing:cbox#pack () in
  let check_cygwin = GButton.check_button ~label:"O.S. type is Cygwin" ~packing:cbox#pack () in
  let check_native = GButton.check_button ~label:"Native compilation is supported" ~packing:cbox#pack () in

  (*  *)
  let cmd_line = GEdit.entry ~editable:false () in
object (self)
  inherit GObj.widget mainbox#as_widget
  val mutable target = None
  val mutable signals_enabled = true
  val mutable page_changed = false

  initializer
    (*  *)
    button_package#set_focus_on_click false;
    ignore (button_package#connect#clicked ~callback:begin fun () ->
      let widget, window = Findlib_list.dialog flbox#coerce () in
      Gaux.may target ~f:(fun tg -> widget#select_packages (Str.split (Miscellanea.regexp ", *") tg.package));
      window#(*set_on_popdown*)connect#destroy begin fun () ->
        entry_package#misc#grab_focus ();
        entry_package#set_position (Glib.Utf8.length entry_package#text);
      end;
      ignore (widget#connect#changed ~callback:begin fun _ ->
        entry_package#set_text (String.concat "," (widget#get_selected_packages()))
      end);
    end);
    (*  *)
    ignore (widget_deps#connect#changed ~callback:begin fun () ->
      self#update (fun target -> target.dependencies <- widget_deps#get()) ();
      changed#call()
    end;);
    (*  *)
    let checks = [
      check_fl_pkg, begin fun () ->
        let packages = String.trim entry_fl_pkg#text in
        if packages <> "" then true, sprintf "HAVE_FL_PKG(%s)" packages else false, ""
      end;
      check_unix, (fun () -> true, "IS_UNIX");
      check_win32, (fun () -> true, "IS_WIN32");
      check_cygwin, (fun () -> true, "IS_CYGWIN");
      check_native, (fun () -> true, "HAVE_NATIVE")
    ] in
    let update_restr () =
      self#update begin fun target ->
        if signals_enabled then
          target.restrictions <-
            List.fold_left begin fun acc (check, f) ->
              if check#active then begin
                let enabled, value = f () in
                if enabled then value :: acc else acc
              end else acc
            end [] checks;
      end ();
      changed#call()
    in
    List.iter begin fun (check, _) ->
      ignore (check#connect#toggled ~callback:update_restr);
    end checks;
    ignore (entry_fl_pkg#connect#changed ~callback:update_restr);
    (*  *)
    ignore (entry_name#connect#changed
      ~callback:begin fun () ->
        self#update (fun target -> target.name <- entry_name#text) ();
        changed#call()
      end);
    ignore (combo_comp#connect#changed
      ~callback:begin fun () ->
        self#update begin fun target ->
          target.byt <- (combo_comp#active = 0 || combo_comp#active = 2);
          self#set_inline target;
        end ();
        changed#call()
      end);
    ignore (combo_comp#connect#changed
      ~callback:(self#update begin fun target ->
        target.opt <- (combo_comp#active = 1 || combo_comp#active = 2);
        self#set_inline target;
      end));
    let update_inline () =
      self#update begin fun target ->
        if signals_enabled then begin
          target.inline <- (if target.opt && check_inline#active then Some entry_inline#value_as_int else None);
        end
      end ();
      changed#call()
    in
    ignore (check_inline#connect#after#toggled ~callback:update_inline);
    ignore (check_inline#connect#after#toggled ~callback:begin fun () ->
      if signals_enabled then begin
        entry_inline#misc#set_sensitive check_inline#active;
      end
    end);
    ignore (adjustment_inline#connect#after#value_changed ~callback:update_inline);
    ignore (entry_libs#connect#changed
      ~callback:(self#update (fun target -> target.libs <- entry_libs#text)));
    ignore (entry_mods#connect#changed
      ~callback:(self#update (fun target -> target.other_objects <- entry_mods#text)));
    ignore (entry_main_module#connect#changed
      ~callback:(self#update begin fun target ->
        if signals_enabled then begin
          target.files <- entry_main_module#text;
          if entry_outname#text = "" then (entry_outname#set_text
            (Filename.chop_extension (Filename.basename entry_main_module#text)))
        end
      end));
    ignore (entry_lib_modules#connect#changed
      ~callback:(self#update begin fun target ->
        if signals_enabled then begin
          target.files <- entry_lib_modules#text
        end
      end));
    ignore (entry_package#connect#changed
      ~callback:(self#update (fun target -> target.package <- entry_package#text)));
    ignore (entry_includes#connect#changed
      ~callback:(self#update (fun target -> target.includes <- entry_includes#text)));
    ignore (check_thread#connect#toggled
      ~callback:(self#update (fun target -> target.thread <- check_thread#active)));
    ignore (check_vmthread#connect#toggled
      ~callback:(self#update (fun target -> target.vmthread <- check_vmthread#active)));
    ignore (entry_pp#connect#changed
      ~callback:(self#update (fun target -> target.pp <- entry_pp#text)));
    ignore (entry_cflags#connect#changed
      ~callback:(self#update (fun target -> target.cflags <- entry_cflags#text)));
    ignore (entry_lflags#connect#changed
      ~callback:(self#update (fun target -> target.lflags <- entry_lflags#text)));
    (* Radio buttons signals *)
    let get_target_type () =
      if radio_archive#active then
        (match combo_kind#active with 0 -> Library | 1 -> Plugin | 2 -> Pack | _ -> assert false)
      else if radio_executable#active then Executable
      else if radio_external#active then External
      else assert false;
    in
    let set_sensitive () =
      align_lib#misc#set_sensitive (not radio_executable#active && not radio_external#active);
      align_exec#misc#set_sensitive radio_executable#active;
      entry_outname#misc#set_sensitive (not radio_external#active);
      if radio_executable#active then (entry_main_module#misc#grab_focus())
      else if radio_archive#active then (button_lib_modules#misc#grab_focus());
    in
    ignore (radio_archive#connect#after#toggled
        ~callback:(self#update begin fun target ->
            set_sensitive();
            if signals_enabled then begin
              target.target_type <- get_target_type();
              entry_lib_modules#set_text "";
              entry_main_module#set_text "";
            end
          end));
    ignore (combo_kind#connect#changed ~callback:(self#update (fun target ->
          target.target_type <- get_target_type())));
    ignore (radio_executable#connect#clicked ~callback:begin fun () ->
        self#update begin fun target ->
          set_sensitive();
          if signals_enabled then begin
            target.target_type <- get_target_type();
          end
         end ();
      end);
    ignore (radio_external#connect#toggled ~callback:begin
        self#update begin fun target ->
          set_sensitive();
          if signals_enabled then begin
            target.target_type <- get_target_type();
          end
        end;
      end);
    (*  *)
    ignore (entry_outname#connect#changed
      ~callback:(self#update (fun target -> target.outname <- entry_outname#text)));
    ignore (entry_lib_install#connect#changed
      ~callback:(self#update begin fun target ->
        target.lib_install_path <- entry_lib_install#text
      end));
    ignore (check_nodep#connect#toggled
      ~callback:(self#update (fun target -> target.nodep <- check_nodep#active)));
    ignore (check_dontlinkdep#connect#toggled
      ~callback:(self#update (fun target -> target.dontlinkdep <- check_dontlinkdep#active)));
    let _ = check_thread#connect#toggled ~callback:begin fun () ->
      if signals_enabled then begin
        check_vmthread#set_active false;
        check_vmthread#misc#set_sensitive (not check_thread#active);
      end
    end in
    let _ = check_vmthread#connect#toggled ~callback:begin fun () ->
      if signals_enabled then begin
        check_thread#set_active false;
        check_thread#misc#set_sensitive (not check_vmthread#active);
      end
    end in
    ignore (self#connect#changed ~callback:(fun () -> page_changed <- true))

  method changed = page_changed
  method set_changed x = page_changed <- x
  method entry_cmd_line = cmd_line
  method entry_name = entry_name

  method private set_inline target =
    check_inline#set_active (target.opt && target.inline <> None);
    entry_inline#set_value (match target.inline with Some inline -> float inline | _ -> 1.);
    check_inline#misc#set_sensitive target.opt;
    entry_inline#misc#set_sensitive (target.opt && check_inline#active);

  method private update update_func () =
    Gaux.may target ~f:begin fun bc ->
      update_func bc;
      Gmisclib.Idle.add ~prio:300 (fun () -> self#update_cmd_line bc);
      (*changed#call()*)
    end;

  method set_target tg =
    signals_enabled <- false;
    target <- Some tg;
    widget_deps#set tg;
    entry_name#set_text tg.name;
    combo_comp#set_active (match tg.byt, tg.opt with
      | true, false -> 0
      | false, true -> 1
      | true, true -> 2
      | _ -> 0);
    self#set_inline tg;
    entry_libs#set_text tg.libs;
    entry_mods#set_text tg.other_objects;
    entry_package#set_text tg.package;
    entry_includes#set_text tg.includes;
    if tg.thread then begin
      check_thread#set_active true;
      check_thread#misc#set_sensitive true;
      check_vmthread#set_active false;
      check_vmthread#misc#set_sensitive false;
    end else if tg.vmthread then begin
      check_thread#set_active false;
      check_thread#misc#set_sensitive false;
      check_vmthread#set_active true;
      check_vmthread#misc#set_sensitive true;
    end else begin
      check_thread#set_active false;
      check_thread#misc#set_sensitive true;
      check_vmthread#set_active false;
      check_vmthread#misc#set_sensitive true;
    end;
    entry_pp#set_text tg.pp;
    entry_cflags#set_text tg.cflags;
    entry_lflags#set_text tg.lflags;
    begin
      match tg.target_type with
        | Executable -> radio_executable#set_active true
        | Library | Pack | Plugin -> radio_archive#set_active true
        | External -> radio_external#set_active true
    end;
    combo_kind#set_active (match tg.target_type with Library -> 0 | Plugin -> 1 | Pack -> 2 | Executable | External -> 0);
    entry_outname#set_text tg.outname;
    entry_lib_install#set_text tg.lib_install_path;
    if (List.mem tg.target_type [Library; Plugin; Pack]) then begin
      align_lib#misc#set_sensitive true;
      align_exec#misc#set_sensitive false;
      entry_lib_modules#set_text tg.files;
      entry_main_module#set_text "";
    end else if (List.mem tg.target_type [External]) then begin
      align_lib#misc#set_sensitive false;
      align_exec#misc#set_sensitive false;
      entry_lib_modules#set_text "";
      entry_main_module#set_text "";
    end else begin
      align_lib#misc#set_sensitive false;
      align_exec#misc#set_sensitive true;
      entry_lib_modules#set_text "";
      let filename = Miscellanea.split " +" tg.files in
      assert (List.length filename <= 1);
      try
        let filename = List.hd filename in
        entry_main_module#set_text filename;
      with Failure "hd" -> (ignore (entry_main_module#set_text ""))
    end;
    check_nodep#set_active tg.nodep;
    check_dontlinkdep#set_active tg.dontlinkdep;
    (*  *)
    check_unix#set_active (List.mem "IS_UNIX" tg.restrictions);
    check_win32#set_active (List.mem "IS_WIN32" tg.restrictions);
    check_cygwin#set_active (List.mem "IS_CYGWIN" tg.restrictions);
    check_native#set_active ((List.mem "HAVE_NATIVE" tg.restrictions) || (List.mem "HAS_NATIVE" tg.restrictions));
    entry_fl_pkg#set_text begin
      match List_opt.find (fun res -> Str.string_match Oebuild.re_fl_pkg_exist res 0) tg.restrictions
      with
        | Some res ->
          if Str.string_match Oebuild.re_fl_pkg_exist res 0 then Str.matched_group 1 res else ""
        | None -> ""
    end;
    check_fl_pkg#set_active (entry_fl_pkg#text <> ""); (*(List.exists (fun r -> Str.string_match Oebuild.re_fl_pkg_exist r 0) tg.restrictions)*)
    (*  *)
    signals_enabled <- true;
    Gmisclib.Idle.add ~prio:300 (fun () -> self#update_cmd_line tg);

  method private update_cmd_line target =
    let cmd, args = create_cmd_line target in
    let args = Xlist.filter_map (fun (e, a) -> if e then Some a else None) args in
    let cmd = sprintf "%s %s" cmd (String.concat " " args) in
    cmd_line#set_text cmd

  method connect = new signals ~changed

end

and changed () = object (self) inherit [unit] signal () as super end
and signals ~changed =
object (self)
  inherit ml_signals [changed#disconnect]
  method changed = changed#connect ~after
end
