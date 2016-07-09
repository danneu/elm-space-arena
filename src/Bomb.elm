
module Bomb exposing (..)

-- Elm
import Time exposing (Time)
-- 1st
import Vec exposing (Vec)


type alias Bomb =
  { pos : Vec
  , vel : Vec
  , ttl : Time
  }
