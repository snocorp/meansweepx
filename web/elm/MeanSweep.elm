module MeanSweep exposing (..)

import Decoders
import Models exposing (..)
import Header
import Content
import Modal

import Html exposing (Html, a, button, div, form, h1, h4, input, label, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, for, href, id, max, min, type_, value)
import Html.Events exposing (onClick)
import Http
import Json.Decode as JSD
import Json.Encode as JSE
import Navigation
import String
import Time
import Time.DateTime as DateTime exposing (DateTime, DateTimeDelta)

main : Program Never Model Msg
main =
  Navigation.program
    locationParser
    {
      init = init,
      update = update,
      subscriptions = subscriptions,
      view = view
      }

locationParser : Navigation.Location -> Msg
locationParser location =
  case hashParser location of
    Game gameId ->
      NavigateToGame gameId
    Index ->
      NavigateToIndex

hashParser : Navigation.Location -> Route
hashParser location =
  let
    path = (Debug.log "location.hash" (String.dropLeft 2 location.hash))
  in
    if (String.startsWith "/game/" path) && (String.length path) == 42 then
      Game (String.right 36 path)
    else
      Index

emptyError : Error
emptyError =
  Error
    Nothing
    Nothing
    Nothing
    Nothing

-- INIT

-- init : Result String Route -> (Model, Cmd Msg)
init : Navigation.Location -> (Model, Cmd Msg)
init location =
  let
    spec = GameSpec 0 0 0
    timeSinceStarted = DateTimeDelta 0 0 0 0 0 0 0
    model = Model
      Index
      emptyError
      spec
      Nothing
      Nothing
      timeSinceStarted
    cmd = case hashParser location of
      Index ->
        Debug.log "Index" Cmd.none
      Game gameId ->
        Debug.log ("Game "++gameId) (loadGame gameId)
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
          if confirm || field.result /= Undecided then
            ({model | newGameSpec = Nothing}, newGame gameSpec)
          else
            ({model | newGameSpec = Just gameSpec}, Cmd.none)

    NewGameCancel ->
      ({model | newGameSpec = Nothing}, Cmd.none)

    NewGameResult (Ok newField) ->
      ({model | field = Just newField}, Navigation.newUrl ("#!/game/" ++ newField.id))

    NewGameResult (Err err) ->
      let
        modelError = model.error
        message = case err of
          Http.BadUrl details ->
            details
          Http.Timeout ->
            "It took too long to create a new game. Please try again."
          Http.NetworkError ->
            "There was a problem trying to create a new game. Please try again."
          Http.BadPayload details _ ->
            details
          Http.BadStatus response ->
            case response.status.code of
              422 ->
                "There was a problem trying to create a new game. Check the chosen values."
              _ ->
                response.status.message
        error = case err of
          Http.BadStatus response ->
            let
              responseErrors = case JSD.decodeString Decoders.errorsDecoder response.body of
                Ok errors ->
                  errors
                Err _ ->
                  Errors [] [] []
            in
              {modelError |
                errorMsg = Just message,
                heightError = List.head responseErrors.height,
                widthError = List.head responseErrors.width,
                chanceError = List.head responseErrors.chance
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

    LoadGameResult (Ok newField) ->
      update (NavigateToGame newField.id) {model | field = Just newField}

    LoadGameResult (Err err) ->
      let
        error = model.error
        message = case err of
          Http.BadUrl details ->
            details
          Http.Timeout ->
            "It took too long to load the game. Please try again."
          Http.NetworkError ->
            "There was a problem trying to load the game. Please try again."
          Http.BadPayload details _ ->
            details
          Http.BadStatus response ->
            case response.status.code of
              404 ->
                "Game not found. Check the URL."
              _ ->
                response.body
      in
        ({model | error = {error | errorMsg = Just message}}, Cmd.none)

    ActivateBlock x y ->
      case model.field of
        Just field ->
          case field.result of
            Undecided ->
              ({model | field = Just {field | activeBlock = Just (Debug.log "x,y" (x, y))}}, Cmd.none)
            _ ->
              (model, Cmd.none)
        Nothing ->
          (model, Cmd.none)

    DeactivateBlock ->
      case model.field of
        Just field ->
          let
            x = Debug.log "activeBlock" (toString field.activeBlock)
          in
            ({model | field = Just {field | activeBlock = Nothing}}, Cmd.none)
        Nothing ->
          (model, Cmd.none)

    Flag gameId x y ->
      handleAction model (flag gameId x y)

    FlagResult (Ok updatedField) ->
      ({model | field = Just updatedField}, Cmd.none)

    FlagResult (Err err) ->
      handleActionError model err "flag"

    Sweep gameId x y ->
      handleAction model (sweep gameId x y)

    SweepResult (Ok updatedField) ->
      ({model | field = Just updatedField}, Cmd.none)

    SweepResult (Err err) ->
      handleActionError model err "sweep"

    NavigateToIndex ->
      ({model | route = Index}, Cmd.none)

    NavigateToGame gameId ->
      case model.field of
        Just field ->
          if field.id == gameId then
            ({model | route = Game gameId}, Cmd.none)
          else
            ({model | field = Nothing}, (loadGame gameId))
        Nothing ->
          (model, (loadGame gameId))

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

    Tick newTimestamp ->
      let
        newDateTime = DateTime.fromTimestamp newTimestamp
        delta =
          case model.field of
            Just field ->
              case field.finished of
                Nothing ->
                  DateTime.delta newDateTime field.started
                Just finished ->
                  DateTime.delta finished field.started
            Nothing ->
              DateTimeDelta 0 0 0 0 0 0 0
      in
        ({model | timeSinceStarted = delta}, Cmd.none)

handleAction : Model -> Cmd Msg -> (Model, Cmd Msg)
handleAction model action =
  let
    newModel =
      case model.field of
        Just field ->
          case field.result of
            Undecided ->
              {model | field = Just {field | activeBlock = Nothing}}
            _ ->
              model
        Nothing ->
          model
  in
    (newModel, action)

handleActionError : Model -> Http.Error -> String -> (Model, Cmd Msg)
handleActionError model err action =
  let
    modelError = model.error
    message = case err of
      Http.BadUrl details ->
        details
      Http.Timeout ->
        "It took too long to "++action++" the area. Please try again."
      Http.NetworkError ->
        "There was a problem trying to "++action++" the area. Please try again."
      Http.BadPayload details _ ->
        details
      Http.BadStatus response ->
        case response.status.code of
          400 ->
            "There was a problem trying to "++action++" the area."
          404 ->
            "The game you tried to "++action++" was not found."
          _ ->
            response.status.message
  in
    ({model | error = {modelError | errorMsg = Just message}}, Cmd.none)


newGame : GameSpec -> Cmd Msg
newGame gameSpec =
  let
    params = JSE.object [
      ("height", JSE.int gameSpec.height),
      ("width", JSE.int gameSpec.width),
      ("chance", JSE.int gameSpec.chance)
      ]
    request = Http.post "/api/fields/" (Http.jsonBody params) Decoders.fieldDecoder
  in
    Http.send NewGameResult request

loadGame : String -> Cmd Msg
loadGame gameId =
  let
    request = Http.get ("/api/fields/" ++ gameId) Decoders.fieldDecoder
  in
    Http.send LoadGameResult request

flag : String -> Int -> Int -> Cmd Msg
flag gameId x y =
  blockAction FlagResult "flag" gameId x y

sweep : String -> Int -> Int -> Cmd Msg
sweep gameId x y =
  blockAction SweepResult "sweep" gameId x y

blockAction : (Result Http.Error Field -> Msg) -> String -> String -> Int -> Int -> Cmd Msg
blockAction msg action gameId x y =
  let
    url = String.join "/" ["/api/fields", action, gameId, toString x, toString y]
    request = Http.post url Http.emptyBody Decoders.fieldDecoder
  in
    Http.send msg request

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every Time.second Tick


-- VIEW

view : Model -> Html Msg
view model =
  let
    showModal = model.newGameSpec /= Nothing
  in
    div [classList [("modal-open", showModal)], onClick DeactivateBlock] [
      Header.header model,
      Content.content model,
      Modal.confirmModal model,
      Modal.backdrop model
      ]
