
port module Main exposing (..)

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


-- MODEL


type alias Model =
  { nextId : Int
  , player : Player.Model
  , tileGrid : TileGrid
  , keyboard : KE.Model
  , prevTick : Maybe Time
  , ticking : Bool
  , lastCollision : Vec
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
    ( { nextId = 1
      , player = Player.init (Vec.make 100 100)
      , tileGrid = tileGrid
      , keyboard = kbModel
      , prevTick = Nothing
      , ticking = True
      , lastCollision = Vec.make 0 0
      , collision = Nothing
      , bombs = []
      , bombTime = 0
      }
    , Cmd.batch
        [ Cmd.map Keyboard kbCmd
        , grid (JE.encode 0 (TileGrid.encode tileGrid))
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
            (player', result) =
              Player.tick delta model.keyboard model.tileGrid model.player
            bombs = Bombs.tick delta model.bombs
            (bombs', bombTime, id') =
              if KE.isPressed KE.CharF model.keyboard && model.bombTime >= 0 then
                ( Bombs.fire model.nextId model.player bombs,
                  -1.0,
                  model.nextId + 1
                )
              else
                (bombs, model.bombTime + delta, model.nextId)
          in
            ( { model
                  | player = player'
                  , prevTick = Just now
                  , collision = Just result
                  , bombs = bombs'
                  , nextId = id'
                  , bombTime = bombTime
              }
            , broadcast (encodeBroadcast model)
            )
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
      [ li [] [ text <| "pos: " ++ Vec.show 0 model.player.pos ]
      , li [] [ text <| "vel: " ++ Vec.show 2 model.player.vel ]
      , li [] [ text <| "acc: " ++ Vec.show 2 model.player.acc ]
      , li
        []
        [ text <|
            "spd: " ++ (Numeral.format "0.00" (Vec.length model.player.vel))
        ]
      , li [] [ text <| "angle: " ++ (Numeral.format "0.00" model.player.angle) ]
      , li
        []
        [ text
            <| "collisions: " ++
                case model.collision of
                  Nothing -> "--"
                  Just result -> TileGrid.showCollisionResult result
        ]
      , li
        []
        [ text <| "bombs: " ++ toString (List.length model.bombs) ]
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


encodeBroadcast : Model -> String
encodeBroadcast model =
  JE.object
    [ ("player", Player.encode model.player)
    , ("bombs", (Bombs.encodeN model.bombs))
    ]
  |> JE.encode 0


port broadcast : String -> Cmd msg
port newBomb : String -> Cmd msg
port grid : String -> Cmd msg


-- MAIN


main : Program ()
main =
  Html.App.programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
