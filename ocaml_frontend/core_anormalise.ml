(*Generated by Lem from frontend/model/core_anormalise.lem.*)
open Lem_pervasives
open Ctype
open Lem_assert_extra


open Core
open Mucore
open Annot

open Debug_ocaml

module Loc = Location_ocaml

(* The a-normalisation should happen after some partial evaluation and
   rewrites that remove expressions passing ctypes and function
   pointers as values. The embedding into mucore then is partial in
   those places. *)


(* type bty = core_base_type *)
type value = Symbol.sym generic_value
type values = value list
type 'bty pexpr = ('bty, Symbol.sym) generic_pexpr
type 'bty pexprs = ('bty pexpr) list
type ('a, 'bty) expr = ('a, 'bty, Symbol.sym) generic_expr
type pattern = mu_base_type mu_pattern
type annot = Annot.annot
type annots = annot list
type outer_annots = annots
type ('a, 'bty) action1 = ('a, 'bty, Symbol.sym) generic_action
type ('a, 'bty) paction = ('a, 'bty, Symbol.sym) generic_paction

type ct = Ctype.ctype
type ut = ct mu_union_def
type st = ct mu_struct_def
type ft = ct Mucore.mu_funinfo_type
type lt = (Symbol.sym option * (Ctype.ctype * bool)) list
type bt = Mucore.mu_base_type

type mu_value = (ct, bt, unit) Mucore.mu_value
type mu_values = mu_value list
type mu_pexpr = (ct, bt, unit) Mucore.mu_pexpr
type mu_pexprs = mu_pexpr list
type mu_expr = (ct, bt, unit) Mucore.mu_expr
type mu_pattern = bt Mucore.mu_pattern
type mu_action = (ct, unit) Mucore.mu_action
type mu_paction = (ct, unit) Mucore.mu_paction
type mu_sym_or_pattern = (bt, unit) Mucore.mu_sym_or_pattern


type asym = unit Mucore.asym
type asyms = asym list


let always_explode_eif:bool=  false


module type LocationCheck = sig

  val good_location : Location_ocaml.t -> bool

end


module Make (L : LocationCheck) = struct

(* include other things to ignore *)
let update_loc loc1 loc2 = 
  if L.good_location loc2 then loc1 else loc2

let maybe_set_loc loc annots = 
  if L.good_location loc 
  then Annot.set_loc loc annots 
  else annots
  



