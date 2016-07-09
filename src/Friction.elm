
module Friction exposing (..)

-- Elm
import Time exposing (Time)
-- 1st
import Vec exposing (Vec)


{-| Decays the vector length by a percentage per second of elapsed time.
-}
apply : Time -> Float -> Vec -> Vec
apply delta rate ((x, y) as vel) =
  let
    x' = x - (x * rate * delta)
    y' = y - (y * rate * delta)
  in
    Vec.make x' y'


{-| Only applies friction if entity is traveling over a certain speed.
It's aesthetically pleasing if entities floating in space never come to a
full stop.
-}
applyWithThreshold : Time -> Float -> Float -> Vec -> Vec
applyWithThreshold delta rate minSpeed vel =
  if Vec.length vel > minSpeed then
    apply delta rate vel
  else
    vel
