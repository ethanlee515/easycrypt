(* -------------------------------------------------------------------- *)
require import AllCore List Ring StdOrder Quotient Bigalg Binomial.
(*---*) import IntOrder.

(* ==================================================================== *)
abstract theory Ideal.
(* -------------------------------------------------------------------- *)
type t.

clone import IDomain as Domain with type t <- t.
clear [Domain.* Domain.AddMonoid.* Domain.MulMonoid.*].

clone import Bigalg.BigComRing as BigDom with
  type  t        <- t,
    op  CR.zeror <- Domain.zeror,
    op  CR.oner  <- Domain.oner,
    op  CR.(+)   <- Domain.(+),
    op  CR.([-]) <- Domain.([-]),
    op  CR.( * ) <- Domain.( * ),
    op  CR.invr  <- Domain.invr,
  pred  CR.unit  <- Domain.unit
  proof CR.*

  remove abbrev CR.(-)
  remove abbrev CR.(/).

realize CR.addrA     by exact: Domain.addrA    .
realize CR.addrC     by exact: Domain.addrC    .
realize CR.add0r     by exact: Domain.add0r    .
realize CR.addNr     by exact: Domain.addNr    .
realize CR.oner_neq0 by exact: Domain.oner_neq0.
realize CR.mulrA     by exact: Domain.mulrA    .
realize CR.mulrC     by exact: Domain.mulrC    .
realize CR.mul1r     by exact: Domain.mul1r    .
realize CR.mulrDl    by exact: Domain.mulrDl   .
realize CR.mulVr     by exact: Domain.mulVr    .
realize CR.unitP     by exact: Domain.unitP    .
realize CR.unitout   by exact: Domain.unitout  .

clear [BigDom.* BigDom.CR.* BigDom.BAdd.* BigDom.BMul.*].

(* -------------------------------------------------------------------- *)
abbrev "_.[_]" (xs : t list) (i : int) = nth zeror xs i.

(* -------------------------------------------------------------------- *)
op (%|) (x y : t) = (exists c, y = c * x).
op (%=) (x y : t) = (x %| y) /\ (y %| x).

(* -------------------------------------------------------------------- *)
lemma dvdrP x y : (x %| y) <=> (exists q, y = q * x).
proof. by rewrite /(%|). qed.

(* -------------------------------------------------------------------- *)
op ideal (I : t -> bool) =
     I zeror
  /\ (forall x y, I x => I y => I (x - y))
  /\ (forall a x, I x => I (a * x)).

lemma idealP (I : t -> bool) :
    I zeror
 => (forall x y, I x => I y => I (x - y))
 => (forall a x, I x => I (a * x))
 => ideal I.
proof. by move=> *; do! split. qed.

lemma idealW (P : (t -> bool) -> bool) :
  (forall I,
        I zeror
     => (forall (x y : t), I x => I y => I (x - y))
     => (forall a x, I x => I (a * x))
     => P I)
  => forall i, ideal i => P i.
proof. by move=> ih i [? [??]]; apply: ih. qed.

lemma ideal0 I : ideal I => I zeror.
proof. by case. qed.

lemma idealN I x : ideal I => I x => I (- x).
proof.
move=> ^iI [_ [+ _]] Ix - /(_ zeror x); rewrite sub0r.
by apply=> //; apply/ideal0.
qed.

lemma idealNP I (x : t) : ideal I => I (- x) = I x.
proof.
move=> iI; apply/eq_iff; split; last exact: idealN.
by rewrite -{2}(opprK x); apply: idealN.
qed.

lemma idealD I x y : ideal I => I x => I y => I (x + y).
proof.
move=> ^iI [_ [+ _] Ix Iy] - /(_ x (-y)); rewrite opprK.
by apply=> //; apply/idealN.
qed.

lemma idealB I x y : ideal I => I x => I y => I (x - y).
proof. by move=> iI Ix Iy; rewrite idealD -1:idealN. qed.

lemma idealMl I x y : ideal I => I y => I (x * y).
proof. by case=> _ [_ +]; apply. qed.

lemma idealMr I x y : ideal I => I x => I (x * y).
proof. by move=> iI Ix; rewrite mulrC; apply: idealMl. qed.