(* ... adapting the algorithm from
   http://matt.might.net/articles/a-normalization/ for core *)


let bty_of_pexpr (Pexpr (_, bty, _)) =  bty
let bty_of_mu_pexpr (M_Pexpr (_, bty, _)) =  bty

let is_symbol (M_Pexpr(annots2, bty, e)): ((Symbol.sym, 'a) a) option = 
  match e with
  | M_PEsym sym1 -> Some (a_pack annots2 bty sym1)
  | _ -> None


(* Here we depend on bty being of type core_base_type *)
let var_pexpr sym1 annots2 bty : ('c,'b,'a) Mucore.mu_pexpr = 
  M_Pexpr (annots2, bty, (M_PEsym sym1))





let ensure_ctype__pexpr = function
  | Core.Pexpr (annots, bty, Core.PEval (Core.Vctype ct)) -> 
     Some (a_pack annots bty ct)
  | _ -> None


let fensure_ctype__pexpr loc err pe : (ctype,'b) a = 
  match ensure_ctype__pexpr pe with
  | Some ctype1 -> ctype1
  | None -> error (err ^ " (" ^ Location_ocaml.location_to_string loc ^ ")")





let core_to_mu__ctor loc ctor : core_base_type mu_ctor = 
  (* let loc = Loc.location_to_string loc in *)
  match ctor with 
  | Core.Cnil bt1 -> M_Cnil bt1
  | Core.Ccons -> M_Ccons
  | Core.Ctuple -> M_Ctuple
  | Core.Carray -> M_Carray
  | Core.CivCOMPL -> M_CivCOMPL
  | Core.CivAND-> M_CivAND
  | Core.CivOR -> M_CivOR
  | Core.CivXOR -> M_CivXOR
  | Core.Cspecified -> M_Cspecified
  | Core.Cfvfromint-> M_Cfvfromint
  | Core.Civfromfloat -> M_Civfromfloat
  | Core.Civmax -> error ("core_anormalisation: Civmax")
  | Core.Civmin -> error ("core_anormalisation: Civmin")
  | Core.Civsizeof -> error ("core_anormalisation: Civsizeof")
  | Core.Civalignof -> error ("core_anormalisation: Civalignof")
  | Core.Cunspecified -> error ("core_anormalisation: Cunspecified")


let rec core_to_mu__pattern loc (Core.Pattern (annots, pat_)) : core_base_type Mucore.mu_pattern = 
  let wrap pat_ = M_Pattern(annots, pat_) in
  let loc = update_loc loc (Annot.get_loc_ annots) in
  match pat_ with
  | Core.CaseBase (msym, bt1) -> 
     wrap (M_CaseBase (msym, bt1))
  | Core.CaseCtor(ctor, pats) -> 
     let ctor = core_to_mu__ctor loc ctor in
     let pats = map (core_to_mu__pattern loc) pats in
     wrap (M_CaseCtor(ctor, pats))



type ('bound, 'body) letbinder = 
  mu_sym_or_pattern -> 'bound -> 'body -> 'body

type 'd n_pexpr_domain = 
  { letbinder : (mu_pexpr, 'd) letbinder }



(*val letbinder_pexpr_in_pexpr : letbinder mu_pexpr mu_pexpr*)
let letbinder_pexpr_in_pexpr pat pexpr body : mu_pexpr = 
  M_Pexpr ([], bty_of_mu_pexpr body, M_PElet (pat, pexpr, body))

(*val letbinder_pexpr_in_expr : letbinder mu_pexpr mu_expr*)
let letbinder_pexpr_in_expr pat pexpr body : mu_expr = 
  M_Expr ([], M_Elet (pat, pexpr, body))


let pexpr_n_pexpr_domain = { letbinder = letbinder_pexpr_in_pexpr }
let expr_n_pexpr_domain = { letbinder = letbinder_pexpr_in_expr }


let letbind_pexpr loc domain pexpr ctxt : 'a = 
  let (M_Pexpr (annots, bty, pe_)) = pexpr in
  let loc' = update_loc loc (get_loc_ annots) in
  let pexpr = M_Pexpr (maybe_set_loc loc' annots, bty, pe_) in
  let sym = Symbol.fresh () in
  let asym = a_pack (only_loc annots) bty sym in
  let body = ctxt asym in
  domain.letbinder (M_Symbol sym) pexpr body


let rec n_ov loc domain v k : 'a = 
  match v with
  | Core.OVinteger iv -> k (M_OVinteger iv)
  | Core.OVfloating fv -> k (M_OVfloating fv)
  | Core.OVpointer pv -> k (M_OVpointer pv)
  | Core.OVarray is -> 
     let vs = (map (fun g -> Vloaded g) is) in
     n_val_names loc domain vs (fun syms ->
     k (M_OVarray syms))
  | Core.OVstruct (sym1, is) -> k (M_OVstruct (sym1, is))
  | Core.OVunion (sym1, id1, mv) -> k (M_OVunion (sym1, id1, mv))

and n_lv loc domain v k :'a = 
  match v with
  | LVspecified ov ->
     n_ov loc domain ov (fun ov -> k (M_LVspecified ov))
  | LVunspecified ct1 ->
     error "core_anormalisation: LVunspeified"


and n_val loc domain v k :'a = 
  match v with
  | Vobject ov -> n_ov loc domain ov (fun ov -> k (M_Vobject ov))
  | Vloaded lv -> n_lv loc domain lv (fun lv -> k (M_Vloaded lv))
  | Vunit -> k M_Vunit
  | Vtrue -> k M_Vtrue
  | Vfalse -> k M_Vfalse
  | Vctype ct1 -> error "core_anormalisation: Vctype"
  | Vlist (cbt, vs) -> 
     n_val_names loc domain vs (fun vs -> k (M_Vlist (cbt, vs)))
  | Vtuple vs -> 
     n_val_names loc domain vs (fun vs -> k (M_Vtuple vs))


 (* here we make explicit unit btys *)
and n_val_name loc domain v k :'a = 
  let bty = () in
  n_val loc domain v (fun v -> 
  let pe = M_Pexpr ([Aloc loc], bty, (M_PEval v)) in
  letbind_pexpr loc domain pe (fun sym -> 
  k sym))

and n_val_names loc domain vs k :'a = 
  match vs with
  | [] -> k []
  | v :: vs ->
     n_val_name loc domain v (fun sym ->
     n_val_names loc domain vs (fun syms ->
     k (sym :: syms)))






(* This code now twice, once for m_pexpr, once for embedding into
   expr. This could be done parameterically with letbinder as before,
   but that probably needs polymorphic recursion that Lem doesn't seem
   to have. *)


(* 1 begin *)

let rec n_pexpr_name : 'a. Loc.t -> 'a n_pexpr_domain ->
                     unit pexpr -> (asym -> 'a) -> 'a = 
  fun loc domain e k ->
  n_pexpr loc domain e (fun e -> 
      match is_symbol e with
      | Some sym1 -> k sym1
      | None -> letbind_pexpr loc domain e k
  )

and n_pexpr_name_2 : 'a. Loc.t -> 'a n_pexpr_domain ->
                     (unit pexpr * unit pexpr) -> ((asym * asym) -> 'a) -> 'a = 
  fun loc domain (e, e') k ->
  n_pexpr_name loc domain e (fun e -> 
  n_pexpr_name loc domain e' (fun e' ->
  k (e,e')))

and n_pexpr_name_3 : 'a. Loc.t -> 'a n_pexpr_domain ->
                     (unit pexpr * unit pexpr * unit pexpr) -> 
                     ((asym * asym * asym) -> 'a) -> 'a = 
  fun loc domain  (e, e', e'') k ->
  n_pexpr_name loc domain e (fun e -> 
  n_pexpr_name loc domain e' (fun e' ->
  n_pexpr_name loc domain e'' (fun e'' ->
  k (e,e',e''))))

and n_pexpr_names : 'a. Loc.t -> 'a n_pexpr_domain ->
                     unit pexpr list -> (asyms -> 'a) -> 'a = 
  fun loc domain es k ->
  match es with 
  | [] -> k []
  | e :: es -> 
     n_pexpr_name loc domain e (fun e -> 
     n_pexpr_names loc domain es (fun es ->
     k (e :: es)))


and n_pexpr : 'a. Loc.t -> 'a n_pexpr_domain ->
                     unit pexpr -> (mu_pexpr -> 'a) -> 'a = 
  fun loc domain e k ->
  let (Pexpr (annots, bty, pe)) = e in
  let annotate pe= M_Pexpr (annots, bty, pe) in
  let loc = update_loc loc (get_loc_ annots) in
  match pe with
  | PEsym sym1 -> 
     k (annotate (M_PEsym sym1))
  | PEimpl i -> 
     k (annotate (M_PEimpl i))
  | PEval v -> 
     n_val loc domain v (fun v ->
     k (annotate (M_PEval v)))
  | PEconstrained l -> 
     let (constraints,exprs) = (List.split l) in
     n_pexpr_names loc domain exprs (fun exprs ->
     let l = (list_combine constraints exprs) in
     k (annotate (M_PEconstrained l)))
  | PEundef(l, u) -> 
     k (annotate (M_PEundef(l, u)))
  | PEerror(err, e') ->
     n_pexpr_name loc domain e' (fun e' -> 
     k (annotate (M_PEerror(err, e'))))
  | PEctor(ctor1, args) ->
     n_pexpr_names loc domain args (fun args -> 
     k (annotate (M_PEctor((core_to_mu__ctor loc ctor1), args))))
  | PEcase(e', pats_pes) ->
     n_pexpr_name loc domain e' (fun e' -> 
        let pats_pes = 
          map (fun (pat,pe) -> 
              let pat = core_to_mu__pattern loc pat in
              let pe = normalise_pexpr loc pexpr_n_pexpr_domain pe in
              (pat, pe)
            ) pats_pes
        in
        k (annotate (M_PEcase(e', pats_pes)))
    )
  | PEarray_shift(e', ctype1, e'') ->
     n_pexpr_name_2 loc domain (e',e'') (fun (e',e'') -> 
     k (annotate (M_PEarray_shift(e', ctype1, e''))))
  | PEmember_shift(e', sym1, id1) ->
     n_pexpr_name loc domain e' (fun e' -> 
     k (annotate (M_PEmember_shift(e', sym1, id1))))
  | PEnot e' -> 
     n_pexpr_name loc domain e' (fun e' -> 
     k (annotate (M_PEnot e')))
  | PEop(binop1, e', e'') ->
     n_pexpr_name_2 loc domain (e',e'') (fun (e',e'') -> 
     k (annotate (M_PEop(binop1, e', e''))))
  | PEstruct(sym1, fields) ->
     let (fnames, pes) = (List.split fields) in
     n_pexpr_names loc domain pes (fun pes ->
     let fields = (list_combine fnames pes) in
     k (annotate (M_PEstruct(sym1, fields))))
  | PEunion(sym1, id1, e') ->
     n_pexpr_name loc domain e' (fun e' ->
     k (annotate (M_PEunion(sym1, id1, e'))))
  | PEcfunction e' ->
     error "core_anormalisation: PEcfunction"
  | PEmemberof(sym1, id1, e') ->
     n_pexpr_name loc domain e' (fun e' ->
     k (annotate (M_PEmemberof(sym1, id1, e'))))
  | PEcall(sym1, args) ->
     n_pexpr_names loc domain args (fun args ->
     k (annotate (M_PEcall(sym1, args))))
  | PElet(pat, e', e'') ->
     let e' = normalise_pexpr loc pexpr_n_pexpr_domain e' in
     let e'' = normalise_pexpr loc pexpr_n_pexpr_domain e'' in
     k (annotate (M_PElet (M_Pat (core_to_mu__pattern loc pat), e', e'')))
  | PEif(e', e'', e''') ->
     n_pexpr_name loc domain e' (fun e' ->
     let e'' = normalise_pexpr loc pexpr_n_pexpr_domain e'' in
     let e''' = normalise_pexpr loc pexpr_n_pexpr_domain e''' in
     k (annotate (M_PEif(e', e'', e'''))))
  | PEis_scalar e' ->
     error "core_anormalisation: PEis_scalar"
  | PEis_integer e' ->
     error "core_anormalisation: PEis_integer"
  | PEis_signed e' ->
     error "core_anormalisation: PEis_signed"
  | PEis_unsigned e' ->
     error "core_anormalisation: PEis_unsigned"
  | PEbmc_assume e' ->
     error "core_anormalisation: PEbmc_assume"
  | PEare_compatible(e', e'') ->
     error "core_anormalisation: PEare_compatible"

and normalise_pexpr (loc : Loc.t) (domain : 'a n_pexpr_domain) (e'' : unit pexpr) = 
  n_pexpr loc domain e'' (fun e -> e)


let n_pexpr_in_expr : Loc.t -> unit pexpr -> (mu_pexpr -> mu_expr) -> mu_expr = 
  fun loc pe k -> 
  n_pexpr loc expr_n_pexpr_domain pe k

let n_pexpr_in_expr_name : Loc.t -> unit pexpr -> (asym -> mu_expr) -> mu_expr = 
  fun loc pe k -> 
  n_pexpr_name loc expr_n_pexpr_domain pe k

let n_pexpr_in_expr_name_2 : Loc.t -> (unit pexpr * unit pexpr) -> 
                             (asym * asym -> mu_expr) -> mu_expr = 
  fun loc (pe, pe') k -> 
  n_pexpr_name_2 loc expr_n_pexpr_domain (pe, pe') k

let n_pexpr_in_expr_name_3 : Loc.t ->
                             (unit pexpr * unit pexpr * unit pexpr) -> 
                             (asym * asym * asym -> mu_expr) -> mu_expr = 
  fun loc (pe, pe', pe'') k -> 
  n_pexpr_name_3 loc expr_n_pexpr_domain (pe, pe', pe'') k


let n_pexpr_in_expr_names : Loc.t -> (unit pexpr) list -> 
                            (asyms -> mu_expr) -> mu_expr = 
  fun loc pes k -> 
  n_pexpr_names loc expr_n_pexpr_domain pes k


let n_kill_kind = function
  | Core.Dynamic -> M_Dynamic
  | Core.Static0 ct1 -> M_Static ct1


let n_action loc (action : ('a, unit) action1) 
      (k : mu_action -> mu_expr) : (ct, bt, unit) Mucore.mu_expr = 
  let (Action (loc', _, a1)) = action in
  let loc = update_loc loc loc' in
  let n_pexpr_in_expr_name = n_pexpr_in_expr_name loc in
  let wrap a1 = M_Action(loc', a1) in
  match a1 with
  | Create(e1, e2, sym1) ->
     let ctype1 = (fensure_ctype__pexpr loc "Create: not a ctype" e2) in
     n_pexpr_in_expr_name e1 (fun e1 ->
     k (wrap (M_Create(e1, ctype1, sym1))))
  | CreateReadOnly(e1, e2, e3, sym1) ->
     let ctype1 = (fensure_ctype__pexpr loc "CreateReadOnly: not a ctype" e1) in
     n_pexpr_in_expr_name e1 (fun e1 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     k (wrap (M_CreateReadOnly(e1, ctype1, e3, sym1)))))
  | Alloc0(e1, e2, sym1) ->
     n_pexpr_in_expr_name e2 (fun e1 ->
     n_pexpr_in_expr_name e2 (fun e2 ->
     k (wrap (M_Alloc(e1, e2, sym1)))))
  | Kill(kind, e1) ->
     n_pexpr_in_expr_name e1 (fun e1 ->
     k (wrap (M_Kill((n_kill_kind kind), e1))))
  | Store0(b, e1, e2, e3, mo1) ->
     let ctype1 = (fensure_ctype__pexpr loc "Store: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     k (wrap (M_Store(b, ctype1, e2, e3, mo1)))))
  | Load0(e1, e2, mo1) ->
     let ctype1 = (fensure_ctype__pexpr loc "Load: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     k (wrap (M_Load(ctype1, e2, mo1))))
  | RMW0(e1, e2, e3, e4, mo1, mo2) ->
     let ctype1 = (fensure_ctype__pexpr loc "RMW: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     n_pexpr_in_expr_name e4 (fun e4 ->
     k (wrap (M_RMW(ctype1, e2, e3, e4, mo1, mo2))))))
  | Fence0 mo1 -> 
     k (wrap (M_Fence mo1))
  | CompareExchangeStrong(e1, e2, e3, e4, mo1, mo2) ->
     let ctype1 = (fensure_ctype__pexpr loc "CompareExchangeStrong: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     n_pexpr_in_expr_name e4 (fun e4 ->
     k (wrap (M_CompareExchangeStrong(ctype1, e2, e3, e4, mo1, mo2))))))
  | CompareExchangeWeak(e1, e2, e3, e4, mo1, mo2) ->
     let ctype1 = (fensure_ctype__pexpr loc "CompareExchangeWeak: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     n_pexpr_in_expr_name e4 (fun e4 ->
     k (wrap (M_CompareExchangeWeak(ctype1, e2, e3, e4, mo1, mo2))))))
  | LinuxFence lmo ->
     k (wrap (M_LinuxFence lmo))
  | LinuxLoad(e1, e2, lmo) ->
     let ctype1 = (fensure_ctype__pexpr loc "LinuxLoad: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     k (wrap (M_LinuxLoad(ctype1, e2, lmo))))
  | LinuxStore(e1, e2, e3, lmo) ->
     let ctype1 = (fensure_ctype__pexpr loc "LinuxStore: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     k (wrap (M_LinuxStore(ctype1, e2, e3, lmo)))))
  | LinuxRMW(e1, e2, e3, lmo) ->
     let ctype1 = (fensure_ctype__pexpr loc "LinuxRMW: not a ctype" e1) in
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_name e3 (fun e3 ->
     k (wrap (M_LinuxRMW(ctype1, e2, e3, lmo)))))

     

let n_paction loc pa (k : mu_paction -> mu_expr) : (ct, bt, unit) Mucore.mu_expr= 
  let (Paction(pol, a)) = pa in
  let wrap a = M_Paction (pol, a) in
  n_action loc a (fun a -> 
  k (wrap a))





(* this is copied from what is probably originally a lem-inlined
   function from Mem_common or similar*)
let show_n_memop = function
  | Mem_common.PtrEq -> "ptreq"
  | Mem_common.PtrNe -> "ptrne"
  | Mem_common.PtrLt -> "ptrlt"
  | Mem_common.PtrGt -> "ptrgt"
  | Mem_common.PtrLe -> "ptrle"
  | Mem_common.PtrGe -> "ptrge"
  | Mem_common.Ptrdiff -> "ptrdiff"
  | Mem_common.IntFromPtr -> "intfromptr"
  | Mem_common.PtrFromInt -> "ptrfromint"
  | Mem_common.PtrValidForDeref -> "ptrvalidforderef"
  | Mem_common.PtrWellAligned -> "ptrwellaligned"
  | Mem_common.Memcpy -> "memcpy"
  | Mem_common.Memcmp -> "memcmp"
  | Mem_common.Realloc -> "realloc"
  | Mem_common.PtrArrayShift -> "ptrarrayshift"
  | Mem_common.Va_start -> "va_start"
  | Mem_common.Va_copy -> "va_copy"
  | Mem_common.Va_arg -> "va_arg"
  | Mem_common.Va_end -> "va_end"

let n_memop loc memop pexprs k:(ct, bt, unit) Mucore.mu_expr = 
  let n_pexpr_in_expr_name = n_pexpr_in_expr_name loc in
  let n_pexpr_in_expr_name_2 = n_pexpr_in_expr_name_2 loc in
  let n_pexpr_in_expr_name_3 = n_pexpr_in_expr_name_3 loc in

  match (memop, pexprs) with
  | (Mem_common.PtrEq, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrEq (sym1, sym2)))
  | (Mem_common.PtrNe, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrNe (sym1, sym2)))
  | (Mem_common.PtrLt, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrLt (sym1, sym2)))
  | (Mem_common.PtrGt, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrGt (sym1, sym2)))
  | (Mem_common.PtrLe, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrLe (sym1, sym2)))
  | (Mem_common.PtrGe, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrGe (sym1, sym2)))
  | (Mem_common.Ptrdiff, [ct1;pe1;pe2]) ->
     let ct1 = (fensure_ctype__pexpr loc "Ptrdiff: not a ctype" ct1) in
     n_pexpr_in_expr_name_2 (pe1, pe2) (fun (sym1,sym2) ->
     k (M_Ptrdiff (ct1, sym1, sym2)))
  | (Mem_common.IntFromPtr, [ct1;pe]) ->
     let ct1 = (fensure_ctype__pexpr loc "IntFromPtr: not a ctype" ct1) in
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_IntFromPtr (ct1, sym1)))
  | (Mem_common.PtrFromInt, [ct1;ct2;pe]) ->
     let ct1 = (fensure_ctype__pexpr loc "PtrFromInt: not a ctype" ct1) in
     let ct2 = (fensure_ctype__pexpr loc "PtrFromInt: not a ctype" ct2) in
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_PtrFromInt (ct1, ct2, sym1)))
  | (Mem_common.PtrValidForDeref, [ct1;pe]) ->
     let ct1 = (fensure_ctype__pexpr loc "PtrValidForDeref: not a ctype" ct1) in
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_PtrValidForDeref (ct1, sym1)))
  | (Mem_common.PtrWellAligned, [ct1;pe]) ->
     let ct1 = (fensure_ctype__pexpr loc "PtrWellAligned: not a ctype" ct1) in
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_PtrWellAligned (ct1, sym1)))
  | (Mem_common.PtrArrayShift, [pe1;ct1;pe2]) ->
     let ct1 = (fensure_ctype__pexpr loc "PtrArrayShift: not a ctype" ct1) in
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_PtrArrayShift (sym1 ,ct1, sym2)))
  | (Mem_common.Memcpy, [pe1;pe2;pe3]) ->
     n_pexpr_in_expr_name_3 (pe1,pe2,pe3) (fun (sym1,sym2,sym3) ->
     k (M_Memcpy (sym1 ,sym2, sym3)))
  | (Mem_common.Memcmp, [pe1;pe2;pe3]) ->
     n_pexpr_in_expr_name_3 (pe1,pe2,pe3) (fun (sym1,sym2,sym3) ->
     k (M_Memcmp (sym1 ,sym2, sym3)))
  | (Mem_common.Realloc, [pe1;pe2;pe3]) ->
     n_pexpr_in_expr_name_3 (pe1,pe2,pe3) (fun (sym1,sym2,sym3) ->
     k (M_Realloc (sym1 ,sym2, sym3)))
  | (Mem_common.Va_start, [pe1;pe2]) ->
     n_pexpr_in_expr_name_2 (pe1,pe2) (fun (sym1,sym2) ->
     k (M_Va_start (sym1 ,sym2)))
  | (Mem_common.Va_copy, [pe]) ->
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_Va_copy sym1))
  | (Mem_common.Va_arg, [pe;ct1]) ->
     let ct1 = (fensure_ctype__pexpr loc "Va_arg: not a ctype" ct1) in
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_Va_arg (sym1 ,ct1)))
  | (Mem_common.Va_end, [pe]) ->
     n_pexpr_in_expr_name pe (fun sym1 ->
     k (M_Va_end sym1))
  | (memop, pexprs1) ->
     let err = 
       show_n_memop memop ^ 
         " applied to " ^ 
           string_of_int (List.length pexprs1) ^ 
             " arguments"
     in
     error err


let rec normalise_expr loc e : (ctype, core_base_type, unit) Mucore.mu_expr =
  n_expr loc e (fun e -> e)

and n_expr loc (e : ('a, unit) expr) (k : mu_expr -> mu_expr) : mu_expr = 
  let (Expr (annots, pe)) = e in
  let wrap pe : mu_expr =  M_Expr (annots, pe) in
  let loc = update_loc loc (get_loc_ annots) in
  let n_pexpr_in_expr_name = (n_pexpr_in_expr_name loc) in
  let n_pexpr_in_expr_names = (n_pexpr_in_expr_names loc) in
  let n_pexpr_in_expr = (n_pexpr_in_expr loc) in
  let n_paction = (n_paction loc) in
  let n_memop = (n_memop loc) in
  let n_expr = (n_expr loc) in
  let normalise_expr = normalise_expr loc in
  match pe with
  | Epure pexpr2 -> 
     n_pexpr_in_expr pexpr2 (fun e -> 
     k (wrap (M_Epure e)))
  | Ememop(memop1, pexprs1) -> 
     n_memop memop1 pexprs1 (fun memop1 ->
     k (wrap (M_Ememop memop1)))
  | Eaction paction2 ->
     n_paction paction2 (fun paction2 ->
     k (wrap (M_Eaction paction2)))
  | Ecase(pexpr2, pats_es) ->
     n_pexpr_in_expr_name pexpr2 (fun pexpr2 ->
         let pats_es = 
           (map (fun (pat,e) -> 
               let pat = (core_to_mu__pattern loc pat) in
               let pe = (n_expr e k) in
               (pat, pe)
            ) 
             pats_es) 
         in
         wrap (M_Ecase(pexpr2, pats_es))
    )
  | Elet(pat, e1, e2) ->
     n_pexpr_in_expr e1 (fun e1 ->
     wrap (M_Elet((M_Pat (core_to_mu__pattern loc pat)),
             e1, (n_expr e2 k))))
  | Eif(e1, e2, e3) ->
     if always_explode_eif || Annot.explode annots then
       n_pexpr_in_expr_name e1 (fun e1 ->
       let e2 = (n_expr e2 k) in
       let e3 = (n_expr e3 k) in
       wrap (M_Eif(e1, e2, e3)))
     else
       n_pexpr_in_expr_name e1 (fun e1 ->
       let e2 = (normalise_expr e2) in
       let e3 = (normalise_expr e3) in
       k (wrap (M_Eif(e1, e2, e3))))
  | Eskip ->
     k (wrap (M_Eskip))
  | Eccall(_a, ct1, e2, es) ->
     let ct1 = ((match ct1 with
       | Core.Pexpr(annots, bty, (Core.PEval (Core.Vctype ct1))) -> 
          (a_pack annots bty ct1)
       | _ -> error "core_anormalisation: Eccall with non-ctype first argument"
    )) in
     (* n_pexpr_in_expr_name e1 (fun e1 -> *)
     n_pexpr_in_expr_name e2 (fun e2 ->
     n_pexpr_in_expr_names es (fun es ->
     k (wrap (M_Eccall(ct1, e2, es)))))
  | Eproc(_a, name1, es) ->
     n_pexpr_in_expr_names es (fun es ->
     k (wrap (M_Eproc(name1, es))))
  | Eunseq es ->
     error "core_anormalisation: Eunseq"
  | Ewseq(pat, e1, e2) ->
     n_expr e1 (fun e1 ->
     wrap (M_Ewseq(core_to_mu__pattern loc pat, e1, n_expr e2 k)))
  | Esseq(pat, e1, e2) ->
     n_expr e1 (fun e1 ->
     wrap (M_Esseq(core_to_mu__pattern loc pat, e1, n_expr e2 k)))
  | Easeq(b, action3, paction2) ->
     error "core_anormalisation: Easeq"
  | Eindet(n, e) ->
     error "core_anormalisation: Eindet"
  | Ebound(n, e) ->
     wrap (M_Ebound(n, (n_expr e k)))
  | End es ->
     let es = (map normalise_expr es) in
     k (wrap (M_End es))
  | Esave((sym1,bt1), syms_typs_pes, e) ->  (* have to check *)
     let (_,typs_pes) = (List.split syms_typs_pes) in
     let (_,pes) = (List.split typs_pes) in
     n_pexpr_in_expr_names pes (fun pes ->
     k (wrap (M_Erun(sym1, pes))))
  | Erun(_a, sym1, pes) ->
     n_pexpr_in_expr_names pes (fun pes ->
     k (wrap (M_Erun(sym1, pes))))
  | Epar es -> 
     error "core_anormalisation: Epar"
  | Ewait tid1 ->
     error "core_anormalisation: Ewait"




let normalise_impl_decl (i : unit generic_impl_decl) : (ct, bt, unit) mu_impl_decl =
  match i with
  | Def(bt1, p) -> 
     M_Def (bt1, normalise_pexpr Loc.unknown pexpr_n_pexpr_domain p)
  | IFun(bt1, args, body) -> 
     M_IFun (bt1, args, normalise_pexpr Loc.unknown pexpr_n_pexpr_domain body)

let normalise_impl (i : unit generic_impl) : (ct, bt, unit) mu_impl=
   (Pmap.map normalise_impl_decl i)

let normalise_fun_map_decl 
      (name1: symbol)
      (d : (unit, 'a) generic_fun_map_decl) 
    : (lt, ct, bt, unit) mu_fun_map_decl=
  match d with
  | Fun (bt1, args, pe) -> 
     M_Fun(bt1, args, normalise_pexpr Loc.unknown pexpr_n_pexpr_domain pe)
  | Proc (loc, bt1, args, e) -> 
     let saves = (Core_aux.m_collect_saves e) in
     let saves' =
       (Pmap.map (fun (_,params,body,annots2) ->
            let param_tys = 
              (map (fun (sym1,(((_,mctb),_))) -> 
                   (match mctb with
                    | Some (ct1,b) -> (Some sym1, (ct1,b))
                    | None -> 
                       error "core_anormalisation: label without c-type argument annotation"
                   )
                 ) params) 
            in
            let params = (map (fun (sym1,(((bt1,_),_))) -> (sym1,bt1)) params) in
            if is_return annots2
            then M_Return param_tys
            else M_Label(param_tys, params, normalise_expr loc body, annots2)
          ) saves)
     in
     M_Proc(loc, bt1, args, normalise_expr loc e, saves')
  | ProcDecl(loc, bt1, bts) -> M_ProcDecl(loc, bt1, bts)
  | BuiltinDecl(loc, bt1, bts) -> M_BuiltinDecl(loc, bt1, bts)

let normalise_fun_map (fmap1 : (unit, 'a) generic_fun_map) : (lt, ct, bt, unit) mu_fun_map= 
   (Pmap.mapi normalise_fun_map_decl fmap1)
  

let normalise_globs (g : ('a, unit) generic_globs) : (ct, bt, unit) mu_globs= 
  match g with
  | GlobalDef(bt1, e) -> M_GlobalDef(bt1, normalise_expr Loc.unknown e)
  | GlobalDecl bt1 -> M_GlobalDecl bt1 


let normalise_globs_list (gs : (Symbol.sym * ('a, unit) generic_globs) list)
    : (Symbol.sym * (ct, bt, unit) mu_globs) list= 
   (map (fun (sym1,g) -> (sym1, normalise_globs g)) gs)



let normalise_tag_definition = function
  | StructDef(l, mf) -> M_StructDef (l, mf)
  | UnionDef l -> M_UnionDef l


let normalise_tag_definitions tagDefs =
   (Pmap.map normalise_tag_definition tagDefs)

let normalise_funinfo (loc,annots2,ret,args,b1,b2) = 
  let args = 
    map (fun (osym, ct) -> 
        match osym with 
        | Some sym -> (sym, ct)
        | None -> (Symbol.fresh (), ct)
      ) args 
  in
   (M_funinfo (loc,annots2,(ret,args),b1,b2))

let normalise_funinfos funinfos =
   (Pmap.map normalise_funinfo funinfos)


let rec ctype_contains_function_pointer (Ctype.Ctype (_, ct_)) = 
  match ct_ with
  | Void -> false
  | Basic _ -> false
  | Array (ct, _) -> ctype_contains_function_pointer ct
  | Function _ -> true
  | Pointer (_, ct) -> ctype_contains_function_pointer ct
  | Atomic ct -> ctype_contains_function_pointer ct
  | Struct _ -> false
  | Union _ -> false


let check_supported file =
  let _ = 
    Pmap.iter (fun _sym def -> 
        let (loc, _attrs, ret_ctype, args,  variadic, _) = def in
        if ctype_contains_function_pointer ret_ctype ||
             List.exists (fun (_,ct) -> ctype_contains_function_pointer ret_ctype) args
        then 
          let err = Errors.UNSUPPORTED "function pointers" in
          Pp_errors.fatal (Pp_errors.to_string (loc, err)); 
        else if variadic then
          let err = Errors.UNSUPPORTED "variadic functions" in
          Pp_errors.fatal (Pp_errors.to_string (loc, err)); 
        else
          ()
      ) file.funinfo
  in
  let _ = 
    Pmap.iter (fun _sym def -> 
        match def with
        | Ctype.StructDef (members, flexible_array_members) ->
           if List.exists (fun (_,(_,_,ct)) -> ctype_contains_function_pointer ct) members 
           then 
             let err = Errors.UNSUPPORTED "function pointers" in
             Pp_errors.fatal (Pp_errors.to_string (Loc.unknown, err)); 
           else if flexible_array_members <> None then
             let err = Errors.UNSUPPORTED "function pointers" in
             Pp_errors.fatal (Pp_errors.to_string (Loc.unknown, err)); 
           else ()
        | Ctype.UnionDef members ->
           if List.exists (fun (_,(_,_,ct)) -> ctype_contains_function_pointer ct) members 
           then 
             let err = Errors.UNSUPPORTED "function pointers" in
             Pp_errors.fatal (Pp_errors.to_string (Loc.unknown, err)); 
           else ()
      ) file.tagDefs
  in
  ()

let normalise_file file : (ft, lt, ct, bt, st, ut, unit) Mucore.mu_file = 
  check_supported file;
   ({ mu_main = (file.main)
   ; mu_tagDefs = (normalise_tag_definitions file.tagDefs)
   ; mu_stdlib = (normalise_fun_map file.stdlib)
   ; mu_impl = (normalise_impl file.impl)
   ; mu_globs = (normalise_globs_list file.globs)
   ; mu_funs = (normalise_fun_map file.funs)
   ; mu_extern = (file.extern)
   ; mu_funinfo = (normalise_funinfos file.funinfo)
   ; mu_loop_attributes = file.loop_attributes0
  })


end
