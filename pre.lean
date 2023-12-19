import Mathlib.Data.Real.EReal
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.Lattice

open Classical

--Structure Definition
structure Auction where
   I : Type*
   hF : Fintype I
   hI: Inhabited I
   hP : ∃ i j : I , i ≠ j
   hP' :  ∀ i : I , ∃ j, i ≠  j
   v : I → ℝ -- The value of each clients

namespace Auction

variable {a : Auction} (b : a.I → ℝ  )

instance : Fintype a.I := a.hF

--Helper Definitions and Lemmas
@[simp]
def maxb : ℝ  := Finset.sup' Finset.univ (⟨ a.hI.default ,  (Finset.mem_univ _)⟩ ) b
--maxb computes the highest bid given a bidding function b

lemma exists_max : ∃ i: a.I, b i = a.maxb b := by
{
   obtain ⟨  i , _ ,h2⟩ := Finset.exists_mem_eq_sup' (⟨ a.hI.default, (Finset.mem_univ _)⟩ ) b
   exact ⟨ i, symm h2⟩
}
--there exists a participant i whose bid equals the highest bid

noncomputable def winner : a.I := Classical.choose (exists_max b)
--defines the winner of the auction,i.e. the participant with the highest bid

lemma winner_take_max : b (winner b) = maxb b:= Classical.choose_spec (exists_max b)
--states that the bid of the winner equals the highest bid

lemma delete_i_nonempty (i:a.I) :Finset.Nonempty (Finset.erase  Finset.univ i ) := by
{
  obtain ⟨ i , hi ⟩  := a.hP' i
  use i
  simp only [Finset.mem_univ, not_true, Finset.mem_erase, and_true]
  rw [ne_comm]
  exact hi
}
--removing a participant i from all participants still leaves a non-empty set

noncomputable def B (i: a.I) : ℝ  := Finset.sup' (Finset.erase Finset.univ i) (delete_i_nonempty i) b
--B is the maximal bid of all but i

noncomputable def secondprice : ℝ  := B b (winner b)
--defines the second highest bid,(i.e.the highest bid excluding the winner’s bid.)

noncomputable def utility  (i : a.I) : ℝ := if i = winner b then a.v i - secondprice b else 0
--defines the utility of participant i, which is--their valuation minus the second highest bid if i is the winner--otherwise, it's 0.

lemma utility_winner (H: i = winner b) : utility b i = a.v i - secondprice b
:= by rw [utility]; simp only [ite_true, H]
--if i is the winner
--then their utility is their valuation minus the second highest bid.

lemma utility_loser (i: a.I) (H : i≠ winner b) : utility b i = 0
:= by rw [utility]; simp only [ite_false, H]
--if i is not the winner, then their utility is 0.

def dominant (i : a.I) (bi : ℝ) : Prop :=
   ∀ b b': a.I → ℝ , (b i = bi) → (∀ j: a.I, j≠ i→ b j = b' j)
   →  utility  b i ≥ utility b' i
--defines concept of a dominant strategy
lemma gt_wins (i : a.I) (H: ∀ j , i ≠j →  b i > b j) : i = winner b
:= by {
   have HH : ∀ j, i = j ↔  b j = maxb b:= by {
      have imax : b i = maxb b := by {
         have H1 : b i ≤  maxb b := by
         {  apply Finset.le_sup'
            simp only [Finset.mem_univ]
         }
         have H2 : maxb b ≤ b i := by
         {  apply Finset.sup'_le
            intro j _
            by_cases hji : i=j
            . rw [hji]
            . {have hji' := H j ( by rw [ne_eq] ; exact hji)
               linarith
            }
         }
         linarith
      }
      intro j
      constructor
      . {intro hji
         rw [<-hji]
         exact imax
      }
      . {intro hbj
         by_contra hji
         have hji' := H j (by rw [ne_eq];exact hji)
         rw [hbj] at hji'
         linarith
      }
   }
   rw [HH]
   rw [<-winner_take_max]
   }

lemma b_winner_max (H: i = winner b) : ∀ j: a.I, b i ≥ b j
:= by{
          intro j

          have H_max: b (winner b) = maxb b := winner_take_max b
          rw [<-H] at H_max
          have H_sup: b j ≤ maxb b
          {
          apply Finset.le_sup'
          simp only [Finset.mem_univ]
          }
          rw [<-H_max] at H_sup
          exact H_sup
     }
