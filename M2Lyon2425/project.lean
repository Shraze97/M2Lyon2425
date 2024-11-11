import Mathlib.Data.Set.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Topology.Defs.Basic
import Mathlib.Topology.Constructions
import Mathlib.Topology.Instances.EReal
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.SetTheory.Cardinal.Continuum

/-- Goal of the project: formalize the counterexamples of the chapter 10
of the book "Counterexamples in Analysis" by Bernard R. Gelbaum and
John M. H. Olmsted -/

-- Counterexample 1: Two disjoint closed sets that are at
-- a zero distance

def F1 : Set (ℝ × ℝ) := setOf fun (x,y) ↦ x*y = 1

def F2 : Set (ℝ × ℝ) := setOf fun (_,y) ↦ y=0

lemma F1_disjoint_F2 : F1 ∩ F2 = ∅ := by
  by_contra H
  rw [Set.ext_iff] at H
  push_neg at H
  cases' H with w H
  cases H with
  | inl h =>
      obtain ⟨⟨h, h'⟩, _⟩ := h
      change w.1 * w.2 = 1 at h
      rw [h', mul_zero] at h
      exact zero_ne_one h
  | inr h => exact h.2

lemma F1_closed : IsClosed F1 :=
  isClosed_eq (Continuous.mul continuous_fst continuous_snd) continuous_one

lemma F2_closed : IsClosed F2 :=
  isClosed_eq continuous_snd continuous_zero

noncomputable instance : Dist (ℝ × ℝ) where
  dist := fun p q ↦ ((q.1 - p.1)^(2 : ℝ) + (q.2 - p.2)^(2 : ℝ))^(1/(2 : ℝ))

def set_dist (A B : Set (ℝ × ℝ)) : Set ℝ := setOf (∃ p ∈ A, ∃ q ∈ B, dist p q = ·)

noncomputable def distance (A B : Set (ℝ × ℝ)) := sInf (set_dist A B)

lemma set_dist_nonempty : (set_dist F1 F2).Nonempty := by
  refine ⟨dist (2, 1/2) ((2 : ℝ), (0 : ℝ)), ⟨(2, 1/2), ⟨?_, ⟨(2,0),
    ⟨(by rw [Set.mem_def]; rfl), rfl⟩⟩⟩⟩⟩
  change 2 * (1/2) = 1
  norm_num

lemma dist_on_prod_pos : ∀ d ∈ set_dist F1 F2, 0 ≤ d := by
  rintro a ⟨p, ⟨_, ⟨q, ⟨_, hdist⟩⟩⟩⟩
  rw [← hdist]
  change 0 ≤ ((q.1 - p.1)^2 + (q.2 - p.2)^2)^(1/2)
  rw [← Real.sqrt_eq_rpow]
  exact Real.sqrt_nonneg _

lemma distance_F1_F2_neg : distance F1 F2 ≤ 0 := by
  rw [distance, Real.sInf_le_iff ⟨0, dist_on_prod_pos⟩ set_dist_nonempty]
  refine fun ε hε ↦ ⟨dist (2 / ε, ε / 2) (2 / ε, 0), ⟨?_, ?_⟩⟩
  · refine ⟨(2 / ε, ε / 2), ⟨?_, ⟨(2 / ε, 0), ⟨(by rw [Set.mem_def]; rfl), rfl⟩⟩⟩⟩
    change (2/ε) * (ε/2) = 1
    norm_num
    exact div_self (ne_of_gt hε)
  · change ((2/ε - 2/ε)^2 + (0 - ε/2)^2)^(1/2) < 0 + ε
    rw [zero_add, sub_self, zero_sub, Real.zero_rpow two_ne_zero, zero_add, Real.rpow_two,
    Even.neg_pow even_two, ← Real.sqrt_eq_rpow, Real.sqrt_sq, half_lt_self_iff]
    exact hε
    linarith

lemma distance_F1_F2_pos : 0 ≤ distance F1 F2 :=
  le_csInf set_dist_nonempty dist_on_prod_pos

lemma distance_F1_F2_eq_zero : distance F1 F2 = 0 :=
  (LE.le.ge_iff_eq distance_F1_F2_neg).1 distance_F1_F2_pos

-- Counterexample 2: A bounded plane set contained in no minimum closed disk

def IsClosedDisk (D : Set (ℝ × ℝ)) (h k r : ℝ) (_ : 0 < r) : Prop :=
    ∀ x ∈ D, (x.1 - h)^2 + (x.2 - k)^2 ≤ r^2

def MinimumClosedDisk (A D : Set (ℝ × ℝ)) {h k r : ℝ} {hr : 0 < r} (_ : IsClosedDisk D h k r hr ∧ A ⊆ D)  : Prop :=
    ∀ (D' : Set (ℝ × ℝ)) (_ : (∃ (h' k' r' : ℝ) (hr' : 0 < r'), IsClosedDisk D' h' k' r' hr') ∧ A ⊆ D'), D ⊆ D'

def Line (a b c : ℝ) : Set (ℝ × ℝ) := setOf (fun x ↦ a*x.1 + b*x.2 = c)

