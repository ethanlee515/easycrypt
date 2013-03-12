(* -------------------------------------------------------------------- *)
open EcMaps
open EcSymbols

(* -------------------------------------------------------------------- *)
type ident = private {
  id_symb : symbol;
  id_tag  : int;
}

type t = ident

val create   : symbol -> t
val fresh    : t -> t
val name     : t -> symbol
val tag      : t -> int
val tostring : t -> string

(* -------------------------------------------------------------------- *)
val id_equal : t -> t -> bool
val id_compare : t -> t -> int 
val id_hash : t -> int

(* -------------------------------------------------------------------- *)
module Mid : Map.S with type key = t
module Sid : Mid.Set with type elt = t

(* -------------------------------------------------------------------- *)
val fv_singleton : ident -> int Mid.t
val fv_union     : int Mid.t -> int Mid.t -> int Mid.t
val fv_diff      : int Mid.t -> 'a Mid.t -> int Mid.t 
val fv_add       : ident -> int Mid.t -> int Mid.t 

(* -------------------------------------------------------------------- *)
val pp_ident : t EcFormat.pp
