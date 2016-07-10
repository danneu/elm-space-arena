
module Tile exposing (..)


-- Elm
import Color
import Json.Encode as JE
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


-- JSON


encode : Tile -> JE.Value
encode {pos} =
  JE.object
    [ ("pos", Vec.encode pos)
    ]
