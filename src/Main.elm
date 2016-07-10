
module Main exposing (..)

-- https://github.com/yupferris/elmsteroids/blob/master/src/Main.elm

-- Elm Core
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (Time)
import Color
import Json.Encode as JE
import Task
-- 3rd
import Keyboard.Extra as KE
import Collage
import Element
import Numeral
-- 1st
import Vec exposing (Vec)
import Player
import TileGrid exposing (TileGrid)
import Util exposing ((=>))
import Ship
import Bombs exposing (Bomb)
import Tile
import Ports

-- MODEL


type alias Model =
  { -- To generate unique ids, we just increment this number
    nextId : Int
  , player : Player.Model
  , tileGrid : TileGrid
    -- Keeps track of which keys are currently pressed
  , keyboard : KE.Model
  , prevTick : Maybe Time
    -- Whether or not the simulation is unpaused
  , ticking : Bool
    -- Stores the current player collision for debugging
  , collision : Maybe TileGrid.CollisionResult
  , bombs : List Bomb
  , bombTime : Float
  }


init : x -> (Model, Cmd Msg)
init _ =
  let
    (kbModel, kbCmd) = KE.init
    tileGrid = TileGrid.default
  in
    ( { nextId = 2
      , player = Player.init 1 (Vec.make 100 100)
      , tileGrid = tileGrid
      , keyboard = kbModel
      , prevTick = Nothing
      , ticking = True
      , collision = Nothing
      , bombs = []
      , bombTime = 0
      }
    , Cmd.batch
        [ Cmd.map Keyboard kbCmd
          -- Send the tilegrid through the port to the JS side of our app
          -- so that it can initialize
        , Ports.grid (TileGrid.encode tileGrid)
        ]
    )


-- UPDATE


type Msg
  = NoOp
  | Keyboard KE.Msg
  | Tick Time
  | ToggleTick
  | ResetPrevTick Time


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    Keyboard kbMsg ->
      let
        (kbModel, kbCmd) = KE.update kbMsg model.keyboard
        -- On Spacebar, pause/unpause the game
        (model', cmd) =
          if KE.isPressed KE.Space kbModel then
            update ToggleTick model
          else
            update NoOp model
      in
        { model'
            | keyboard = kbModel
        }
        ! [ Cmd.map Keyboard kbCmd
          , cmd
          ]
    Tick now ->
      case model.prevTick of
        Nothing ->
          ({ model | prevTick = Just now }, Cmd.none)
        Just prev ->
          let
            -- Seconds since last tick
            delta = Time.inSeconds (now - prev)
            -- Update player position
            (player', result) =
              Player.tick delta model.keyboard model.tileGrid model.player
            -- Update bombs
            bombs = Bombs.tick delta model.tileGrid model.bombs
            -- Shoot bomb
            (bombs', bombTime, id', didShootBomb) =
              if KE.isPressed KE.CharF model.keyboard && model.bombTime >= 0 then
                ( Bombs.fire model.nextId model.player bombs
                , -1.0
                , model.nextId + 1
                , True
                )
              else
                (bombs, model.bombTime + delta, model.nextId, False)
          in
            { model
                | player = player'
                , prevTick = Just now
                , collision = Just result
                , bombs = bombs'
                , nextId = id'
                , bombTime = bombTime
            }
            ! [ -- Send every tick result to the JS side of our app
                Ports.broadcast (encodeBroadcast model)
                -- Play bounce sound if hit wall hard enough
                -- FIXME: sloppy as hell. also fix the dirs spam finally.
              , let
                  {dirs} = result
                  (vx, vy) = model.player.vel
                  threshold = 10
                  didCollide =
                    dirs.top || dirs.bottom || dirs.left || dirs.right
                  hitYHard =
                    (dirs.top || dirs.bottom) && abs vy > threshold
                  hitXHard =
                    (dirs.left || dirs.right) && abs vx > threshold
                in
                  if didCollide && (hitXHard || hitYHard)  then
                    Ports.playerHitWall ()
                  else
                    Cmd.none
                -- Play bomb sound
              , if didShootBomb then
                  Ports.playerBomb ()
                else
                  Cmd.none
              ]

    ResetPrevTick now ->
      ({ model | prevTick = Just now }, Cmd.none)
    ToggleTick ->
      let
        -- If transitioning from pause -> unpause, then reset the
        -- prevTick so that we don't calculate positions from
        -- the time before the pause.
        cmd =
          if model.ticking then
            Cmd.none
          else
            Task.perform identity ResetPrevTick Time.now
      in
        ( { model
              | ticking = not model.ticking
          }
        , cmd
        )


-- VIEW


view : Model -> Html Msg
view model =
  div
  []
  [ div
    [ class "overlay" ]
    [ button
      [ class "btn btn-default"
      , onClick ToggleTick
      ]
      [ text <| if model.ticking then "Pause" else "Unpause" ]
    , p
      [ style [ "display" => "inline-block"
              , "margin-left" => "10px"
              ]
      ]
      [ text "Arrows to move, F to bomb, Spacebar to pause" ]
    , ul
      []
      [ li [] [ text <| "pos: " ++ Vec.show 1 model.player.pos ]
      , li [] [ text <| "vel: " ++ Vec.show 1 model.player.vel ]
      , li [] [ text <| "acc: " ++ Vec.show 1 model.player.acc ]
      , let speed = (Numeral.format "0.0" (Vec.length model.player.vel))
        in li [] [ text <| "speed: " ++ speed ]
      , li [] [ text <| "angle: " ++ (toString (floor model.player.angle)) ]
      , let
          str =
            case model.collision of
              Nothing -> "--"
              Just result -> TileGrid.showCollisionResult result
        in li [] [ text <| "collisions: " ++ str ]
      ]
    ]
  ]


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    List.concat
      [ if model.ticking then
          [ Time.every (Time.millisecond * 20) Tick ]
        else
          []
      , [ Sub.map Keyboard KE.subscriptions ]
      ]
    |> Sub.batch


-- PORTS


encodeBroadcast : Model -> JE.Value
encodeBroadcast model =
  JE.object
    [ "player" => Player.encode model.player
    , "bombs" => Bombs.encodeN model.bombs
    ]


-- MAIN


main : Program ()
main =
  Html.App.programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
