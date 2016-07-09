
port module Main exposing (..)

-- https://github.com/yupferris/elmsteroids/blob/master/src/Main.elm

-- Elm Core
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (Time)
import Color
-- 3rd
import Keyboard.Extra as KE
import Collage
import Element
import Numeral
-- 1st
import Vec exposing (Vec)
import Player
import CollisionMap exposing (CollisionMap)
import Util
import Starfield exposing (Starfield)
import Ship


-- MODEL


type alias Model =
  { player : Player.Model
  , collisionMap : CollisionMap
  , keyboard : KE.Model
  , prevTick : Maybe Time
  , ticking : Bool
  , viewport : { x : Int, y : Int }
  , starfield : Starfield
  , lastCollision : Vec
  }


init : { viewport : { x : Int, y: Int } } -> (Model, Cmd Msg)
init {viewport} =
  let
    (kbModel, kbCmd) = KE.init
  in
    ( { player = Player.init (Vec.make 100 100)
      , collisionMap = CollisionMap.default
      , keyboard = kbModel
      , prevTick = Nothing
      , ticking = True
      , viewport = viewport
      , starfield = Starfield.init 2 600 "/img/starfield.jpg"
      , lastCollision = Vec.make 0 0
      }
    , Cmd.map Keyboard kbCmd
    )


-- UPDATE


type Msg
  = NoOp
  | Keyboard KE.Msg
  | Tick Time
  | ViewportResized { x : Int, y : Int }
  | StopTick


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    Keyboard kbMsg ->
      let
        (kbModel, kbCmd) = KE.update kbMsg model.keyboard
      in
        { model
            | keyboard = kbModel
        }
        ! [Cmd.map Keyboard kbCmd]
    Tick now ->
      case model.prevTick of
        Nothing ->
          ({ model | prevTick = Just now }, Cmd.none)
        Just prev ->
          let
            -- Seconds since last tick
            delta : Time
            delta = Time.inSeconds (now - prev)
            (player', maybeTile) = Player.tick delta model.keyboard model.collisionMap model.player
          in
            ( { model
                  | player = player'
                  , prevTick = Just now
                  , lastCollision =
                      case maybeTile of
                        Nothing -> model.lastCollision
                        Just vector -> vector
              }
            , Cmd.none
            )
    ViewportResized viewport' ->
      ({ model | viewport = viewport'}, Cmd.none)
    StopTick ->
      ({ model | ticking = False }, Cmd.none)


-- VIEW


view : Model -> Html Msg
view model =
  let
    shipCoord =
      Util.toCoord model.viewport model.player.pos
    stage =
      Collage.collage model.viewport.x model.viewport.y
        [ Starfield.draw model.viewport model.player.pos model.starfield
        , CollisionMap.draw model.lastCollision (Util.toCoord model.viewport) model.collisionMap
          |> Collage.moveX -(fst shipCoord)
          |> Collage.moveY -(snd shipCoord)
        , Ship.draw model.player.angle
        ]
      |> Element.toHtml
  in
    div
    []
    [ stage
    , div
      [ class "overlay" ]
      [ button
        [ class "btn btn-default"
        , onClick StopTick
        ]
        [ text "Stop" ]
      , ul
        []
        [ li [] [ text <| "pos: " ++ Vec.show 0 model.player.pos ]
        , li [] [ text <| "vel: " ++ Vec.show 2 model.player.vel ]
        , li [] [ text <| "acc: " ++ Vec.show 2 model.player.acc ]
        , li
          []
          [ text <| "spd: " ++ (Numeral.format "0.00" (Vec.length model.player.vel)) ]
        , li [] [ text <| "angle: " ++ (Numeral.format "0.00" model.player.angle) ]
        ]
      ]
    ]


-- SUBSCRIPTIONS

port resizes : ({ x : Int, y : Int } -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  if model.ticking then
    Sub.batch
      [ Sub.map Keyboard KE.subscriptions
      , Time.every (Time.millisecond * 20) Tick
      , resizes ViewportResized
      ]
  else
    Sub.none


main : Program { viewport : { x : Int, y : Int } }
main =
  Html.App.programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
