module CF = Cerb_frontend
module SymSet = Set.Make (Sym)
module SymMap = Map.Make (Sym)
module IT = IndexTerms
module LC = LogicalConstraints
module LCSet = Set.Make (LC)
open ResourceTypes

type oargs = O of IT.t

let pp_oargs (O t) = IT.pp t

type resource = resource_type * oargs

type t = resource

let request (r, _oargs) = r

let oargs_bt (_re, O oargs) = IT.bt oargs

let pp (r, O oargs) = ResourceTypes.pp_aux r (Some oargs)

let json re : Yojson.Safe.t = `String (Pp.plain (pp re))

let subst substitution ((r, O oargs) : t) =
  (ResourceTypes.subst substitution r, O (IT.subst substitution oargs))


let free_vars (r, O oargs) = SymSet.union (ResourceTypes.free_vars r) (IT.free_vars oargs)

let range_size ct =
  let here = Locations.other (__FUNCTION__ ^ ":" ^ string_of_int __LINE__) in
  let size = Memory.size_of_ctype ct in
  IT.num_lit_ (Z.of_int size) Memory.uintptr_bt here


let upper_bound addr ct =
  let here = Locations.other (__FUNCTION__ ^ ":" ^ string_of_int __LINE__) in
  IT.add_ (addr, range_size ct) here


let addr_of pointer =
  let here = Locations.other (__FUNCTION__ ^ ":" ^ string_of_int __LINE__) in
  IT.addr_ pointer here


(* assumption: the resource is owned *)
let derived_lc1 (resource, _) =
  let here = Locations.other (__FUNCTION__ ^ ":" ^ string_of_int __LINE__) in
  match resource with
  | P { name = Owned (ct, _); pointer; iargs = _ } ->
    let addr = addr_of pointer in
    [ IT.hasAllocId_ pointer here; IT.(lt_ (addr, upper_bound addr ct) here) ]
  | Q { name = Owned _; pointer; _ } -> [ IT.hasAllocId_ pointer here ]
  | P { name = PName _; pointer = _; iargs = _ } | Q { name = PName _; _ } -> []


(* assumption: both resources are owned at the same *)
(* todo, depending on how much we need *)
let derived_lc2 (resource, _) (resource', _) =
  match (resource, resource') with
  | ( P { name = Owned (ct1, _); pointer = p1; iargs = _ },
      P { name = Owned (ct2, _); pointer = p2; iargs = _ } ) ->
    let here = Locations.other (__FUNCTION__ ^ ":" ^ string_of_int __LINE__) in
    let addr1 = addr_of p1 in
    let addr2 = addr_of p2 in
    let up1 = upper_bound addr1 ct1 in
    let up2 = upper_bound addr2 ct2 in
    [ IT.(or2_ (le_ (up2, addr1) here, le_ (up1, addr2) here) here) ]
  | _ -> []


let pointer_facts ~new_resource ~old_resources =
  derived_lc1 new_resource @ List.concat_map (derived_lc2 new_resource) old_resources
