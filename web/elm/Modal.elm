module Modal exposing (confirmModal, backdrop)

import Models exposing (..)

import Html exposing (Html, a, button, div, h4, li, nav, span, text, ul)
import Html.Attributes exposing (class, classList, href, type_)
import Html.Events exposing (onClick)

confirmModal : Model -> Html Msg
confirmModal model =
  let
    showModal = model.newGameSpec /= Nothing
    newGameOnClick =
      case model.newGameSpec of
        Just gameSpec ->
          [onClick (NewGame gameSpec True)]
        Nothing ->
          []
  in
    div [classList [("modal", True), ("fade", True), ("in", showModal), ("d-block", showModal)]] [
      div [class "modal-dialog"] [
        div [class "modal-content"] [
          div [class "modal-header"] [
            button [type_ "button", class "close", onClick NewGameCancel] [
              span [] [text "×"]
              ],
            h4 [class "modal-title"] [text "Are you sure?"]
            ],
          div [class "modal-body"] [text "You have an ongoing game. Are you sure you want to start a new one?"],
          div [class "modal-footer"] [
            button [type_ "button", class "btn btn-secondary", onClick NewGameCancel] [text "Cancel"],
            text " ",
            button ([type_ "button", class "btn btn-primary"] ++ newGameOnClick) [text "New Game"]
            ]
          ]
        ]
      ]

backdrop : Model -> Html Msg
backdrop model =
  let
    showBackdrop = model.newGameSpec /= Nothing
  in
    div [
      classList [
        ("modal-backdrop", True),
        ("fade", True),
        ("in", showBackdrop),
        ("hidden-xs-up", not showBackdrop)
        ]
      ] []
