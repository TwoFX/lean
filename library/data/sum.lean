-- Copyright (c) 2014 Microsoft Corporation. All rights reserved.
-- Released under Apache 2.0 license as described in the file LICENSE.
-- Author: Leonardo de Moura, Jeremy Avigad
import logic.core.prop logic.core.inhabited logic.core.decidable
open inhabited decidable eq_ops
-- data.sum
-- ========
-- The sum type, aka disjoint union.

inductive sum (A B : Type) : Type :=
  inl : A → sum A B,
  inr : B → sum A B

namespace sum
  infixr `⊎` := sum
  namespace extra_notation
    infixr `+`:25 := sum    -- conflicts with notation for addition
  end extra_notation

  protected definition rec_on {A B : Type} {C : (A ⊎ B) → Type} (s : A ⊎ B)
    (H1 : ∀a : A, C (inl B a)) (H2 : ∀b : B, C (inr A b)) : C s :=
  rec H1 H2 s

  protected definition cases_on {A B : Type} {P : (A ⊎ B) → Prop} (s : A ⊎ B)
    (H1 : ∀a : A, P (inl B a)) (H2 : ∀b : B, P (inr A b)) : P s :=
  rec H1 H2 s

  -- Here is the trick for the theorems that follow:
  -- Fixing a1, "f s" is a recursive description of "inl B a1 = s".
  -- When s is (inl B a1), it reduces to a1 = a1.
  -- When s is (inl B a2), it reduces to a1 = a2.
  -- When s is (inr A b), it reduces to false.

  theorem inl_inj {A B : Type} {a1 a2 : A} (H : inl B a1 = inl B a2) : a1 = a2 :=
  let f := λs, rec_on s (λa, a1 = a) (λb, false) in
  have H1 : f (inl B a1), from rfl,
  have H2 : f (inl B a2), from H ▸ H1,
  H2

  theorem inl_neq_inr {A B : Type} {a : A} {b : B} (H : inl B a = inr A b) : false :=
  let f := λs, rec_on s (λa', a = a') (λb, false) in
  have H1 : f (inl B a), from rfl,
  have H2 : f (inr A b), from H ▸ H1,
  H2

  theorem inr_inj {A B : Type} {b1 b2 : B} (H : inr A b1 = inr A b2) : b1 = b2 :=
  let f := λs, rec_on s (λa, false) (λb, b1 = b) in
  have H1 : f (inr A b1), from rfl,
  have H2 : f (inr A b2), from H ▸ H1,
  H2

  protected theorem is_inhabited_left [instance] {A B : Type} (H : inhabited A) : inhabited (A ⊎ B) :=
  inhabited.mk (inl B (default A))

  protected theorem is_inhabited_right [instance] {A B : Type} (H : inhabited B) : inhabited (A ⊎ B) :=
  inhabited.mk (inr A (default B))

  protected definition has_eq_decidable [instance] {A B : Type} (H1 : decidable_eq A) (H2 : decidable_eq B) :
       decidable_eq (A ⊎ B) :=
  take s1 s2 : A ⊎ B,
    rec_on s1
      (take a1, show decidable (inl B a1 = s2), from
        rec_on s2
          (take a2, show decidable (inl B a1 = inl B a2), from
            decidable.rec_on (H1 a1 a2)
              (assume Heq : a1 = a2, decidable.inl (Heq ▸ rfl))
              (assume Hne : a1 ≠ a2, decidable.inr (mt inl_inj Hne)))
          (take b2,
            have H3 : (inl B a1 = inr A b2) ↔ false,
              from iff.intro inl_neq_inr (assume H4, false_elim H4),
            show decidable (inl B a1 = inr A b2), from decidable_iff_equiv _ (iff.symm H3)))
      (take b1, show decidable (inr A b1 = s2), from
        rec_on s2
          (take a2,
            have H3 : (inr A b1 = inl B a2) ↔ false,
              from iff.intro (assume H4, inl_neq_inr (H4⁻¹)) (assume H4, false_elim H4),
            show decidable (inr A b1 = inl B a2), from decidable_iff_equiv _ (iff.symm H3))
          (take b2, show decidable (inr A b1 = inr A b2), from
            decidable.rec_on (H2 b1 b2)
              (assume Heq : b1 = b2, decidable.inl (Heq ▸ rfl))
              (assume Hne : b1 ≠ b2, decidable.inr (mt inr_inj Hne))))
end sum
