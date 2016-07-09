
module CollisionMap exposing (..)


-- Elm
import Array exposing (Array)
import Color
-- 3rd
import Collage
-- 1st
import CollisionTile exposing (CollisionTile, Kind(..))
import Util
import Vec exposing (Vec)
import Collision.Bounds


{- I am bad at math.
-}


-- Not sure how I want this datastructure to look, so I'll
-- store random configurations in this junk drawer.
type alias CollisionMapRecord =
  { rows : Array (Array CollisionTile)
  , tiles : List CollisionTile
  }


type alias CollisionMap = CollisionMapRecord


type alias CollisionResult =
  { collision : { x : Bool, y : Bool }
  , pos : Vec
  , tile : Maybe Vec
  }


tileSize : Int
tileSize = 16


default : CollisionMap
default =
  let
    xformTile : Int -> Int -> CollisionTile.Kind -> CollisionTile
    xformTile y colIdx kind =
      let
        x = colIdx * tileSize
      in
        CollisionTile.make x y tileSize kind
    xformRow : Int -> (List CollisionTile.Kind) -> (List CollisionTile)
    xformRow rowIdx row =
      let
        y = rowIdx * tileSize
      in
        List.indexedMap (xformTile y) row
  in
  List.concatMap identity
    [ [List.repeat 64 Box]
    , List.repeat 18 (List.concat [ [Box], (List.repeat 62 Empty), [Box] ])
    , [List.repeat 64 Box]
    ]
  |> List.indexedMap xformRow
  |> List.map Array.fromList
  |> Array.fromList
  |> (\rows ->
        let
          isBox tile =
            case tile.kind of
              Box -> True
              _ -> False
        in
          { rows = rows
          , tiles =
              rows
              |> Array.toList
              |> List.concatMap (List.filter isBox << Array.toList)
          }
     )


rowCount : CollisionMap -> Int
rowCount {rows} =
  Array.length rows


colCount : CollisionMap -> Int
colCount {rows} =
  case Array.get 0 rows of
    Nothing ->
      Debug.crash "Impossible, a CollisionMap always has at least one row"
    Just row ->
      Array.length row


width : CollisionMap -> Int
width map =
  tileSize * (colCount map)


height : CollisionMap -> Int
height map =
  tileSize * (rowCount map)


trace : Int -> Vec -> Vec -> CollisionMap -> CollisionResult
trace width prevPos vel map =
  let
    nextPos = Vec.add prevPos vel
    nextObjBounds = Collision.Bounds.fromPoint (toFloat width / 2) nextPos
    accum ts =
      case ts of
        [] ->
          { pos = nextPos
          , collision = { x = False, y = False }
          , tile = Nothing
          }
        t :: rest ->
          case t.kind of
            Box ->
              if Collision.Bounds.overlap nextObjBounds t.bounds then
                let
                  prevObjBounds =
                    Collision.Bounds.fromPoint (toFloat width / 2) prevPos
                  -- FIXME: Dumb, barely-working logic
                  collidesX =
                    (prevObjBounds.left > t.bounds.right)
                    || (prevObjBounds.right < t.bounds.left)
                in
                  { pos = prevPos
                  , collision = { x = collidesX, y = not collidesX }
                  , tile = Just t.pos
                  }
              else
                accum rest
            Empty ->
              accum rest
  in
    accum map.tiles


draw : Vec -> (Vec -> (Float, Float)) -> CollisionMap -> Collage.Form
draw ((lastX, lastY) as lastCollision) toCoord map =
  map.tiles
  |> List.map (\tile ->
       let
         (x, y) = tile.pos
       in
       case CollisionTile.draw tile of
         Nothing ->
           Nothing
         Just form ->
           ( if lastX == x && lastY == y then
               Collage.square 16 |> Collage.filled Color.red
             else
               form
           )
           |> Collage.move (toCoord (Vec.make x y))
           |> Just
     )
  |> List.filter Util.isJust
  |> List.map Util.unwrapMaybe
  |> Collage.group
