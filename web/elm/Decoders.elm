module Decoders exposing (fieldDecoder, errorsDecoder)

import Models exposing (..)

import Json.Decode as JSD
import Json.Decode.Pipeline exposing (decode, required, requiredAt, optional, optionalAt, hardcoded)

resultDecoder : JSD.Decoder GameResult
resultDecoder =
  let
    decodeToType int =
      case int of
        0 -> Result.Ok Undecided
        1 -> Result.Ok Win
        2 -> Result.Ok Loss
        _ -> Result.Err ("Not valid pattern for decoder to GameResult. Pattern: " ++ (toString int))
  in
    JSD.customDecoder JSD.int decodeToType

gridBlockDecoder : JSD.Decoder GridBlock
gridBlockDecoder =
  decode GridBlock
    |> required "value" JSD.int
    |> required "flagged" JSD.bool
    |> required "swept" JSD.bool


fieldDecoder : JSD.Decoder Field
fieldDecoder =
  decode Field
    |> requiredAt ["data", "id"]     JSD.string
    |> requiredAt ["data", "height"] JSD.int
    |> requiredAt ["data", "width"]  JSD.int
    |> requiredAt ["data", "count"]  JSD.int
    |> requiredAt ["data", "result"] resultDecoder
    |> requiredAt ["data", "grid"]   (JSD.array (JSD.array gridBlockDecoder))
    |> hardcoded Nothing

errorsDecoder : JSD.Decoder Errors
errorsDecoder =
  decode Errors
    |> optionalAt ["errors", "height"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "width"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "chance"] (JSD.list JSD.string) []
