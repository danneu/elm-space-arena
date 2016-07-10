
module Starfield exposing (Starfield, init, toForm, transform)


-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)


type alias StarfieldRecord =
  { distance : Float -- Starfield moves 1/distance the speed of the ship
  , tileSize : Int
  , url : String
  }


-- Opaque type
type alias Starfield = StarfieldRecord


init : Float -> Int -> String -> Starfield
init distance tileSize url =
  StarfieldRecord distance tileSize url


-- RENDER


toForm : { x : Int, y : Int } -> Starfield -> Collage.Form
toForm viewport {tileSize, url} =
  Element.tiledImage (viewport.x + tileSize * 2) (viewport.y + tileSize * 2) url
  |> Collage.toForm


transform : Vec -> Collage.Form -> Starfield -> Collage.Form
transform ((x, y) as shipPos) form {distance, tileSize} =
  let
    coord =
      ( toFloat ((round (-x / distance)) % tileSize)
      , toFloat ((round (y / distance)) % tileSize)
      )
  in
    Collage.move coord form


-- OLD
-- draw : { x : Int, y : Int} -> Vec -> Starfield -> Collage.Form
-- draw viewport ((x, y) as shipPos) {distance, tileSize, url} =
--   let
--     coord =
--       ( toFloat ((round (-x / distance)) % tileSize)
--       , toFloat ((round (y / distance)) % tileSize)
--       )
--   in
--     Element.tiledImage (viewport.x + tileSize * 2) (viewport.y + tileSize * 2) url
--     |> Collage.toForm
--     |> Collage.move coord
