
module Player exposing (..)


-- Elm
import Time exposing (Time)
-- 3rd
import Keyboard.Extra as KE
-- 1st
import Util
import Vec exposing (Vec)
import Friction
import CollisionMap exposing (CollisionMap)


type alias Model =
  { pos : Vec
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
  , thrust : Float
  , turnPerSecond : Float
  , maxSpeed : Float
  , friction : Float
  }


init : Vec -> Model
init pos =
  { pos = pos
  , vel = Vec.make 0 0
  , acc = Vec.make 0 0
  , subangle = 0
  , angle = 0
  , thrust = 200
  , turnPerSecond = 250 -- Degrees the ship can turn per second
  , maxSpeed = 3
  , friction = 0.25 -- The % of velocity lost per second
  }


-- delta is seconds
tick : Time -> KE.Model -> CollisionMap -> Model -> (Model, Maybe Vec)
tick delta keys collisionMap model =
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
      (
      if KE.isPressed KE.ArrowUp keys then
        Vec.fromDeg model.angle
      else if KE.isPressed KE.ArrowDown keys then
        Vec.fromDeg model.angle
        |> Vec.multiply -1
      else
        Vec.make 0 0
      )
      |> Vec.multiply (delta * model.thrust)
    nextVel =
      Vec.multiply delta nextAcc
      |> Vec.add model.vel
      |> Friction.applyWithThreshold delta model.friction 0.10
      |> enforceMaxSpeed model.maxSpeed
    (nextPos, nextVel', maybeTile) =
      let
        result =
          CollisionMap.trace 30 model.pos nextVel collisionMap
        (nextVelX, nextVelY) = nextVel
        vx =
          if result.collision.x then
            -nextVelX * 0.9
          else
            nextVelX
        vy =
          if result.collision.y then
            -nextVelY * 0.9
          else
            nextVelY
      in
        (result.pos, Vec.make vx vy, result.tile)
  in
    ( { model
          | angle = nextAngle
          , subangle = nextSubangle
          , acc = nextAcc
          , vel = nextVel'
          , pos = nextPos
      }
    , maybeTile
    )


enforceMaxSpeed : Float -> Vec -> Vec
enforceMaxSpeed maxSpeed vel =
  if Vec.length vel > maxSpeed then
    Vec.multiply (maxSpeed / Vec.length vel) vel
  else
    vel
