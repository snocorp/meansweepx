module Models exposing (..)

import Array exposing (Array)
import HttpBuilder as Http
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime, DateTimeDelta)

type Msg =
  NewGame GameSpec Bool | NewGameSucceed (Http.Response Field) | NewGameFail (Http.Error Errors) | NewGameCancel |
  LoadGame String Bool | LoadGameSucceed (Http.Response Field) | LoadGameFail (Http.Error String) |
  ActivateBlock Int Int | DeactivateBlock |
  Flag String Int Int | FlagFail (Http.Error Errors) | FlagSucceed (Http.Response Field) |
  Sweep String Int Int | SweepFail (Http.Error Errors) | SweepSucceed (Http.Response Field) |
  NavigateToIndex | NavigateToGame String |
  ChangeCustomHeight String | ChangeCustomWidth String | ChangeCustomChance String |
  ClearErrorMessage |
  Tick Time

type alias Errors = {
  height: List String,
  width: List String,
  chance: List String
}

type alias GameSpec = {
  height: Int,
  width: Int,
  chance: Int
}

type alias GridBlock = {
  value : Int,
  flagged : Bool,
  swept: Bool
}
type alias GridRow = Array GridBlock
type alias Grid = Array GridRow

type GameResult = Win | Loss | Undecided

type alias Field = {
  id : String,
  width : Int,
  height : Int,
  count : Int,
  result : GameResult,
  grid : Grid,
  started: DateTime,
  activeBlock : Maybe (Int, Int)
  }

type Route = Index | Game String

type alias Error = {
  errorMsg : Maybe String,
  heightError : Maybe String,
  widthError : Maybe String,
  chanceError : Maybe String
}

type alias Model = {
  route : Route,
  error : Error,
  customGameSpec: GameSpec,
  newGameSpec: Maybe GameSpec,
  field : Maybe Field,
  timeSinceStarted : DateTimeDelta
}
