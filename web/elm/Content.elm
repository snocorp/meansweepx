module Content exposing (content)

import Models exposing (..)
import Alert exposing (..)
import Grid exposing (gridSvg)

import Html exposing (Html, a, button, div, form, h1, h4, input, label, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, for, href, id, max, min, type_, value)
import Html.Events exposing (onClick, onInput)

content : Model -> Html Msg
content model =
  case model.route of
    Index ->
      div [class "container"] [
        div [class "jumbotron"] [
          h1 [class "display-3"] [text "sweep!"],
          p [class "lead"] [text "Start a new game by choosing a mine field below"]
          ],
        errorAlert model.error.errorMsg,
        div [class "row"] [
          minefieldCard 8 8 15,
          minefieldCard 12 12 15,
          minefieldCard 16 16 15,
          minefieldCard 24 24 15,
          minefieldCard 32 16 20,
          minefieldCard 32 32 20
          ],
        div [class "row"] [
          div [class "col-sm-8 offset-sm-2"] [
            div [class "card card-block"] [
              h4 [class "card-title"] [text "Custom"],
              form [] [
                customFormInput model.customGameSpec.width "Field width" "width" model.error.widthError ChangeCustomWidth,
                customFormInput model.customGameSpec.height "Field height" "height" model.error.heightError ChangeCustomHeight,
                customFormInput model.customGameSpec.chance "Percent bomb coverage" "chance" model.error.chanceError ChangeCustomChance,
                button [type_ "button", class "btn btn-secondary", onClick (NewGame model.customGameSpec False)] [text "Play"]
                ]
              ]
            ]
          ]
        ]

    Game gameId ->
      div [class "container"]
        (case model.field of
          Nothing ->
            [div [] [text "No game"]]

          Just field ->
            let
              winResult =
                case field.result of
                  Win ->
                    Just "Congratulations! The map is clear."
                  _ ->
                    Nothing
              lossResult =
                case field.result of
                  Loss ->
                    Just "You lose. Better luck next time."
                  _ ->
                    Nothing
            in
              [
                errorAlert model.error.errorMsg,
                dangerAlert lossResult,
                successAlert winResult,
                Grid.gridSvg field
                ])

minefieldCard : Int -> Int -> Int -> Html Msg
minefieldCard h w c =
  div [class "col-sm-4"] [
    div [class "card card-block card-clickable", onClick (NewGame (GameSpec h w c) False)] [
      h4 [class "card-title"] [text ((toString h) ++ " x " ++ (toString w))],
      p [class "card-text"] [text ((toString c) ++ "% mine coverage")]
      ]
    ]

customFormInput : Int -> String -> String -> Maybe String -> (String -> Msg) -> Html Msg
customFormInput fieldValue fieldLabel fieldId error changeHandler =
  let
    hasError = error /= Nothing
  in
    div [classList [("form-group", True), ("has-danger", hasError)]] ([
      label [for fieldId, class "control-label"] [text fieldLabel],
      input [
        type_ "number",
        Html.Attributes.max "100",
        Html.Attributes.min "1",
        classList [("form-control", True), ("form-control-danger", hasError)],
        id fieldId,
        value (toString fieldValue),
        onInput changeHandler
        ] []
      ] ++ customFormInputFeedback error)

customFormInputFeedback : Maybe String -> List (Html Msg)
customFormInputFeedback error =
  case error of
    Nothing -> []
    Just errorMsg -> [
      span [class "form-control-feedback"] [text errorMsg]
      ]
