
module Ship exposing (..)

-- Elm
import Color
-- 3rd
import Collage
import Element
-- 1st
import Vec exposing (Vec)


draw : Float -> Collage.Form
draw angle =
  let
    shipForm =
      Element.image 30 30 "/img/warbird.gif"
      |> Collage.toForm
      |> Collage.rotate (degrees -angle)
  in
    Collage.group
      [ shipForm
        -- Collision box
      , Collage.square 30
        |> Collage.outlined (Collage.solid Color.white)
      ]
