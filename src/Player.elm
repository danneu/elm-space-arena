
module Player exposing (..)


-- Elm
import Json.Encode as JE
-- 3rd
import Keyboard.Extra as KE
-- 1st
import Util
import Vec exposing (Vec)
import Friction
import TileGrid exposing (TileGrid)
import Util exposing ((=>))


type alias Model =
  { id : Int
  , pos : Vec
  , vel : Vec
  , acc : Vec
    -- Subangle is a float 0-359 that is used to calculate angle
    -- by clamping subangle to 9 degree intervals.
    -- Always use angle in calculations rather than subangle.
  , subangle : Float
    -- Angle is clamped to 9 degree intervals to allow players to hit perfect
    -- angles like 0deg, 90deg, 180deg, ... so they can for example shoot down
    -- a hallway or aim through a hole in the wall.
  , angle : Float
  , thrust : Float -- aka force. i.e. acceleration = thrust / mass
  , mass : Float
  , turnPerSecond : Float -- degrees
  , maxSpeed : Float
    -- The % of velocity lost per second
  , friction : Float
  }


init : Int -> Vec -> Model
init id pos =
  { id = id
  , pos = pos
  , vel = Vec.make 0 0
  , acc = Vec.make 0 0
  , subangle = 0
  , angle = 0
  , thrust = 1200
  , mass = 5
  , turnPerSecond = 250
  , maxSpeed = 200
  , friction = 0.25
  }


tick : Float -> KE.Model -> TileGrid -> Model -> (Model, TileGrid.CollisionResult)
tick delta keys tileGrid model =
  let
    nextSubangle =
      if KE.isPressed KE.ArrowLeft keys then
        Util.wrap360 <| model.subangle - (model.turnPerSecond * delta)
      else if KE.isPressed KE.ArrowRight keys then
        Util.wrap360 <| model.subangle + (model.turnPerSecond * delta)
      else
        model.subangle
    nextAngle =
      toFloat <| Util.nearestMultiple 9 nextSubangle
    nextAcc =
      let
        base =
          if KE.isPressed KE.ArrowUp keys then
            Vec.fromDeg model.angle
          else if KE.isPressed KE.ArrowDown keys then
            Vec.fromDeg model.angle
            |> Vec.reverse
          else
            Vec.make 0 0
      in
        Vec.multiply (model.thrust / model.mass) base
    nextVel =
      Vec.multiply delta nextAcc
      |> Vec.add model.vel
      |> Friction.applyWithThreshold delta model.friction 0.10
      |> enforceMaxSpeed model.maxSpeed
    (nextPos, nextVel', result) =
      let
        -- Bounce off walls with 75% of velocity leftover
        bounciness = 0.75
        minBounceVel = 0.50
        -- TODO: Apply friction again when ship hits a wall so that they
        --       lose speed when sliding along a wall.
        result = TileGrid.trace delta 30 model.pos nextVel tileGrid
        (vx, vy) = nextVel
        vx' =
          if result.dirs.left || result.dirs.right then
            if bounciness > 0 && abs vx > minBounceVel then
              -vx * bounciness
            else
              0
          else
            vx
        vy' =
          if result.dirs.top || result.dirs.bottom then
            if bounciness > 0 && abs vy > minBounceVel then
              -vy * bounciness
            else
              0
          else
            vy
      in
        (result.pos, Vec.make vx' vy', result)
  in
    ( { model
          | angle = nextAngle
          , subangle = nextSubangle
          , acc = nextAcc
          , vel = nextVel'
          , pos = nextPos
      }
    , result
    )


enforceMaxSpeed : Float -> Vec -> Vec
enforceMaxSpeed maxSpeed vel =
  if Vec.length vel > maxSpeed then
    Vec.multiply (maxSpeed / Vec.length vel) vel
  else
    vel


nose : Model -> Vec
nose {pos, angle} =
  let
    r = 15
    (x, y) = pos
    noseX = x + r * (cos <| degrees <| angle - 90)
    noseY = y + r * (sin <| degrees <| angle - 90)
  in
    Vec.make noseX noseY


-- JSON


encode : Model -> JE.Value
encode {pos, acc, angle} =
  JE.object
    [ "pos" => Vec.encode pos
    , "acc" => Vec.encode acc
    , "angle" => JE.float (degrees angle)
    ]
