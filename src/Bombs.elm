
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


-- List.filterMap
--   ( moveBomb delta
--     >> checkWall delta grid
--     >> (flip Maybe.andThen) (expireBomb delta)
--   )
tick : Float -> TileGrid -> List Bomb -> (List Bomb, List Bomb)
tick delta grid bombs =
  let
    accum bombs ((nextBombs, detonated) as memo) =
      case bombs of
        [] ->
          memo
        b :: rest ->
          let
            -- 1. Move them bomb
            b' = moveBomb delta b
          in
            -- 2. Check if it hit a wall (detonate)
            case checkWall delta grid b' of
              Nothing ->
                -- Detonated
                accum rest (nextBombs, b' :: detonated)
              Just _ ->
                -- 3. Check if bomb is expired
                case expireBomb delta b' of
                  Nothing ->
                    -- Expired
                    accum rest memo
                  Just _ ->
                    -- Bomb is still live
                    accum rest (b' :: nextBombs, detonated)
  in
    accum bombs ([], [])


-- Check if bomb has run out of ttl
expireBomb : Float -> Bomb -> Maybe Bomb
expireBomb delta bomb =
  if bomb.ttl <= 0 then
    Nothing
  else
    Just bomb


-- If bomb hits a wall, it dies
checkWall : Float -> TileGrid -> Bomb -> Maybe Bomb
checkWall deltaTime grid bomb =
  let
    {dirs} = TileGrid.trace deltaTime 0 bomb.pos bomb.vel grid
  in
    if dirs.left || dirs.right || dirs.top || dirs.bottom then
      Nothing
    else
      Just bomb


-- Move and age the bomb
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
              |> Vec.add (Vec.rotate player.angle (0, 450))
      , ttl = 4
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
