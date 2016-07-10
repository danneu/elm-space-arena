
module TileGrid exposing (..)


-- Elm
import Dict exposing (Dict)
-- 3rd
import Collage
-- 1st
import Vec exposing (Vec)
import Tile exposing (Tile, Kind(..))
import Util


type alias TileGridRecord =
  { tileSize : Int
  , dict : Dict (Int, Int) Tile
  , rowCount : Int
  , colCount : Int
  }


-- Opaque record
type alias TileGrid = TileGridRecord


default : TileGrid
default =
  let
    tileSize = 16
    xformTile : Int -> Int -> Int -> Tile.Kind -> ((Int, Int), Tile)
    xformTile y rowIdx colIdx kind =
      let
        x = colIdx * tileSize
        point = (colIdx, rowIdx)
        pos = (toFloat x, toFloat y)
        tile = Tile point pos tileSize kind
      in
        (point, tile)
    xformRow : Int -> (List Tile.Kind) -> (List ((Int, Int), Tile))
    xformRow rowIdx row =
      let
        y = rowIdx * tileSize
      in
        List.indexedMap (xformTile y rowIdx) row
  in
    List.concatMap identity
      [ [List.repeat 64 Box]
      , List.repeat 18 (List.concat [ [Box], (List.repeat 62 Empty), [Box] ])
      , [List.repeat 64 Box]
      ]
    |> List.indexedMap xformRow
    |> List.concatMap identity
    |> Dict.fromList
    |> (\dict ->
          { tileSize = tileSize
          , dict = dict
          , rowCount = 20
          , colCount = 64
          }
      )


-- DIMENSIONS


-- pixel width
width : TileGrid -> Int
width grid =
  grid.tileSize * grid.colCount


-- pixel height
height : TileGrid -> Int
height grid =
  grid.tileSize * grid.rowCount


-- QUERY


allTiles : TileGrid -> List Tile
allTiles {dict} =
  Dict.values dict


-- Ex: tilesWithinPosRadius ship.size ship.pos => [...]
tilesWithinPosRadius : Float -> Vec -> TileGrid -> List Tile
tilesWithinPosRadius radius pos grid =
  case containingTile pos grid of
    Nothing ->
      []
    Just centerTile ->
      let
        diameter = round (radius * 2)
        pred tile =
          collides diameter pos tile.tileSize tile.pos
      in
        Dict.values grid.dict
        |> List.filter pred


-- Returns the tile that contains the given position vector.
containingTile : Vec -> TileGrid -> Maybe Tile
containingTile ((x, y) as pos) grid =
  let
    pointX = Util.nearestMultiple grid.tileSize x // grid.tileSize
    pointY = Util.nearestMultiple grid.tileSize y // grid.tileSize
    tileIdx = (pointX, pointY)
  in
    Dict.get tileIdx grid.dict


-- Returns list of tiles adjacent to given tile idx (8 directions)
idxNeighbors : (Int, Int) -> TileGrid -> List Tile
idxNeighbors ((x, y) as idx) {dict} =
  [ Dict.get (x, y - 1) dict -- n
  , Dict.get (x + 1, y - 1) dict -- ne
  , Dict.get (x + 1, y) dict -- e
  , Dict.get (x + 1, y + 1) dict -- se
  , Dict.get (x, y + 1) dict -- s
  , Dict.get (x - 1, y + 1) dict -- sw
  , Dict.get (x - 1, y) dict -- w
  , Dict.get (x - 1, y - 1) dict -- nw
  ]
  |> List.filter Util.isJust
  |> List.map Util.unwrapMaybe


-- COLLISION


type alias CollisionResult =
  { -- Which directions were touching
    dirs : { left : Bool, right : Bool, top : Bool, bottom : Bool }
    -- Next position of the entity
  , pos : Vec
  }


collides : Int -> Vec -> Int -> Vec -> Bool
collides size1 ((x1, y1) as pos1) size2 ((x2, y2) as pos2) =
  let
    radius1 = toFloat size1 / 2
    radius2 = toFloat size2 / 2
    overlapsX = (x1 - radius1 < x2 + radius2) && (x1 + radius1 > x2 - radius2)
    overlapsY = (y1 - radius1 < y2 + radius2) && (y1 + radius1 > y2 - radius2)
  in
    overlapsX && overlapsY