(* -------------------------------------------------------------------- *)
op id0 = pred1<:t> zeror.
op idT = predT<:t>.
op idI = predI<:t>.

op idD (I J : t -> bool) : t -> bool =
  fun x => exists i j, (I i /\ J j) /\ x = i + j.

op idR (I : t -> bool) : t -> bool =
  fun x => exists n, 0 <= n /\ I (Domain.exp x n).

(* -------------------------------------------------------------------- *)
lemma mem_id0 x : id0 x <=> x = zeror.
proof. by []. qed.

(* -------------------------------------------------------------------- *)
lemma ideal_id0 : ideal id0.
proof.
rewrite /id0 /pred1; apply/idealP => //.
- by move=> x y -> -> /=; rewrite subrr.
- by move=> a x -> /=; rewrite mulr0.
qed.

(* -------------------------------------------------------------------- *)
lemma ideal_idT : ideal idT.
proof. by []. qed.

(* -------------------------------------------------------------------- *)
lemma ideal_idI I J : ideal I => ideal J => ideal (idI I J).
proof.
move=> iI iJ @/idI @/predI; apply/idealP => //=.
- by rewrite !ideal0.
- by move=> x y [Ix Jx] [Iy Jy]; rewrite !idealB.
- by move=> a x [Ix Jx]; rewrite !idealMl.
qed.

(* -------------------------------------------------------------------- *)
lemma ideal_idD I J : ideal I => ideal J => ideal (idD I J).
proof.
move=> iI iJ; apply/idealP.
- by exists zeror zeror; rewrite addr0 !ideal0.
- move=> _ _ [xi xj [[Ixi Jxj] ->]] [yi yj [[Iyi Jyj] ->]].
  by rewrite subrACA; exists (xi - yi) (xj - yj) => /=; rewrite !idealB.
- move=> a _ [i j [[Ii Jj] ->]]; rewrite mulrDr.
  by exists (a * i) (a * j) => /=; rewrite !idealMl.
qed.

(* -------------------------------------------------------------------- *)
lemma idDC I J : idD I J = idD J I.
proof.
apply/fun_ext=> x @/idD; apply: eq_iff; split; 
  by case=> i j [? ->]; exists j i; rewrite addrC /= andbC.
qed.

lemma mem_idDl I J x : I x => ideal J => (idD I J) x.
proof.
by move=> Ix iJ; exists x zeror; rewrite Ix addr0 ideal0.
qed.

lemma mem_idDr I J x : J x => ideal I => (idD I J) x.
proof.
by move=> Jx iI; rewrite idDC; apply: mem_idDl.
qed.

(* -------------------------------------------------------------------- *)
op idgen (xs : t list) = fun (x : t) =>
  exists cs, x = BAdd.bigi predT (fun i => cs.[i] * xs.[i]) 0 (size xs).

lemma idgenP (xs : t list) (x : t) :
  idgen xs x => exists cs, size cs = size xs
    /\ x = BAdd.bigi predT (fun i => cs.[i] * xs.[i]) 0 (size xs).
proof.
case=> cs ->; exists (mkseq (fun i => cs.[i]) (size xs)); split.
- by rewrite size_mkseq ler_maxr // size_ge0.
rewrite !BAdd.big_seq &(BAdd.eq_bigr) /= => i /mem_range rg_i.
by rewrite nth_mkseq.
qed.

lemma ideal_idgen (xs : t list) : ideal (idgen xs).
proof. do! split.
- by exists []; rewrite BAdd.big1 //= => i _; rewrite mul0r.
- move=> x y /idgenP[cxs [szx ->]] /idgenP[cys [szy ->]].
  rewrite BAdd.sumrB /=; exists (mkseq (fun i => cxs.[i] - cys.[i]) (size xs)).
  rewrite !BAdd.big_seq &(BAdd.eq_bigr) /= => i /mem_range rg_i.
  by rewrite nth_mkseq //= mulrBl.
- move=> a x /idgenP[cs [sz ->]]; exists (mkseq (fun i => a * cs.[i]) (size xs)).
  rewrite BAdd.mulr_sumr !BAdd.big_seq &(BAdd.eq_bigr) /=.
  by move=> i /mem_range rg_i; rewrite nth_mkseq //= mulrA.
qed.

hint exact : ideal_idgen.