--the bid of the winner is always greater than or equal to the bids of all other participants.

lemma b_winner' (H: i = winner b) : b i ≥ B b i := by
{
   have Hmax := winner_take_max b
   rw [<-H] at Hmax
   rw [Hmax]
   apply Finset.sup'_le
   intro j
   intro _
   apply Finset.le_sup'
   simp only [Finset.mem_erase,Finset.mem_univ]
}
--shows that the bid of the winner is always greater than or equal to the second highest bid.

lemma b_winner (H: i = winner b) : b i ≥ secondprice b := by
   {
    have Hmax := winner_take_max b
    rw [<-H] at Hmax
    rw [Hmax]
    apply Finset.sup'_le
    apply delete_i_nonempty
    intro j _
    apply Finset.le_sup'
    simp only [Finset.mem_erase,Finset.mem_univ]

   }
-- the bid of the winner is always greater than or equal to the second highest bid.

lemma b_loser_max (H: i ≠  winner b) : B b i = maxb b := by
   {
      have H1 : B b i ≤ maxb b := by
      {
         apply Finset.sup'_le
         intro i _
         apply Finset.le_sup'
         simp only [Finset.mem_univ]
      }
      have H2 : maxb b ≤ B b i := by
      {
         rw [<-winner_take_max b]
         apply Finset.le_sup'
         simp only [Finset.mem_univ, Finset.mem_erase, and_true]
         exact (Ne.symm H)
      }
      linarith
   }
-- if i is not the winner, then the highest bid excluding i is equal to the overall highest bid.

lemma b_loser' (H: i ≠  winner b) : b i ≤ B b i := by sorry

lemma b_loser (H: i ≠  winner b) : b i ≤ secondprice b := by sorry

--Proof for the two Propositions
lemma utility_pos (i: a.I) : (b i = a.v i) → utility b i≥0   := by {
   intro H
   by_cases H2 : i = winner b

   . {
      rw [utility]
      simp only [H2, if_true]
      rw [<-H2]
      rw[<-H]
      rw [H2]
      rw [winner_take_max b]
      apply sub_nonneg.mpr
      rw [secondprice]
      apply Finset.sup'_le
      simp only [Finset.mem_univ, Finset.mem_erase, and_true]
      intro j _
      rw [maxb]
      simp only [Finset.le_sup'_iff, Finset.mem_univ, true_and]
      use j
      }
   . {
      rw [utility]
      rw [if_neg H2]
   }
}
theorem valuation_is_dominant (i : a.I ) : dominant i (a.v i) := by {
   intro b b' hb hb'
   by_cases H : i = winner b'
   . {
      by_cases H1 : a.v i >  B b' i
      . {
         have h_winner_b : i = winner b := gt_wins b i (λ j hj => by {
         rw[hb]
         rw[hb']

         have HBi: B b' i ≥  b' j := by {
            rw [B]
            simp only [Finset.mem_univ, not_true, ge_iff_le, Finset.le_sup'_iff, Finset.mem_erase,
              ne_eq, and_true]
            use j
            simp only [le_refl, and_true]
            rw [<-ne_eq,ne_comm]
            exact hj
         }

         exact gt_of_gt_of_ge H1 HBi
         exact id (Ne.symm hj)
         })
         repeat rw [utility_winner]
         have h_secondprice_eq : secondprice b = secondprice b' := by {
            repeat rw [secondprice]
            rw[<-h_winner_b]
            rw[<-H]
            repeat rw [B]
            have secondprice_eq: B b i = B b' i := by {
               apply le_antisymm
               . {
                  apply Finset.sup'_le
                  intro j
                  intro hj
                  apply Finset.le_sup'

               }
               rw [B]
               rw [B]
               simp only [Finset.mem_univ, not_true, ge_iff_le, Finset.le_sup'_iff, Finset.mem_erase,
                 ne_eq, and_true]
            }

         }

      }

   }
   . {
         -- Show that 0 ≥  utility b' i
         -- Combine with utility b i ≥ 0 finish the proof
         sorry
   }
    --  have u' := utility_loser b' i  H
   --   simp only [u',utility_pos b i hb]
   --}
}

end Auction
