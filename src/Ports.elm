
port module Ports exposing (..)


-- Elm
import Json.Encode as JE

--
-- INCOMING
--


port tileClicked : ((Int, Int) -> msg) -> Sub msg


--
-- OUTGOING
--


-- STATE BROADCAST


port broadcast : JE.Value -> Cmd msg

port grid : JE.Value -> Cmd msg

port bombHitWall : JE.Value -> Cmd msg

-- Sends the greened tile
port greenSpawned : JE.Value -> Cmd msg

-- Sends list of tiles that were scavenged of their green
port greensCollected : JE.Value -> Cmd msg


-- SOUNDS


port playerHitWall : () -> Cmd msg

port playerBomb : () -> Cmd msg



-- MAP BUILDING


port tileUpdated : JE.Value -> Cmd msg