lemma mem_idgen1 x a : idgen [x] a <=> exists b, a = b * x.
proof. split => [/idgenP /= [cs]|].
- by case=> [/size_eq1[c ->] ->]; exists c; rewrite BAdd.big_int1.
- by case=> c ->; exists [c] => /=; rewrite BAdd.big_int1.
qed.

lemma mem_idgen1_gen x : idgen [x] x.
proof.
by rewrite mem_idgen1; exists oner; rewrite mul1r.
qed.

(* -------------------------------------------------------------------- *)
lemma le_idDl (I1 I2 J : t -> bool) :
  ideal J => I1 <= J => I2 <= J => idD I1 I2 <= J.
proof.
move=> iJ le1 le2 x [x1 x2 [+ ->]].
by case=> [/le1 Jx1 /le2 Jx2]; apply: idealD.
qed.

(* -------------------------------------------------------------------- *)
op principal (I : t -> bool) =
  exists a : t, forall x, (I x <=> exists b, x = b * a).

lemma principal_ideal I : principal I => ideal I.
proof.
case=> a inI; suff ->: I = idgen [a] by apply/ideal_idgen.
by apply/fun_ext=> x; rewrite inI -mem_idgen1.
qed.

lemma principal_idgen1 x : principal (idgen [x]).
proof. by exists x=> y; rewrite mem_idgen1. qed.

lemma idgen1_0 : idgen [zeror] = id0.
proof.
apply/fun_ext=> x; rewrite mem_id0 mem_idgen1.
apply/eq_iff; split=> [[b ->]|->].
- by rewrite mulr0.
- by exists zeror; rewrite mulr0.
qed.

lemma principalP I : principal I <=> exists d, I = idgen [d].
proof.
split=> [|[d ->]]; last by apply/principal_idgen1.
by case=> d IE; exists d; apply/fun_ext => x; rewrite IE mem_idgen1.
qed.

lemma principal_id0 : principal id0.
proof. by rewrite -idgen1_0 &(principal_idgen1). qed.

(* -------------------------------------------------------------------- *)
lemma mem_idgen1_dvd x y : idgen [x] y <=> x %| y.
proof. by rewrite mem_idgen1 -dvdrP. qed.

lemma le_idgen1_dvd x y : x %| y <=> idgen [y] <= idgen [x].
proof.
split=> [[c ->>] y /mem_idgen1_dvd [d ->]|].
- by rewrite mulrA mem_idgen1_dvd; exists (d * c).
- move/(_ y); rewrite !mem_idgen1_dvd; apply.
  by exists oner; rewrite mul1r.
qed.

lemma in_idgen_mem xs x : x \in xs => idgen xs x.
proof.
admitted.

(* -------------------------------------------------------------------- *)
lemma dvdrr x : x %| x.
proof. by rewrite -mem_idgen1_dvd mem_idgen1_gen. qed.

lemma dvdr_mull d x y : d %| y => d %| x * y.
proof.
rewrite -!mem_idgen1_dvd => ?; apply/(@idealMl (idgen [d])) => //.
by apply: ideal_idgen.
qed.

lemma dvdr_mulr d x y : d %| x => d %| x * y.
proof. by move=> dx; rewrite mulrC dvdr_mull. qed.

lemma dvdr_trans : transitive (%|).
proof.
move=> z x y; rewrite !le_idgen1_dvd => h1 h2.
by apply: (subpred_trans _ _ _ h2 h1).
qed.

lemma dvdr0 x : x %| zeror.
proof. by exists zeror; rewrite mul0r. qed.

lemma dvd0r x : (zeror %| x) <=> (x = zeror).
proof.
split=> [|->]; last by exists zeror; rewrite mulr0.
by case=> ?; rewrite mulr0.
qed.

lemma eqmodP x y : (x %= y) <=> (exists u, unit u /\ x = u * y).
proof.
split=> [[dxy dyx]|[u [invu ->]]]; last first.
- rewrite /(%=) dvdr_mull 1:dvdrr /=; apply/dvdrP.
  by exists (invr u); rewrite mulrA mulVr // mul1r.
case: (y = zeror) => [->>|nz_y].
- rewrite (_ : x = zeror) 1:-dvd0r //.
  by exists oner; rewrite mul1r /= unitr1.
