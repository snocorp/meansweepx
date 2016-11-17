module Models exposing (..)

import Array exposing (Array)
import Http
import Time exposing (Time)
import Time.DateTime as DateTime exposing (DateTime, DateTimeDelta)

type Msg =
  NewGame GameSpec Bool | NewGameCancel | NewGameResult (Result Http.Error Field) |
  LoadGame String Bool | LoadGameResult (Result Http.Error Field) |
  ActivateBlock Int Int | DeactivateBlock |
  Flag String Int Int | FlagResult (Result Http.Error Field) |
  Sweep String Int Int | SweepResult (Result Http.Error Field) |
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
  finished: Maybe DateTime,
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
