
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
import TileGrid exposing (TileGrid)
import Util
import Starfield exposing (Starfield)
import Ship


-- MODEL


-- A cache of our Collage.Forms so all we need to do is transform
-- them instead of rebuilding them every update.
type alias Gfx =
  { starfield : Collage.Form
  , tileGrid : Collage.Form
  , ship : Collage.Form
  }


type alias Model =
  { player : Player.Model
  , tileGrid : TileGrid
  , keyboard : KE.Model
  , prevTick : Maybe Time
  , ticking : Bool
  , viewport : { x : Int, y : Int }
  , lastCollision : Vec
  , starfield : Starfield
  , gfx : Gfx
  , collision : Maybe TileGrid.CollisionResult
  }


init : { viewport : { x : Int, y: Int } } -> (Model, Cmd Msg)
init {viewport} =
  let
    (kbModel, kbCmd) = KE.init
    starfield = Starfield.init 2 600 "./img/starfield.jpg"
    tileGrid = TileGrid.default
  in
    ( { player = Player.init (Vec.make 100 100)
      , tileGrid = tileGrid
      , keyboard = kbModel
      , prevTick = Nothing
      , ticking = True
      , viewport = viewport
      , lastCollision = Vec.make 0 0
      , starfield = starfield
      , gfx =
          { starfield = Starfield.toForm viewport starfield
          , tileGrid = TileGrid.toForm (Util.toCoord viewport) tileGrid
          , ship = Ship.toForm
          }
      , collision = Nothing
      }
    , Cmd.map Keyboard kbCmd
    )


-- UPDATE


type Msg
  = NoOp
  | Keyboard KE.Msg
  | Tick Time
  | ViewportResized { x : Int, y : Int }
  | ToggleTick


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
            (player', result) =
              Player.tick delta model.keyboard model.tileGrid model.player
          in
            ( { model
                  | player = player'
                  , prevTick = Just now
                  , collision = Just result
                  -- , ticking =
                  --     if result.dirs.left || result.dirs.right
                  --        || result.dirs.top || result.dirs.bottom then
                  --       False
                  --     else
                  --       model.ticking
                  -- , lastCollision =
                  --     case maybeTile of
                  --       Nothing -> model.lastCollision
                  --       Just vector -> vector
              }
            , Cmd.none
            )
    ViewportResized viewport' ->
      let
        gfx = model.gfx
        gfx' =
          { gfx
              | starfield = Starfield.toForm viewport' model.starfield
              , tileGrid = TileGrid.toForm (Util.toCoord viewport') model.tileGrid
          }
      in
        ( { model
              | viewport = viewport'
              , gfx = gfx'
          }
        , Cmd.none
        )
    ToggleTick ->
      ({ model | ticking = not model.ticking }, Cmd.none)


-- VIEW


view : Model -> Html Msg
view model =
  let
    shipCoord =
      Util.toCoord model.viewport model.player.pos
    stage =
      Collage.collage model.viewport.x model.viewport.y
        [ Starfield.transform model.player.pos model.gfx.starfield model.starfield
        , TileGrid.transform model.viewport model.player.pos model.gfx.tileGrid
        , Ship.transform model.player.angle model.gfx.ship
          -- Show the tiles that will be checked for collision
        , TileGrid.tilesWithinPosRadius (15 + 8) model.player.pos model.tileGrid
          |> List.map
              (\tile ->
                  Collage.square 16
                  |> Collage.outlined  (Collage.solid Color.yellow)
                  |> Collage.move (Util.toCoord model.viewport tile.pos)
              )
          |> Collage.group
          |> Collage.moveX -(fst shipCoord)
          |> Collage.moveY -(snd shipCoord)
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
        , onClick ToggleTick
        ]
        [ text <| if model.ticking then "Pause" else "Unpause" ]
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
    Sub.batch
      [ Sub.map Keyboard KE.subscriptions
      , resizes ViewportResized
      ]


main : Program { viewport : { x : Int, y : Int } }
main =
  Html.App.programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }
