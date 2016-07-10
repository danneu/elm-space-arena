
module Tile exposing (..)


-- Elm
import Color
import Json.Encode as JE
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)
import Util exposing ((=>))


type alias Point = (Int, Int)


type Kind
  = Box
  | Empty


type alias Tile =
  { idx : Point  -- idx location (0,0) is top-left
  , pos : Vec    -- pixel location
  , tileSize : Int
  , kind : Kind
  , green : Bool
  }


-- JSON


encode : Tile -> JE.Value
encode {pos, green, kind, idx} =
  JE.object
    [ "idx" =>
        JE.object
          [ "x" => JE.int (fst idx)
          , "y" => JE.int (snd idx)
          ]
    , "pos" =>
        Vec.encode pos
    , "kind" =>
        case kind of
          Empty -> JE.string "EMPTY"
          Box -> JE.string "BOX"
    , "green" =>
        JE.bool green
    ]
