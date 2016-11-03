module MeanSweep exposing (..)

import Decoders
import Models exposing (..)
import Header
import Content
import Modal

import Html exposing (Html, a, button, div, form, h1, h4, input, label, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, for, href, id, max, min, type', value)
import HttpBuilder as Http exposing (jsonReader, send, stringReader, withHeader, withJsonBody, withTimeout)
import Json.Encode as JSE
import Navigation
import String
import Task
import Time

main : Program Never
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

    ActivateBlock x y ->
      case model.field of
        Just field ->
          ({model | field = Just {field | activeBlock = Just (Debug.log "x,y" (x, y))}}, Cmd.none)
        Nothing ->
          (model, Cmd.none)

    Flag gameId x y ->
      let
        newModel =
          case model.field of
            Just field ->
              {model | field = Just {field | activeBlock = Nothing}}
            Nothing ->
              model
      in
        (newModel, flag gameId x y)

    FlagSucceed response ->
      let
        updatedField = response.data
      in
        ({model | field = Just updatedField}, Cmd.none)

    FlagFail err ->
      let
        modelError = model.error
        message = case err of
          Http.Timeout ->
            "It took too long to flag the area. Please try again."
          Http.NetworkError ->
            "There was a problem trying to flag the area. Please try again."
          Http.UnexpectedPayload details ->
            details
          Http.BadResponse response ->
            case response.status of
              400 ->
                "There was a problem trying to flag the area."
              404 ->
                "The game you tried to flag was not found."
              _ ->
                response.statusText
      in
        ({model | error = {modelError | errorMsg = Just message}}, Cmd.none)

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
    ClearErrorMessage ->
      let
        error = model.error
      in
        ({model | error = {error | errorMsg = Nothing}}, Cmd.none)

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
        |> send (jsonReader Decoders.fieldDecoder) (jsonReader Decoders.errorsDecoder)
      )

loadGame : String -> Cmd Msg
loadGame gameId =
  Task.perform LoadGameFail LoadGameSucceed (
    Http.get ("/api/fields/" ++ gameId)
      |> withHeader "Content-Type" "application/json"
      |> withTimeout (1 * Time.second)
      |> send (jsonReader Decoders.fieldDecoder) stringReader
    )

flag : String -> Int -> Int -> Cmd Msg
flag gameId x y =
  let
    url = String.join "/" ["/api/fields/flag", gameId, toString x, toString y]
  in
    Task.perform FlagFail FlagSucceed (
      Http.post url
        |> withTimeout (1 * Time.second)
        |> send (jsonReader Decoders.fieldDecoder) (jsonReader Decoders.errorsDecoder)
      )

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- VIEW

view : Model -> Html Msg
view model =
  let
    showModal = model.newGameSpec /= Nothing
  in
    div [classList [("modal-open", showModal)]] [
      Header.header model,
      Content.content model,
      Modal.confirmModal model,
      Modal.backdrop model
      ]