case/dvdrP: dyx=> u xE; exists u; rewrite xE eq_refl /=.
apply/unitrP; case/dvdrP: dxy=> v yE; exists v.
by apply: (mulIf y) => //; rewrite mul1r -mulrA -xE yE.
qed.

lemma idgen_mulVl x y : unit x => idgen [x * y] = idgen [y].
proof.
move=> invx; apply/fun_ext=> z; apply/eq_iff.
apply: subpred_eqP z => /=; split.
- by apply/le_idgen1_dvd/dvdr_mull/dvdrr.
move=> z /mem_idgen1[c ->]; apply/mem_idgen1.
by exists (c * invr x); rewrite !mulrA mulrVK.
qed.

lemma eqmod_idP x y : (x %= y) <=> (idgen [x] = idgen [y]).
proof.
split; first by case/eqmodP=> [u [invu ->]]; rewrite idgen_mulVl.
move=> eq; have: idgen[x] <= idgen[y] /\ idgen[y] <= idgen[x].
- by apply/subpred_eqP=> z; rewrite eq.
by case=> /le_idgen1_dvd dyx /le_idgen1_dvd dxy.
qed.

(* -------------------------------------------------------------------- *)
lemma eqp_refl x : x %= x.
proof. by rewrite eqmod_idP. qed.

lemma eqp_sym x y : x %= y => y %= x.
proof. by rewrite !eqmod_idP eq_sym. qed.

lemma eqp_trans y x z : x %= y => y %= z => x %= z.
proof. by rewrite !eqmod_idP => <-. qed.

lemma eqp0P x : (x %= zeror) <=> (x = zeror).
proof.
split=> [/eqmodP[u [_ ->]]|]; first by rewrite mulr0.
by move=> ->; apply/eqp_refl.
qed.
end Ideal.

(* ==================================================================== *)
abstract theory RingQuotient.
type b, t.

clone import IDomain as IDomain with type t <- b.
clear [IDomain.* IDomain.AddMonoid.* IDomain.MulMonoid.*].

clone import Ideal with
  type t <- b,
  pred Domain.unit   <- IDomain.unit,
    op Domain.zeror  <- IDomain.zeror,
    op Domain.oner   <- IDomain.oner,
    op Domain.( + )  <- IDomain.( + ),
    op Domain.([-])  <- IDomain.([-]),
    op Domain.( * )  <- IDomain.( * ),
    op Domain.invr   <- IDomain.invr,
    op Domain.intmul <- IDomain.intmul,
    op Domain.ofint  <- IDomain.ofint,
    op Domain.exp    <- IDomain.exp

  proof * by smt(@IDomain)

  remove abbrev Domain.(-)
  remove abbrev Domain.(/).

(* -------------------------------------------------------------------- *)
op p : b -> bool.

axiom ideal_p : ideal p.
axiom ideal_Ntriv : forall x, unit x => !p x.

hint exact : ideal_p.

op rel (x y : b) = p (y - x).

lemma relxx : reflexive rel.
proof. by move=> x @/rel; rewrite /rel subrr ideal0 ideal_p. qed.

lemma rel_sym : symmetric rel.
proof. by move=> x y @/rel; rewrite -opprB idealNP // ideal_p. qed.

lemma rel_trans : transitive rel.
proof.
move=> y x z @/rel hpyx hpzy.
have ->: z - x = (z - y) + (y - x).
- by rewrite addrACA !addrA addrK.
by apply/idealD => //; apply/ideal_p.
qed.

hint exact : relxx.

(* -------------------------------------------------------------------- *)
lemma rel0r x : rel x zeror <=> p x.
proof. by rewrite rel_sym /rel subr0. qed.

lemma rel0l x : rel zeror x <=> p x.
proof. by rewrite rel_sym &(rel0r). qed.

lemma relN x y : rel x y => rel (-x) (-y).
proof. by rewrite /rel -idealNP 1:ideal_p opprD. qed.

lemma relD x1 x2 y1 y2 : rel x1 x2 => rel y1 y2 => rel (x1 + y1) (x2 + y2).
proof. by rewrite /rel subrACA &(idealD) ideal_p. qed.

lemma relMl x y1 y2 : rel y1 y2 => rel (x * y1) (x * y2).
proof. by rewrite /rel -mulrBr &(idealMl) ideal_p. qed.

