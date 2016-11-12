module Decoders exposing (fieldDecoder, errorsDecoder)

import Models exposing (..)

import Json.Decode as JSD
import Json.Decode.Pipeline exposing (decode, hardcoded, nullable, optional, optionalAt, required, requiredAt, resolveResult)
import Time.DateTime as DateTime exposing (DateTime)

dateTimeDecoder : JSD.Decoder DateTime
dateTimeDecoder =
  JSD.customDecoder JSD.string DateTime.fromISO8601

resultDecoder : JSD.Decoder GameResult
resultDecoder =
  let
    decodeToType int =
      case int of
        0 -> Result.Ok Undecided
        1 -> Result.Ok Win
        2 -> Result.Ok Loss
        _ -> Result.Err ("Not a valid pattern for decoder to GameResult. Pattern: " ++ (toString int))
  in
    JSD.customDecoder JSD.int decodeToType

gridBlockDecoder : JSD.Decoder GridBlock
gridBlockDecoder =
  let
    asResult : Int -> Bool -> Bool -> Result String GridBlock
    asResult value flagged swept =
      Ok (GridBlock value flagged swept)
  in
    decode asResult
      |> required "v" JSD.int
      |> required "f" JSD.bool
      |> required "s" JSD.bool
      |> resolveResult


fieldDecoder : JSD.Decoder Field
fieldDecoder =
  decode Field
    |> requiredAt ["data", "id"]     JSD.string
    |> requiredAt ["data", "height"] JSD.int
    |> requiredAt ["data", "width"]  JSD.int
    |> requiredAt ["data", "count"]  JSD.int
    |> requiredAt ["data", "result"] resultDecoder
    |> requiredAt ["data", "grid"]   (JSD.array (JSD.array gridBlockDecoder))
    |> requiredAt ["data", "started"] dateTimeDecoder
    |> requiredAt ["data", "finished"] (nullable dateTimeDecoder)
    |> hardcoded Nothing

errorsDecoder : JSD.Decoder Errors
errorsDecoder =
  decode Errors
    |> optionalAt ["errors", "height"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "width"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "chance"] (JSD.list JSD.string) []
