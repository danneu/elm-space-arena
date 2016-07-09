
module Collision.Bounds exposing (..)

-- 1st
import Vec exposing (Vec)


type alias Bounds =
  { top : Float
  , left : Float
  , right : Float
  , bottom : Float
  }


fromPoint : Float -> Vec -> Bounds
fromPoint radius ((x, y) as center) =
  { left = x - radius
  , right = x + radius
  , top = y - radius
  , bottom = y + radius
  }


overlap : Bounds -> Bounds -> Bool
overlap a b =
  let
    xOverlaps = (a.left < b.right) && (a.right > b.left)
    yOverlaps = (a.top < b.bottom) && (a.bottom > b.top)
  in
    xOverlaps && yOverlaps
