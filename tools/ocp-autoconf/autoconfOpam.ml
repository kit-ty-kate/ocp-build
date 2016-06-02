(**************************************************************************)
(*                                                                        *)
(*                              OCamlPro TypeRex                          *)
(*                                                                        *)
(*   Copyright OCamlPro 2011-2016. All rights reserved.                   *)
(*   This file is distributed under the terms of the GPL v3.0             *)
(*      (GNU Public Licence version 3.0).                                 *)
(*                                                                        *)
(*     Contact: <typerex@ocamlpro.com> (http://www.ocamlpro.com/)         *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       *)
(*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *)
(*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   *)
(*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    *)
(*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     *)
(*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      *)
(*  SOFTWARE.                                                             *)
(**************************************************************************)

open StringCompat
open AutoconfProjectConfig
open SimpleConfig.Op (* !! and =:= *)

let opam_version = "1.2"

let manage () =

  if Sys.file_exists "opam" then begin
    Sys.rename "opam" "opam.old";
  end;

  let oc = open_out "opam" in
  Printf.fprintf oc "opam-version: %S\n" opam_version;
  let opam_maintainer = !!AutoconfProjectConfig.opam_maintainer in
  if opam_maintainer <> "" then
    Printf.fprintf oc "maintainer: %S\n" opam_maintainer ;
  let authors = !!AutoconfProjectConfig.authors in
  let authors =
    if authors = [] && opam_maintainer <> "" then
      [ opam_maintainer ]
    else authors
  in
  if authors <> [] then begin
    Printf.fprintf oc "authors: [\n";
    List.iter (fun name ->
        Printf.fprintf oc "  %S\n" name) authors;
    Printf.fprintf oc "]\n";
  end;
  let homepage = !!AutoconfProjectConfig.homepage in
  if homepage <> "" then
    Printf.fprintf oc "homepage: %S\n" homepage;
  let dev_repo = !!AutoconfProjectConfig.dev_repo in
  if dev_repo <> "" then
    Printf.fprintf oc "dev-repo: %S\n"  dev_repo;
  let bug_reports = !!AutoconfProjectConfig.bug_reports in
  if bug_reports <> "" then
    Printf.fprintf oc "bug-reports: %S\n" bug_reports;
  Printf.fprintf oc "build: [\n";
  Printf.fprintf oc "  [ \"./configure\" \n";
  Printf.fprintf oc "    \"--prefix\" \"%%{prefix}%%\" \n";
  Printf.fprintf oc "    \"--with-ocamldir\" \"%%{prefix}%%/lib\" \n";
  Printf.fprintf oc "    \"--with-metadir\" \"%%{prefix}%%/lib\" \n";
  Printf.fprintf oc "  ]\n";
  Printf.fprintf oc "  [ make ]\n";
  Printf.fprintf oc "]\n";
  Printf.fprintf oc "install: [\n";
  Printf.fprintf oc "  [ make \"install\" ]\n";
  Printf.fprintf oc "]\n";
  Printf.fprintf oc "remove: [\n";
  List.iter (fun file ->
      Printf.fprintf oc "  [ \"rm\" \"-f\" %S ]\n" file)
    !!AutoconfProjectConfig.opam_remove_files;
  List.iter (fun pkg ->
      Printf.fprintf oc "  [ \"ocp-build\" \"uninstall\" %S ]\n" pkg)
    !!AutoconfProjectConfig.install_packages;
  Printf.fprintf oc "]\n";
  Printf.fprintf oc "depends: [\n";
  List.iter (fun (n,v) ->
      match v with
      | None ->
        Printf.fprintf oc "     %S\n" n
      | Some v ->
        Printf.fprintf oc "     %S {>= %S }\n" n v
    ) !!AutoconfProjectConfig.need_packages;
  Printf.fprintf oc "]\n";
  Printf.fprintf oc "available: [ocaml-version >= %S]\n"
    !!AutoconfProjectConfig.ocaml_minimal_version;

  close_out oc;
  [ "opam" ]

  (*
  let extra_files = ref [] in

  let need_pkgs = ref [] in
  let need_ocamlbuild = ref false in
  let need_ocamlfind = ref false in
  let need_camlp4 = ref false in

  List.iter (fun (package, version) ->
      match package with
      | "ocamlbuild" -> need_ocamlbuild := true
      | "ocamlfind" -> need_ocamlfind := true
      | "camlp4" -> need_camlp4 := true
      | _ ->
        need_pkgs := (package, version) :: !need_pkgs
    ) !!need_packages;
  if !!optional_packages <> [] then need_ocamlfind := true;

  let need_packages = List.rev !need_pkgs in

  FileString.safe_mkdir "autoconf";
  Printf.eprintf "Saving template files...\n%!";
  List.iter AutoconfCommon.save_file [
    "skeleton/autoconf/m4/ax_compare_version.m4";
    "skeleton/autoconf/m4/ocaml.m4";
    "skeleton/autoconf/Makefile.rules";
    "skeleton/autoconf/.gitignore";
  ] ;
  if not (Sys.file_exists "configure") then begin
    Printf.eprintf "Warning: ./configure, creating one.\n%!";
    FileString.write_file "configure"
      (AutoconfCommon.find_content "skeleton/configure");
    Unix.chmod "configure"  0o755;
  end;
  List.iter (fun filename ->
      let content = FileString.read_file filename in
      let basename = Filename.basename filename in
      let dst_filename = Filename.concat "autoconf/m4" basename in
      extra_files := dst_filename :: !extra_files;
      FileString.write_file dst_filename content
    ) !!extra_m4_files;


  List.iter (AutoconfCommon.save_file ~override:false) [
    "skeleton/build.ocp";
    "skeleton/Makefile";
    "skeleton/ocp-autoconf.ac";
    "skeleton/.gitignore";
    "skeleton/LICENSE";
  ];

  if not (Sys.file_exists ".git") then begin
    AutoconfCommon.command "git init"
  end;

  let oc = open_out "autoconf/configure.ac" in

  Printf.fprintf oc "#######################################################\n";
  Printf.fprintf oc "#                                                     #\n";
  Printf.fprintf oc "#               DO NOT EDIT THIS FILE                 #\n";
  Printf.fprintf oc "#                                                     #\n";
  Printf.fprintf oc "#  Use ocp-autoconf to generate this file from:       #\n";
  Printf.fprintf oc "#   * ocp-autoconf.config for the OCaml part          #\n";
  Printf.fprintf oc "#   * ocp-autoconf.ac for autoconf parts              #\n";
  Printf.fprintf oc "#                                                     #\n";
  Printf.fprintf oc "#######################################################\n";

  Printf.fprintf oc "AC_INIT(%s,%s)\n" !!project_name !!project_version;
  Printf.fprintf oc "CONFIGURE_ARGS=$*\n";
  Printf.fprintf oc "AC_COPYRIGHT(%s)\n" !!project_copyright;
  Printf.fprintf oc "OCAML_MINIMAL_VERSION=%s\n" !!ocaml_minimal_version;

  output_string oc (AutoconfCommon.find_content "skeleton/autoconf/configure.ocaml");

  if !!ocaml_unsupported_version <> "" then begin
    Printf.fprintf oc "if test \"$VERSION_CHECK\" = \"yes\" ; then\n";
    Printf.fprintf oc "  AX_COMPARE_VERSION( [$OCAMLVERSION], [ge], [%s],\n" !!ocaml_unsupported_version;
    Printf.fprintf oc "     AC_MSG_ERROR([Your version of OCaml: $OCAMLVERSION is not yet supported]))\n";
    Printf.fprintf oc "fi\n";
  end;

  if !!need_ocamllex then begin
    Printf.fprintf oc "AC_PROG_OCAMLLEX\n";
  end;

  if !!need_ocamlyacc then begin
    Printf.fprintf oc "AC_PROG_OCAMLYACC\n";
  end;

  if !need_camlp4 then begin
    Printf.fprintf oc "AC_PROG_CAMLP4\n";
    Printf.fprintf oc "if test \"$CAMLP4\" = \"no\"; then\n";
    Printf.fprintf oc "   AC_MSG_ERROR([You must install OCaml package 'camlp4'])\n";
    Printf.fprintf oc "fi\n";
  end;

  if !need_ocamlbuild then begin
    Printf.fprintf oc "if test \"$OCAMLBUILD\" = \"no\"; then\n";
    Printf.fprintf oc "   AC_MSG_ERROR([You must install OCaml package 'ocamlbuild'])\n";
    Printf.fprintf oc "fi\n";
  end;

  if !need_ocamlfind then begin
    (* Printf.fprintf oc "AC_PROG_FINDLIB\n"; ALREADY DONE *)
    Printf.fprintf oc "if test \"$OCAMLFIND\" = \"no\"; then\n";
    Printf.fprintf oc "   AC_MSG_ERROR([You must install OCaml package 'ocamlfind'])\n";
    Printf.fprintf oc "fi\n";
  end;

  let to_ac package =
    let package = Bytes.of_string package in
    for i = 0 to Bytes.length package -1 do
      match Bytes.get package i with
      | '-' -> Bytes.set package i '_'
      | _ -> ()
    done;
    Bytes.to_string package
  in

  List.iter (fun tool ->
      let pkg = to_ac tool in
      Printf.fprintf oc "AC_CHECK_TOOL([OCAML_TOOL_%s],[%s],[no])\n"
        pkg tool;
      Printf.fprintf oc "if test \"$OCAML_TOOL_%s\" = \"no\"; then\n" pkg;
      Printf.fprintf oc "   AC_MSG_ERROR([Please install OCaml tool '%s'.])\n" tool;
      Printf.fprintf oc "fi\n";

    ) !!need_tools;

  List.iter (fun (package, version) ->
      let pkg = to_ac package in
      Printf.fprintf oc "AC_CHECK_OCAML_PKG(%s)\n" package;
      Printf.fprintf oc "if test \"$OCAML_PKG_%s\" = \"no\"; then\n" pkg;
      Printf.fprintf oc "   AC_MSG_ERROR([Please install OCaml package '%s'.])\n" package;
      Printf.fprintf oc "fi\n";
      match version with
      | None -> ()
      | Some version ->
        Printf.fprintf oc "  AX_COMPARE_VERSION( [$OCAML_PKG_%s_VERSION], [lt], [%s],\n" pkg version;
        Printf.fprintf oc "     AC_MSG_ERROR([Version %s of %s is needed]))\n" version pkg;

    ) need_packages;

  List.iter (fun package ->
      let pkg = to_ac package in
      Printf.fprintf oc "AC_CHECK_OCAML_PKG([%s])\n" package;
      Printf.fprintf oc
        "AC_ARG_ENABLE(lwt,  [  --disable-%s           to disable %s],\n"
        package package;
      Printf.fprintf oc "                    [OCAML_PKG_%s=no],[])\n" pkg;

      Printf.fprintf oc "if test \"$OCAML_PKG_%s\" = \"no\"; then\n" pkg;
      Printf.fprintf oc "   %s_ENABLED=false\n" pkg;
      Printf.fprintf oc "else\n";
      Printf.fprintf oc "   %s_ENABLED=true\n" pkg;
      Printf.fprintf oc "fi\n";
      Printf.fprintf oc "AC_SUBST(%s_ENABLED)\n" pkg;

    ) !!optional_packages;

  List.iter (fun modname ->
      Printf.fprintf oc "AC_CHECK_OCAML_MODULE(%s)\n" modname
    ) !!need_modules;

  if Sys.file_exists "ocp-autoconf.ac" then begin
    Printf.eprintf "Using %S\n%!" "ocp-autoconf.ac";
    output_string oc (FileString.read_file "ocp-autoconf.ac");
  end;

  let default_config_vars =
    (List.map (fun s -> s, None)
      [
        "CONFIGURE_ARGS";
      ]) @
    (List.map (fun s -> s, Some (String.lowercase s)) [
        "ROOTDIR";
        "prefix";
        "exec_prefix";
        "bindir";
        "libdir";
        "datarootdir";
        "mandir";
        "datadir";

        "ocamldir";
        "metadir";
        "PACKAGE_NAME";
        "PACKAGE_VERSION";
      ]) @
    (List.map (fun s ->
         s, Some ("conf_" ^ String.lowercase s)) [
           "OCAMLVERSION";
           "OCAMLC";
           "OCAMLOPT";
           "OCAMLDEP";
           "OCAMLMKTOP";
           "OCAMLMKLIB";
           "OCAMLDOC";
           "OCAMLLIB";
           "OCAMLBIN";
      ])

  in
  let config_vars =
    default_config_vars @
    (List.map (fun s -> s, Some ("conf_" ^ String.lowercase s)
              ) !!extra_config_vars)  in

  let config_vars =
    if !!need_ocamllex then
      ("OCAMLLEX", Some "conf_ocamllex") :: config_vars
    else config_vars in

  let config_vars =
    if !!need_ocamlyacc then
      ("OCAMLYACC", Some "conf_ocamlyacc") :: config_vars
    else config_vars in

  let config_vars =
    if !need_ocamlbuild then
      ("OCAMLBUILD", Some "conf_ocamlbuild") :: config_vars
    else config_vars in

  let config_vars =
    if !need_ocamlfind then
      ("OCAMLFIND", Some "conf_ocamlfind") :: config_vars
    else config_vars in

  let config_vars =
    if !need_camlp4 then
      ("CAMLP4", Some "conf_camlp4") ::
      ("CAMLP4O", Some "conf_camlp4o") ::
      config_vars
    else config_vars in

  List.iter (fun (var, _) ->
      Printf.fprintf oc "AC_SUBST(%s)\n" var
    ) config_vars;

  let bool_vars =
    "OCAML_USE_BINANNOT" ::
    !!extra_bool_vars
    @
    List.map (fun package ->
        let pkg = to_ac package in
        Printf.sprintf "%s_ENABLED" pkg
      ) !!optional_packages;
  in

  List.iter (fun var ->
      Printf.fprintf oc "AC_SUBST(%s)\n" var
    ) bool_vars;


  Printf.fprintf oc "AC_CONFIG_FILES(%s)\n"
    (String.concat " "
       ("Makefile.config" :: "config.ocpgen" :: "ocaml-config.h" ::
        !!extra_config_files));

  output_string oc
    (AutoconfCommon.find_content "skeleton/autoconf/configure.trailer");
  close_out oc;


  let oc = open_out "autoconf/Makefile.config.in" in
  List.iter (fun (var,_) ->
      Printf.fprintf oc "%s=@%s@\n" var var;
    ) config_vars;
  List.iter (fun var ->
      Printf.fprintf oc "%s=@%s@\n" var var;
    ) bool_vars;
  close_out oc;

  close_out oc;

  let oc = open_out "autoconf/config.ocpgen.in" in
  List.iter (function
      | (var, None)-> ()
      | (var, Some name) ->
        Printf.fprintf oc "%s=\"@%s@\"\n" name var;
    ) config_vars;

  List.iter (fun var ->
      Printf.fprintf oc "%s = @%s@\n" (String.lowercase var) var
    ) bool_vars;

  Printf.fprintf oc "autoconf_dir = \"@PACKAGE_NAME@-autoconf-dir\"\n";
  output_string oc (AutoconfCommon.find_content
                      "skeleton/autoconf/config.trailer");
  close_out oc;


  let oc = open_out "autoconf/ocaml-config.h.in" in
  Printf.fprintf oc "#@OCAML_USE_POSIX_TYPES@ OCAML_USE_POSIX_TYPES\n";
  close_out oc;

  let oc = open_out "autoconf/build.ocp" in
  Printf.fprintf oc "(* Just here to refer to this directory *)\n";
  Printf.fprintf oc "if include \"config.ocpgen\" then {} else {}\n";
  Printf.fprintf oc "begin library autoconf_dir end\n";
  close_out oc;

  Unix.chdir "autoconf";

  AutoconfCommon.command "aclocal -I m4";
  AutoconfCommon.command "autoconf";

  Unix.chdir "..";

  Printf.eprintf "Now, you should call ./configure\n%!";

  !extra_files @ [
      "ocp-autoconf.ac";
      ".gitignore";
      "configure";
      "ocp-autoconf.config";
      "LICENSE";
      "build.ocp";
      "Makefile";
      "autoconf";
      "autoconf/config.ocpgen.in";
      "autoconf/.gitignore";
      "autoconf/configure";
      "autoconf/ocaml-config.h.in";
      "autoconf/Makefile.rules";
      "autoconf/configure.ac";
      "autoconf/build.ocp";
      "autoconf/Makefile.config.in";
      "autoconf/aclocal.m4";
      "autoconf/m4";
      "autoconf/m4/ax_compare_version.m4";
      "autoconf/m4/ocaml.m4";
  ]
*)
