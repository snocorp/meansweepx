module Header exposing (header)

import Models exposing (..)

import Html exposing (Html, a, div, li, nav, text, ul)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)

header : Model -> Html Msg
header model =
  div [class "header"] [
    nav [class "navbar navbar-full navbar-light bg-faded"] ([
      a [class "navbar-brand", href "#!/"] [text "MeanSweep X"]
      ] ++ (returnToGame model))
    ]

returnToGame : Model -> List (Html Msg)
returnToGame model =
  case model.field of
    Just field ->
      [
        ul [class "nav navbar-nav"] [
          li [classList [("nav-item", True), ("active", (model.route == Game field.id))]] [
            a [class "nav-link", href ("#!/game/" ++ field.id), onClick (NavigateToGame field.id)] [text "Game"]
            ]
          ]
        ]
    Nothing ->
      []
