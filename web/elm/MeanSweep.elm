module MeanSweep exposing (..)

import Models exposing (..)
import Header
import Grid exposing (gridRows)

import Html exposing (Html, a, button, div, form, h1, h4, input, label, li, nav, p, span, text, ul)
import Html.App as App
import Html.Attributes exposing (class, classList, for, href, id, max, min, type', value)
import Html.Events exposing (onClick, onInput)
import HttpBuilder as Http exposing (jsonReader, send, stringReader, withHeader, withJsonBody, withTimeout)
import Json.Decode as JSD
import Json.Decode.Pipeline exposing (decode, required, requiredAt, optional, optionalAt, hardcoded)
import Json.Encode as JSE
import Navigation
import String exposing (join)
import Svg exposing (svg)
import Svg.Attributes exposing (viewBox, width)
import Task
import Time

main =
  Navigation.program
    (Navigation.makeParser hashParser)
    {
      init = init,
      update = update,
      urlUpdate = urlUpdate,
      subscriptions = subscriptions,
      view = view
      }

hashParser : Navigation.Location -> Result String Route
hashParser location =
  let
    path = (Debug.log "location.hash" (String.dropLeft 2 location.hash))
  in
    if (String.startsWith "/game/" path) && (String.length path) == 42 then
      Ok (Game (String.right 36 path))
    else
      Ok Index

emptyError : Error
emptyError =
  Error
    Nothing
    Nothing
    Nothing
    Nothing

-- INIT

init : Result String Route -> (Model, Cmd Msg)
init result =
  let
    spec = GameSpec 0 0 0
    model = Model
      Index
      emptyError
      spec
      Nothing
      Nothing
    cmd = case result of
      Ok route ->
        case route of
          Index ->
            Debug.log "ok->Index" Cmd.none
          Game gameId ->
            Debug.log ("ok->Game "++gameId) (loadGame gameId)
      Err error ->
        Debug.log "err" Cmd.none
  in
    (model, cmd)


-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewGame gameSpec confirm ->
      case model.field of
        Nothing ->
          ({model | newGameSpec = Nothing}, newGame gameSpec)
        Just field ->
          -- TODO improve to detect resolved games
          if confirm then
            ({model | newGameSpec = Nothing}, newGame gameSpec)
          else
            ({model | newGameSpec = Just gameSpec}, Cmd.none)

    NewGameCancel ->
      ({model | newGameSpec = Nothing}, Cmd.none)
    NewGameSucceed response ->
      let
        newField = response.data
        fieldId = Debug.log "fieldId" newField.id
      in
        ({model | field = Just newField}, Navigation.newUrl ("#!/game/" ++ fieldId))
        --update (NavigateToGame newField.id) {model | field = Just newField}

    NewGameFail err ->
      let
        modelError = model.error
        message = case err of
          Http.Timeout ->
            "It took too long to create a new game. Please try again."
          Http.NetworkError ->
            "There was a problem trying to create a new game. Please try again."
          Http.UnexpectedPayload details ->
            details
          Http.BadResponse response ->
            case response.status of
              422 ->
                "There was a problem trying to create a new game. Check the chosen values."
              _ ->
                response.statusText
        error = case err of
          Http.BadResponse response ->
            {modelError |
              errorMsg = Just message,
              heightError = List.head response.data.height,
              widthError = List.head response.data.width,
              chanceError = List.head response.data.chance
              }
          _ ->
            {modelError |
              errorMsg = Just message,
              heightError = Nothing,
              widthError = Nothing,
              chanceError = Nothing
              }

      in
        ({model | error = error}, Cmd.none)

    LoadGame gameId confirm ->
      case model.field of
        Nothing ->
          (model, loadGame gameId)
        Just field ->
          if confirm then
            (model, loadGame gameId)
          else
            (model, Cmd.none)

    LoadGameSucceed response ->
      let
        newField = response.data
      in
        update (NavigateToGame newField.id) {model | field = Just newField}

    LoadGameFail err ->
      let
        error = model.error
        message = case err of
          Http.Timeout ->
            "It took too long to load the game. Please try again."
          Http.NetworkError ->
            "There was a problem trying to load the game. Please try again."
          Http.UnexpectedPayload details ->
            details
          Http.BadResponse response ->
            case response.status of
              404 ->
                "Game not found. Check the URL."
              _ ->
                response.data
      in
        ({model | error = {error | errorMsg = Just message}}, Cmd.none)

    Flag ->
      (model, Cmd.none)

    Sweep ->
      (model, Cmd.none)

    NavigateToIndex ->
      ({model | route = Index}, Cmd.none)

    NavigateToGame gameId ->
      ({model | route = Game gameId}, Cmd.none)

    ChangeCustomHeight heightStr ->
      let
        gameSpec = model.customGameSpec
        error = model.error
      in
        case String.toInt heightStr of
          Ok h ->
            ({model |
              customGameSpec = {gameSpec | height = h},
              error = {error | heightError = Nothing}}, Cmd.none)
          Err err ->
            ({model |
              error = {error | heightError = Just "Height must be an integer"}}, Cmd.none)

    ChangeCustomWidth widthStr ->
      let
        gameSpec = model.customGameSpec
        error = model.error
      in
        case String.toInt widthStr of
          Ok w ->
            ({model |
              customGameSpec = {gameSpec | width = w},
              error = {error | widthError = Nothing}}, Cmd.none)
          Err err ->
            ({model |
              error = {error | widthError = Just "Width must be an integer"}}, Cmd.none)

    ChangeCustomChance chanceStr ->
      let
        gameSpec = model.customGameSpec
        error = model.error
      in
        case String.toInt chanceStr of
          Ok c ->
            ({model |
              customGameSpec = {gameSpec | chance = c},
              error = {error | chanceError = Nothing}}, Cmd.none)
          Err err ->
            ({model |
              error = {error | chanceError = Just "Chance must be an integer"}}, Cmd.none)

urlUpdate : Result String Route -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  let
    route = case result of
      Ok route ->
        (Debug.log "route" (toString route))
      Err error ->
        (Debug.log "error" error)
    modelError = model.error
  in
    case result of
      Ok route ->
        case route of
          Index ->
            ({model |
              error = {modelError | errorMsg = Nothing},
              route = route}, Cmd.none)
          Game gameId ->
            case model.field of
              Just field ->
                if field.id == gameId then
                  ({model | route = route}, Cmd.none)
                else
                  ({model | field = Nothing}, (loadGame gameId))
              Nothing ->
                (model, (loadGame gameId))
      Err err ->
        ({model | error = {modelError | errorMsg = Just err}}, Cmd.none)


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
    |> requiredAt ["data", "grid"]   (JSD.list (JSD.list gridBlockDecoder))

errorsDecoder : JSD.Decoder Errors
errorsDecoder =
  decode Errors
    |> optionalAt ["errors", "height"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "width"] (JSD.list JSD.string) []
    |> optionalAt ["errors", "chance"] (JSD.list JSD.string) []

newGame : GameSpec -> Cmd Msg
newGame gameSpec =
  let
    params = JSE.object [
      ("height", JSE.int gameSpec.height),
      ("width", JSE.int gameSpec.width),
      ("chance", JSE.int gameSpec.chance)
      ]
  in
    Task.perform NewGameFail NewGameSucceed (
      Http.post "/api/fields/"
        |> withJsonBody params
        |> withHeader "Content-Type" "application/json"
        |> withTimeout (1 * Time.second)
        |> send (jsonReader fieldDecoder) (jsonReader errorsDecoder)
      )

loadGame : String -> Cmd Msg
loadGame gameId =
  Task.perform LoadGameFail LoadGameSucceed (
    Http.get ("/api/fields/" ++ gameId)
      |> withHeader "Content-Type" "application/json"
      |> withTimeout (1 * Time.second)
      |> send (jsonReader fieldDecoder) stringReader
    )

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- VIEW

view : Model -> Html Msg
view model =
  div [class "modal-open"] [
    Header.header model,
    content model,
    confirmModal model,
    backdrop model
    ]

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
                button [type' "button", class "btn btn-secondary", onClick (NewGame model.customGameSpec False)] [text "Play"]
                ]
              ]
            ]
          ]
        ]

    Game gameId ->
      div [class "container"] [
        case model.field of
          Nothing ->
            div [] [text "TODO: No game"]

          Just field ->
            svg [ viewBox (gridViewBox field.width field.height), width "100%" ]
              (gridRows field.grid)
        ]

gridViewBox : Int -> Int -> String
gridViewBox h w =
  String.join " " (List.map toString [0, 0, w * 100, h * 100])

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
        type' "number",
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

errorAlert : Maybe String -> Html Msg
errorAlert error =
  case error of
    Nothing ->
      div [] []
    Just errorMsg ->
      div [classList [("alert", True), ("alert-danger", True)]] [
        button [type' "button", class "close"] [text "×"],
        span [] [text errorMsg]
        ]

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
            button [type' "button", class "close", onClick NewGameCancel] [
              span [] [text "×"]
              ],
            h4 [class "modal-title"] [text "Are you sure?"]
            ],
          div [class "modal-body"] [text "You have an ongoing game. Are you sure you want to start a new one?"],
          div [class "modal-footer"] [
            button [type' "button", class "btn btn-secondary", onClick NewGameCancel] [text "Cancel"],
            text " ",
            button ([type' "button", class "btn btn-primary"] ++ newGameOnClick) [text "New Game"]
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