def IsTwoPointSet (S : Set (ℝ × ℝ)) : Prop :=
  ∀ (a b c : ℝ), Cardinal.mk (Subtype (· ∈ Line a b c ∩ S)) = 2

example (S : Set (ℝ × ℝ)) (hS : IsTwoPointSet S) :
    ¬(∃ (D : Set (ℝ × ℝ)) (h k r : ℝ) (hr : 0 < r) (hD : IsClosedDisk D h k r hr ∧ S ⊆ D),
    MinimumClosedDisk S D hD) := by
  intro h
  obtain ⟨D, h, k, r, hr, ⟨hD, hD₂⟩, hD₃⟩ := h
  let L := Line 1 0 (h + r + 1)
  have : L ∩ D = ∅ := by
    by_contra h₂
    rw [Set.ext_iff] at h₂
    push_neg at h₂
    obtain ⟨w, hw⟩ := h₂
    cases hw with
    | inl h₃ =>
        obtain ⟨⟨hw, hw₂⟩, hw₃⟩ := h₃
        rw [IsClosedDisk] at hD
        specialize hD w hw₂
        change 1*w.1 + 0*w.2 = (h + r + 1) at hw
        rw [one_mul, zero_mul, add_zero] at hw
        rw [hw, add_sub_right_comm, add_sub_right_comm, sub_self, zero_add] at hD
        have : r ^ 2 < (r + 1) ^ 2 := by
          linarith
        have : r ^ 2 < (r + 1) ^ 2 + (w.2 - k) ^ 2 := by
          rw [add_comm]
          exact lt_add_of_nonneg_of_lt (even_two.pow_nonneg (w.2 - k)) this
        exact not_lt.2 hD this
    | inr h₃ => exact h₃.2
  have : L ∩ S = ∅ := by
    ext x
    refine ⟨fun h' ↦ ?_, fun h' ↦ ?_⟩
    · rw [Set.ext_iff] at this
      exact (this x).1 ⟨h'.1, hD₂ h'.2⟩
    · exfalso
      exact h'
  unfold IsTwoPointSet at hS
  specialize hS 1 0 (h + r + 1)
  apply_fun Cardinal.mk at this
  simp only [Cardinal.mk_eq_zero] at this
  rw [this] at hS
  exact two_ne_zero hS.symm

-- Construction of the two-point set

def IsColinear (a b : ℝ × ℝ) : Prop := ∃ (a' b' c' : ℝ), a ∈ Line a' b' c' ∧ b ∈ Line a' b' c'

def NoThreeColinearPoints {α : Type*} (s : α → Set (ℝ × ℝ)) : Prop :=
    ¬(∃ a b c, a ∈ Set.iUnion s ∧ b ∈ Set.iUnion s ∧ c ∈ Set.iUnion s ∧ IsColinear a b ∧ IsColinear b c)

def ordinals_lt (o : Ordinal) : Set Ordinal := setOf (· < o)

def Lines : setOf (· < Cardinal.continuum.ord) → setOf (∃ a b c, · = Line a b c) := sorry

def Lines_v2 (o : Ordinal) : setOf (· < o) → setOf (∃ a b c, · = Line a b c) := sorry

class seq_A (f : ordinals_lt Cardinal.continuum.ord → Set (ℝ × ℝ)) where
  prop₁ : ∀ ε : Subtype (ordinals_lt Cardinal.continuum.ord), Cardinal.mk (f ε) ≤ 2
  prop₂ : ∀ ε : Subtype (ordinals_lt Cardinal.continuum.ord),
    NoThreeColinearPoints (fun (i : setOf (fun (i : ordinals_lt Cardinal.continuum.ord) ↦ i ≤ ε)) ↦ f i)
  prop₃ : ∀ ε : Subtype (ordinals_lt Cardinal.continuum.ord),
    Cardinal.mk (Subtype (· ∈ Set.iUnion (fun (i : setOf (fun (i : ordinals_lt Cardinal.continuum.ord) ↦ i ≤ ε)) ↦ f i) ∩
    Lines ε)) = 2

class seq_A_v2 (o : Ordinal) (f : ordinals_lt o → Set (ℝ × ℝ)) where
  prop₁ := ∀ ε : Subtype (ordinals_lt o), Cardinal.mk (f ε) ≤ 2
  prop₂ := ∀ ε : Subtype (ordinals_lt o),
    NoThreeColinearPoints (fun (i : setOf (fun (i : ordinals_lt o) ↦ i ≤ ε)) ↦ f i)
  prop₃ := ∀ ε : Subtype (ordinals_lt o),
    Cardinal.mk (Subtype (· ∈ Set.iUnion (fun (i : setOf (fun (i : ordinals_lt o) ↦ i ≤ ε)) ↦ f i) ∩
    Lines_v2 o ε)) = 2

def existence_seqA : ∃ (f : ordinals_lt Cardinal.continuum.ord → Set (ℝ × ℝ)), Nonempty (seq_A_v2 Cardinal.continuum.ord f) := by
  apply @Ordinal.induction (p := fun (o : Ordinal) ↦ ∃ (f : ordinals_lt o → Set (ℝ × ℝ)), Nonempty (seq_A_v2 o f)) Cardinal.continuum.ord
  intros ε hε
