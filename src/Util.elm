
module Util exposing (..)

-- 1st
import Vec exposing (Vec)


{-| Wrap an angle so that it's always 0 <= angle < 360.
-}
wrap360 : Float -> Float
wrap360 deg =
  if deg >= 0 && deg < 360 then
    deg
  else
    toFloat <| (round deg) % 360


{-| Round `n` to the nearest multiple.
-}
nearestMultiple : Int -> Float -> Int
nearestMultiple multiple n =
  multiple * (round <| n / (toFloat multiple))


isJust : Maybe a -> Bool
isJust maybe =
  case maybe of
    Nothing ->
      False
    Just _ ->
      True

unwrapMaybe : Maybe a -> a
unwrapMaybe maybe =
  case maybe of
    Nothing ->
      Debug.crash "Impossible, encountered a Nothing"
    Just val ->
      val


-- Translate our game positions to stage coordinates.
-- In our game, (0, 0) is the top-left point where +x goes right
-- and +y goes down.
toCoord : { x : Int, y : Int } -> Vec -> (Float, Float)
toCoord viewport (x, y) =
  (x - (toFloat viewport.x / 2), (toFloat viewport.y / 2) - y)
