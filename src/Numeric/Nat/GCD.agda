
module Numeric.Nat.GCD where

open import Prelude
open import Control.WellFounded
open import Numeric.Nat.Properties
open import Numeric.Nat.DivMod
open import Numeric.Nat.Divide
open import Tactic.Nat

--- GCD ---

record IsGCD (d a b : Nat) : Set where
  no-eta-equality
  constructor is-gcd
  field d|a : d Divides a
        d|b : d Divides b
        g   : ∀ k → k Divides a → k Divides b → k Divides d

record GCD (a b : Nat) : Set where
  no-eta-equality
  constructor gcd-res
  field d     : Nat
        isGCD : IsGCD d a b

open GCD public using () renaming (d to get-gcd)

isGCD-step : ∀ {d r₀ r₁ r₂} q → q * r₁ + r₂ ≡ r₀ → IsGCD d r₁ r₂ → IsGCD d r₀ r₁
isGCD-step q refl (is-gcd d|r₁ d|r₂ g) =
  is-gcd (divides-add (divides-mul-r q d|r₁) d|r₂)
         d|r₁ (λ k k|r₀ k|r₁ → g k k|r₁ (divides-sub-l k|r₀ (divides-mul-r q k|r₁)))

private
  gcd-step : ∀ {a b} q {r} → q * suc b + r ≡ a → GCD (suc b) r → GCD a (suc b)
  gcd-step q eq (gcd-res d p) = gcd-res d (isGCD-step q eq p)

  gcd-cert-acc : ∀ a b → Acc _<_ b → GCD a b
  gcd-cert-acc a zero _ = gcd-res a (is-gcd (factor 1 auto) (factor! 0) (λ k k|a _ → k|a))
  gcd-cert-acc a (suc b) (acc wf) =
    case a divmod suc b of λ
    { (qr q r lt eq) → gcd-step q eq (gcd-cert-acc (suc b) r (wf r lt)) }

eraseIsGCD : ∀ {d a b} → IsGCD d a b → IsGCD d a b
eraseIsGCD (is-gcd d|a d|b g) =
  is-gcd (fast-divides d|a) (fast-divides d|b)
         λ k k|a k|b → fast-divides (g k k|a k|b)

eraseGCD : ∀ {a b} → GCD a b → GCD a b
eraseGCD (gcd-res d p) = gcd-res d (eraseIsGCD p)

gcd : ∀ a b → GCD a b
gcd 0 b = gcd-res b (is-gcd (factor! 0) divides-refl (λ _ _ k|b → k|b))
gcd 1 b = gcd-res 1 (is-gcd divides-refl (factor b auto) (λ _ k|1 _ → k|1))
gcd a b = eraseGCD (gcd-cert-acc a b (wfNat b))

gcd! : Nat → Nat → Nat
gcd! a b = get-gcd (gcd a b)

--- Properties ---

private
  gcd-unique′ : ∀ {a b} d₁ d₂ (g₁ : IsGCD d₁ a b) (g₂ : IsGCD d₂ a b) → d₁ ≡ d₂
  gcd-unique′ zero zero _ _ = refl
  gcd-unique′ zero (suc d) (is-gcd 0|a 0|b _) (is-gcd _ _ g) =
    sym (divides-zero (g 0 0|a 0|b))
  gcd-unique′ (suc d) zero (is-gcd _ _ g) (is-gcd 0|a 0|b _) =
    divides-zero (g 0 0|a 0|b)
  gcd-unique′ (suc d) (suc d′) (is-gcd d|a d|b gd) (is-gcd d′|a d′|b gd′) =
    divides-antisym (gd′ (suc d) d|a d|b)
                    (gd  (suc d′) d′|a d′|b)

gcd-unique : ∀ a b d → IsGCD d a b → gcd! a b ≡ d
gcd-unique a b d pd with gcd a b
... | gcd-res d′ pd′ = gcd-unique′ d′ d pd′ pd

gcd-mul-l : ∀ a b → gcd! a (a * b) ≡ a
gcd-mul-l a b = gcd-unique a (a * b) a (is-gcd divides-refl (divides-mul-l b divides-refl) λ _ k|a _ → k|a)

gcd-mul-r : ∀ a b → gcd! b (a * b) ≡ b
gcd-mul-r a b = gcd-unique b (a * b) b (is-gcd divides-refl (divides-mul-r a divides-refl) λ _ k|b _ → k|b)

gcd-zero : ∀ n → gcd! 0 n ≡ n
gcd-zero n = gcd-unique 0 n n (is-gcd (factor! 0) divides-refl λ _ _ k|n → k|n)

is-gcd-commute : ∀ {d a b} → IsGCD d a b → IsGCD d b a
is-gcd-commute (is-gcd d|a d|b g) = is-gcd d|b d|a (flip ∘ g)

gcd-commute : ∀ a b → gcd! a b ≡ gcd! b a
gcd-commute a b with gcd b a
gcd-commute a b | gcd-res d p = gcd-unique a b d (is-gcd-commute p)
