module Alert exposing (errorAlert, dangerAlert, successAlert)

import Models exposing (..)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, classList, type_)
import Html.Events exposing (onClick)

errorAlert : Maybe String -> Html Msg
errorAlert error =
  case error of
    Nothing ->
      div [] []
    Just errorMsg ->
      div [classList [("alert", True), ("alert-danger", True)]] [
        button [type_ "button", class "close", onClick ClearErrorMessage] [text "×"],
        span [] [text errorMsg]
        ]

dangerAlert : Maybe String -> Html Msg
dangerAlert maybeMsg =
  alert "danger" maybeMsg

successAlert : Maybe String -> Html Msg
successAlert maybeMsg =
  alert "success" maybeMsg

alert : String -> Maybe String -> Html Msg
alert alertType maybeMsg =
  case maybeMsg of
    Nothing ->
      div [] []
    Just msg ->
      div [classList [("alert", True), ("alert-" ++ alertType, True)]] [
        span [] [text msg]
        ]
