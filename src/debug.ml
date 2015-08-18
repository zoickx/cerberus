(*
module Loc = struct
  let of_tuple (file, line, _, _, _, _, _, _) = 
    "file: " ^ file ^ ", line: " ^ (string_of_int line)
end

(* Debug mode *)
let debug = true


let print msg = if debug then
                  print_endline ("\x1b[31m[DEBUG] " ^ msg ^ "\x1b[0m")(* "\x1b[31mDEBUG[" ^ __LOCATION__ ^ "]" *)
                else
                  ()

let error msg = print_endline ("\x1b[31m[ERROR] " ^ msg ^ "\x1b[0m"); exit 1
*)

(*
assert_false () =
  assert false
*)

let error str =
  failwith str


let debug_level = ref 0

let get_debug_level () =
  !debug_level

let print_success msg =
  if !debug_level > 0 then
    prerr_endline Colour.(ansi_format [Green] msg)

let print_debug level msg =
  if !debug_level >= level then
    prerr_endline Colour.(ansi_format [Red] ("(debug " ^ string_of_int level ^ "): " ^ msg))

let print_debug2 msg k =
  if !debug_level > 0 then
    let _ = prerr_endline Colour.(ansi_format [Red] ("\x1b[31mDEBUG: " ^ msg ^ "\x1b[0m")) in k
  else
    k

let output_string2 msg =
  if !debug_level > 0 then
    prerr_endline msg




let timing_stack =
  ref []

let begin_timing (fun_name: string) =
  timing_stack := (fun_name, Unix.gettimeofday ()) :: !timing_stack

let end_timing () =
  let t' = Unix.gettimeofday () in
  match !timing_stack with
    | [] ->
        () (* this implies an improper use of end_timing, but we silently ignore *)
    | (str, t) :: xs ->
        let oc = open_out_gen [Open_creat; Open_wronly; Open_append] 0o666 "cerb.prof" in
        Printf.fprintf oc "[%s] %f\n" str (t' -. t);
        close_out oc;
        timing_stack := xs
