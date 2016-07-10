
module Vec exposing (..)

-- Elm
import String
import Json.Encode as JE
-- 3rd
import Numeral


type alias Vec = (Float, Float)


make : Float -> Float -> Vec
make x y =
  (x, y)


fromDeg : Float -> Vec
fromDeg deg =
  let
    rad = degrees deg
  in
    make (sin rad) -(cos rad)


add : Vec -> Vec -> Vec
add (x1, y1) (x2, y2) =
  make (x1 + x2) (y1 + y2)


subtract : Vec -> Vec -> Vec
subtract (x1, y1) (x2, y2) =
  make (x1 - x2) (y1 - y2)


multiply : Float -> Vec -> Vec
multiply scalar (x, y) =
  make (x * scalar) (y * scalar)


divide : Float -> Vec -> Vec
divide scalar (x, y) =
  make (x / scalar) (y / scalar)


-- The speed of an entity is the length of its velocity vector.
length : Vec -> Float
length (x, y) =
  sqrt (x ^ 2 + y ^ 2)


perpendicular : Vec -> Vec
perpendicular (x, y) =
  make -y x


distance : Vec -> Vec -> Float
distance v1 v2 =
  length <| subtract v2 v2


normalize : Vec -> Vec
normalize ((x, y) as vec) =
  let
    len = length vec
  in
    make (x / len) (y / len)


rotate : Float -> Vec -> Vec
rotate angle (x, y) =
  let
    c = cos (degrees angle)
    s = sin (degrees angle)
  in
    make -(x * c - y * s) -(x * s + y * c)


reverse : Vec -> Vec
reverse vector =
  multiply -1 vector


show : Int -> Vec -> String
show decimalPad (x, y) =
  let
    suffix =
      if decimalPad == 0 then
        ""
      else
        "." ++ String.repeat decimalPad "0"
    format n =
      Numeral.format ("0,0" ++ suffix) n
  in
    "(" ++ format x ++ ", " ++ format y ++ ")"


-- JSON


encode : Vec -> JE.Value
encode (x, y) =
  JE.object
    [ ("x", JE.float x)
    , ("y", JE.float y)
    ]
