
module Tile exposing (..)


-- Elm
import Color
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)


type alias Point = (Int, Int)


type Kind
  = Box
  | Empty


type alias Tile =
  { idx : Point  -- idx location (0,0) is top-left
  , pos : Vec    -- pixel location
  , tileSize : Int
  , kind : Kind
  }


-- RENDER


-- Returns Nothing if the Tile does not render as anything (transparent)
draw : Tile -> Maybe Collage.Form
draw tile =
  case tile.kind of
    Empty ->
      Nothing
    Box ->
      Element.image 16 16 "./img/wall.png"
      |> Collage.toForm
      |> Just
