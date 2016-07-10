
module Bombs exposing (..)

-- Elm
import Json.Encode as JE
-- 1st
import Vec exposing (Vec)
import Player
import TileGrid exposing (TileGrid)


type alias Bomb =
  { id : Int
  , pos : Vec
  , vel : Vec
  , ttl : Float -- bomb stays in flight for ttl seconds
  , ownerId : Int -- id for the entity that shot it, e.g. player id
  }


tick : Float -> List Bomb -> List Bomb
tick delta =
  List.filterMap (killBomb delta << moveBomb delta)


killBomb : Float -> Bomb -> Maybe Bomb
killBomb delta bomb =
  if bomb.ttl <= 0 then
    Nothing
  else
    Just bomb


moveBomb : Float -> Bomb -> Bomb
moveBomb delta bomb =
  let
    pos' =
      Vec.multiply delta bomb.vel
      |> Vec.add bomb.pos
    ttl' =
      bomb.ttl - delta
  in
    { bomb
        | pos = pos'
        , ttl = ttl'
    }


fire : Int -> Player.Model -> List Bomb -> List Bomb
fire id player bombs =
  let
    bomb =
      { id = id
      , pos = Player.nose player
      , vel = player.vel
              |> Vec.add (Vec.rotate player.angle (0, 200))
      , ttl = 5
      , ownerId = player.id
      }
  in
    bomb :: bombs


-- JSON


encode1 : Bomb -> JE.Value
encode1 {id, pos} =
  JE.object
    [ ("id", JE.int id)
    , ("pos", Vec.encode pos)
    ]

encodeN : List Bomb -> JE.Value
encodeN bombs =
  bombs
  |> List.map (\bomb -> (toString bomb.id, encode1 bomb))
  |> JE.object
