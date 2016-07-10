
module CollisionTile exposing (..)


-- Elm
import Color
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)
import Collision.Bounds exposing (Bounds)

{- This file is to be replaced by Tile.elm
-}

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
