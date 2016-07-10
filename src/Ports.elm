
port module Ports exposing (..)


-- Elm
import Json.Encode as JE


-- STATE BROADCAST


port broadcast : JE.Value -> Cmd msg

port grid : JE.Value -> Cmd msg

port bombHitWall : JE.Value -> Cmd msg

-- Sends the greened tile
port greenSpawned : JE.Value -> Cmd msg


-- SOUNDS


port playerHitWall : () -> Cmd msg

port playerBomb : () -> Cmd msg
