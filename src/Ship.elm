
module Ship exposing (..)

-- Elm
import Color
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)


-- RENDER


toForm : Collage.Form
toForm =
  Element.image 30 30 "./img/warbird.gif"
  |> Collage.toForm


collisionBox : Collage.Form
collisionBox =
  Collage.square 30
  |> Collage.outlined (Collage.solid Color.white)


transform : Float -> Collage.Form -> Collage.Form
transform angle shipForm =
  Collage.group
    [ shipForm
      |> Collage.rotate (degrees -angle)
    , collisionBox
    ]


-- OLD
-- draw : Float -> Collage.Form
-- draw angle =
--   let
--     shipForm =
--       Element.image 30 30 "./img/warbird.gif"
--       |> Collage.toForm
--       |> Collage.rotate (degrees -angle)
--   in
--     Collage.group
--       [ shipForm
--         -- Collision box
--       , Collage.square 30
--         |> Collage.outlined (Collage.solid Color.white)
--       ]