lemma relMr x1 x2 y : rel x1 x2 => rel (x1 * y) (x2 * y).
proof. by rewrite !(mulrC _ y) &(relMl). qed.

(* -------------------------------------------------------------------- *)
clone import Quotient.EquivQuotient
  with type T   <- b,
       type qT  <- t,
         op eqv <- rel

   proof EqvEquiv.*.

realize EqvEquiv.eqv_refl  by apply: relxx.
realize EqvEquiv.eqv_sym   by apply: rel_sym.
realize EqvEquiv.eqv_trans by apply: rel_trans.

(* -------------------------------------------------------------------- *)
op zeror = pi zeror.
op oner  = pi oner.

op ( + ) (x y : t) = pi (repr x + repr y).
op [ - ] (x   : t) = pi (- repr x).
op ( * ) (x y : t) = pi (repr x * repr y).

op   invr : t -> t.
pred unit : t.

lemma addE x y : (pi x) + (pi y) = pi (x + y).
proof.
rewrite /(+) &(eqv_pi) /rel subrACA.
by rewrite &(idealD) ?ideal_p // &(eqv_repr).
qed.

lemma oppE x : -(pi x) = pi (-x).
proof.
rewrite /([-]) &(eqv_pi) /rel opprK addrC.
by rewrite -/(rel _ _) rel_sym &(eqv_repr).
qed.

lemma mulE x y : (pi x) * (pi y) = pi (x * y).
proof.
rewrite /(+) &(eqv_pi) /rel; pose z := repr (pi x).
have ->: x = x - z + z by rewrite subrK.
rewrite mulrDl -addrA -mulrBr (mulrC _ y) {1}/z.
by rewrite &(idealD) ?ideal_p // idealMl ?ideal_p &(eqv_repr).
qed.

axiom mulVr   : left_inverse_in unit oner invr ( * ).
axiom unitP   : forall (x y : t), y * x = oner => unit x.
axiom unitout : forall (x : t), !unit x => invr x = x.

clone import ComRing with
  type t     <- t    ,
  op   zeror <- zeror,
  op   ( + ) <- (+)  ,
  op   [ - ] <- [-]  ,
  op   oner  <- oner ,
  op   ( * ) <- ( * ),
  op   invr  <- invr ,
  pred unit  <- unit

  proof *.

realize addrA.
proof.
elim/quotW=> x; elim/quotW=> y; elim/quotW=> z.
by rewrite !addE &(eqv_pi) !addrA !relD // 1:rel_sym &(eqv_repr).
qed.

realize addrC.
proof.
by elim/quotW=> x; elim/quotW=> y; rewrite !addE addrC.
qed.

realize add0r.
proof. by elim/quotW=> x; rewrite !addE add0r. qed.

realize addNr.
proof.
elim/quotW=> x; rewrite !addE &(eqv_pi) addrC.
by apply/rel0r/eqv_repr.
qed.

realize oner_neq0.
proof. by rewrite -eqv_pi rel0r; apply/ideal_Ntriv/unitr1. qed.

realize mulrA.
proof.
elim/quotW=> x; elim/quotW=> y; elim/quotW=> z.
rewrite !mulE &(eqv_pi) !mulrA.
apply: (rel_trans (x * (repr (pi y)) * z)).
- by apply/relMl/eqv_repr.
- by apply/relMr/relMr; rewrite rel_sym &(eqv_repr).
qed.

realize mulrC.
proof. by elim/quotW=> x; elim/quotW=> y; rewrite !mulE mulrC. qed.

realize mul1r.
proof. by elim/quotW=> x; rewrite mulE mul1r. qed.

realize mulrDl.
proof.
elim/quotW=> x1; elim/quotW=> x2; elim/quotW=> y.
rewrite !(addE, mulE) &(eqv_pi) -mulrDl.
apply: (rel_trans ((x1 + x2) * (repr (pi y)))).
- by apply/relMl; rewrite rel_sym &(eqv_repr).
- by apply/relMr/relD; rewrite rel_sym &(eqv_repr).
qed.

realize mulVr   by apply: mulVr.
realize unitP   by apply: unitP.
realize unitout by apply: unitout.
end RingQuotient.