-- vel should already be adjusted by delta time
moveY : Int -> Vec -> Vec -> Int -> List Tile
        -> { finalPosY : Float, top : Bool, bottom : Bool }
moveY size ((x, y) as prevPos) ((vx, vy) as vel) tileSize neighbors =
  let
    (testX, testY) = Vec.add prevPos (0, vy)
    accum tiles =
      case tiles of
        -- No collisions
        [] ->
          { finalPosY = testY, top = False, bottom = False }
        tile :: rest ->
          case tile.kind of
            -- Cannot collide with empty tiles, so skip
            Empty ->
              accum rest
            Box ->
              if collides size (testX, testY) tileSize tile.pos then
                if vy < 0 then
                  -- Collided with tile above
                  --let _ = Debug.log "collided top" tile in
                  { finalPosY = (snd tile.pos) + toFloat tileSize / 2
                                + toFloat size / 2
                  , top = True
                  , bottom = False
                  }
                else
                  -- Collided with tile below
                  --let _ = Debug.log "collided bottom" tile in
                  { finalPosY = (snd tile.pos) - toFloat tileSize / 2
                                - toFloat size / 2
                  , top = False
                  , bottom = True
                  }
              else
                accum rest
  in
    accum neighbors


-- vel should already be adjusted by delta time
moveX : Int -> Vec -> Vec -> Int -> List Tile
        -> { finalPosX : Float, left : Bool, right : Bool }
moveX size ((x, y) as prevPos) ((vx, vy) as vel) tileSize neighbors =
  let
    (testX, testY) = Vec.add prevPos (vx, 0)
    accum tiles =
      case tiles of
        -- No collisions
        [] ->
          { finalPosX = testX, left = False, right = False }
        tile :: rest ->
          case tile.kind of
            -- Cannot collide with empty tiles, so skip
            Empty ->
              accum rest
            Box ->
              if collides size (testX, testY) tileSize tile.pos then
                if vx < 0 then
                  -- Collided with left tile
                  --let _ = Debug.log "collided left" tile in
                  { finalPosX = (fst tile.pos) + toFloat tileSize / 2
                                + toFloat size / 2
                  , left = True
                  , right = False
                  }
                else
                  -- Collided with right tile
                  --let _ = Debug.log "collided right" tile in
                  { finalPosX = (fst tile.pos) - toFloat tileSize / 2
                                - toFloat size / 2
                  , left = False
                  , right = True
                  }
              else
                accum rest
  in
    accum neighbors


-- vel should already be adjusted by delta time
-- size is entity side length (assumed square)
trace : Int -> Vec -> Vec -> TileGrid -> CollisionResult
trace size ((x, y) as prevPos) ((vx, vy) as vel) grid =
  -- { pos = Vec.add prevPos vel
  -- , dirs = { left = False, right = False, top = False, bottom = False }
  -- }
  case containingTile prevPos grid of
    Nothing ->
      Debug.crash "Huh? Ship wasn't inside a tile?"
    Just centerTile ->
      let
        neighbors =
          tilesWithinPosRadius
            (toFloat size / 2 + toFloat grid.tileSize / 2)
            prevPos
            grid
        {finalPosY, top, bottom} = moveY size prevPos vel grid.tileSize neighbors
        {finalPosX, left, right} = moveX size prevPos vel grid.tileSize neighbors
      in
        { dirs = { left = left, right = right, top = top, bottom = bottom }
        , pos = Vec.make finalPosX finalPosY
        }


-- RENDER


draw : (Vec -> (Float, Float)) -> TileGrid -> Collage.Form
draw toCoord ({dict} as grid) =
  Dict.values dict
  |> List.map (\tile ->
       case Tile.draw tile of
         Nothing ->
           Nothing
         Just form ->
           form
           |> Collage.move (toCoord tile.pos)
           |> Just
     )
  |> List.filter Util.isJust
  |> List.map Util.unwrapMaybe
  |> Collage.group
