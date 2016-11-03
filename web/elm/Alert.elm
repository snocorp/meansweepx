module Alert exposing (errorAlert)

import Models exposing (..)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, classList, type')
import Html.Events exposing (onClick)

errorAlert : Maybe String -> Html Msg
errorAlert error =
  case error of
    Nothing ->
      div [] []
    Just errorMsg ->
      div [classList [("alert", True), ("alert-danger", True)]] [
        button [type' "button", class "close", onClick ClearErrorMessage] [text "×"],
        span [] [text errorMsg]
        ]
