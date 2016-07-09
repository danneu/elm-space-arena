
module CollisionTile exposing (..)


-- Elm
import Color
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)
import Collision.Bounds exposing (Bounds)


type Kind
  = Empty -- Does not collide
  | Box -- All sides are 90 degree angle collisions.


type alias CollisionTile =
  { pos : Vec
  , kind : Kind
  , bounds : Bounds
  }


make : Int -> Int -> Int -> Kind -> CollisionTile
make x y tileSize kind =
  let
    radius = toFloat tileSize / 2
  in
  { pos = Vec.make (toFloat x) (toFloat y)
  , kind = kind
  , bounds =
      { left = toFloat x - radius
      , right = toFloat x + radius
      , top = toFloat y - radius
      , bottom = toFloat y + radius
      }
  }


draw : CollisionTile -> Maybe Collage.Form
draw tile =
  case tile.kind of
    Empty ->
      Nothing
    Box ->
      Element.image 16 16 "./img/wall.png"
      |> Collage.toForm
      |> Just
