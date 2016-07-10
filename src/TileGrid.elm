
module TileGrid exposing (..)


-- Elm
import Dict exposing (Dict)
import Json.Encode as JE
import Random
-- 1st
import Vec exposing (Vec)
import Tile exposing (Tile, Kind(..))
import Util exposing ((=>))


type alias TileGridRecord =
  { tileSize : Int
  , dict : Dict (Int, Int) Tile
  , rowCount : Int
  , colCount : Int
  , greenCount : Int
  , maxGreens : Int
  }


-- Opaque record
type alias TileGrid = TileGridRecord


default : Int -> Int -> Int -> TileGrid
default rows cols maxGreens =
  let
    tileSize = 16
    xformTile : Int -> Int -> Int -> Tile.Kind -> ((Int, Int), Tile)
    xformTile y rowIdx colIdx kind =
      let
        x = colIdx * tileSize
        point = (colIdx, rowIdx)
        pos = (toFloat x, toFloat y)
        tile = Tile point pos tileSize kind False
      in
        (point, tile)
    xformRow : Int -> (List Tile.Kind) -> (List ((Int, Int), Tile))
    xformRow rowIdx row =
      let
        y = rowIdx * tileSize
      in
        List.indexedMap (xformTile y rowIdx) row
  in
    List.repeat rows (List.repeat cols Empty)
    |> List.indexedMap xformRow
    |> List.concatMap identity
    |> Dict.fromList
    |> (\dict ->
          { tileSize = tileSize
          , dict = dict
          , rowCount = rows
          , colCount = cols
          , greenCount = 0
          , maxGreens = maxGreens
          }
      )
    -- Make outermost tiles into walls
    |> map
         (\ ((x, y) as idx) tile ->
            if x == 0 || y == 0 || y == rows - 1 || x == cols - 1 then
              { tile | kind = Tile.Box }
            else
              tile
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


-- TRANSFORM


map : ((Int, Int) -> Tile -> Tile) -> TileGrid -> TileGrid
map xform grid =
  { grid
      | dict = Dict.map xform grid.dict
  }


-- QUERY


-- Percent of the max amount of greens currently on the board
greenCoverage : TileGrid -> Float
greenCoverage {greenCount, maxGreens} =
  toFloat greenCount / toFloat maxGreens


contains : (Int, Int) -> TileGrid -> Bool
contains idx {dict} =
  case Dict.get idx dict of
    Just _ ->
      True
    Nothing ->
      False


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


-- Debug
showCollisionResult : CollisionResult -> String
showCollisionResult result =
  "[ "
  ++ (if result.dirs.left then "Left " else "")
  ++ (if result.dirs.right then "Right " else "")
  ++ (if result.dirs.top then "Top " else "")
  ++ (if result.dirs.bottom then "Bottom " else "")
  ++ "]"



collides : Int -> Vec -> Int -> Vec -> Bool
collides size1 ((x1, y1) as pos1) size2 ((x2, y2) as pos2) =
  let
    radius1 = toFloat size1 / 2
    radius2 = toFloat size2 / 2
    overlapsX = (x1 - radius1 < x2 + radius2) && (x1 + radius1 > x2 - radius2)
    overlapsY = (y1 - radius1 < y2 + radius2) && (y1 + radius1 > y2 - radius2)
  in
    overlapsX && overlapsY


moveY : Float -> Int -> Vec -> Vec -> Int -> List Tile
        -> { finalPosY : Float, top : Bool, bottom : Bool }
moveY delta size ((x, y) as prevPos) ((vx, vy) as vel) tileSize neighbors =
  let
    (testX, testY) = Vec.add prevPos (Vec.multiply delta (0, vy))
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


moveX : Float -> Int -> Vec -> Vec -> Int -> List Tile
        -> { finalPosX : Float, left : Bool, right : Bool }
moveX delta size ((x, y) as prevPos) ((vx, vy) as vel) tileSize neighbors =
  let
    (testX, testY) = Vec.add prevPos (Vec.multiply delta (vx, 0))
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


-- size is entity hitbox side-length (assumed square)
trace : Float -> Int -> Vec -> Vec -> TileGrid -> CollisionResult
trace delta size ((x, y) as prevPos) ((vx, vy) as vel) grid =
  case containingTile prevPos grid of
    Nothing ->
      Debug.crash "FIXME: Entity tunneled through the outer wall"
    Just centerTile ->
      let
        -- Only need to collision-check nearby tiles
        neighbors =
          tilesWithinPosRadius
            (toFloat size / 2 + toFloat grid.tileSize / 2)
            prevPos
            grid
        {finalPosY, top, bottom} =
          moveY delta size prevPos vel grid.tileSize neighbors
        {finalPosX, left, right} =
          moveX delta size prevPos vel grid.tileSize neighbors
      in
        { dirs = { left = left, right = right, top = top, bottom = bottom }
        , pos = Vec.make finalPosX finalPosY
        }

insert : (Int, Int) -> Tile -> TileGrid -> TileGrid
insert idx tile grid =
  { grid
      | dict = Dict.insert idx tile grid.dict
  }


valueAt : (Int, Int) -> TileGrid -> Maybe Tile
valueAt idx {dict} =
  Dict.get idx dict

update : (Int, Int) -> (Maybe Tile -> Maybe Tile) -> TileGrid -> TileGrid
update idx xform grid =
  case xform (valueAt idx grid) of
    Nothing ->
      grid
    Just new ->
      insert idx new grid


-- Returns list of all tiles that were collected by player in this tick
checkGreens : Vec -> TileGrid -> (List Tile, TileGrid)
checkGreens pos grid =
  case containingTile pos grid of
    Nothing ->
      ([], grid)
    Just tile ->
      let
        tilesToCheck = tile :: (idxNeighbors tile.idx grid)
        accum tile ((collectedTiles, finalGrid) as memo) =
          if not tile.green then
            memo
          else
            let
              tile' = { tile | green = False }
              finalGrid' =
                insert tile.idx tile' finalGrid
                |> \g -> { g | greenCount = finalGrid.greenCount - 1 }
            in
              (tile' :: collectedTiles, finalGrid')
      in
        List.foldl accum ([], grid) tilesToCheck


spawnGreen : Random.Seed -> TileGrid -> (Maybe Tile, TileGrid, Random.Seed)
spawnGreen seed0 grid =
  if grid.greenCount == grid.maxGreens then
    (Nothing, grid, seed0)
  else
    let
      idxGenerator : Random.Generator (Int, Int)
      idxGenerator =
        Random.pair
          (Random.int 0 (grid.colCount - 1))
          (Random.int 0 (grid.colCount - 1))
      recur seed =
        let
          (idx, seed') = Random.step idxGenerator seed
        in
          case Dict.get idx grid.dict of
            Nothing ->
              -- random idx was not in bounds
              recur seed'
            Just tile ->
              if tile.green then
                -- tile already has a green
                recur seed'
              else if tile.kind /= Empty then
                -- tile was a wall
                recur seed'
              else
                -- empty tile, can insert green
                let
                  tile' = { tile | green = True }
                  tileGrid' =
                    insert idx tile' grid
                    |> (\grid -> { grid | greenCount = grid.greenCount + 1 })
                in
                  (Just tile', tileGrid', seed')
    in
      recur seed0


-- MAP BUILDING


-- toggleTile :


-- ENCODE


encode : TileGrid -> JE.Value
encode grid =
  JE.object
    [ "height" => JE.int (height grid)
    , "width" => JE.int (width grid)
    , "tiles" =>
        ( allTiles grid
          |> List.map Tile.encode
          |> JE.list
        )
    ]
