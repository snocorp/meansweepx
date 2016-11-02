module Models exposing (..)

import HttpBuilder as Http

type Msg =
  NewGame GameSpec Bool | NewGameSucceed (Http.Response Field) | NewGameFail (Http.Error Errors) | NewGameCancel |
  LoadGame String Bool | LoadGameSucceed (Http.Response Field) | LoadGameFail (Http.Error String) |
  Flag | Sweep |
  NavigateToIndex | NavigateToGame String |
  ChangeCustomHeight String | ChangeCustomWidth String | ChangeCustomChance String

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
type alias GridRow = List GridBlock
type alias Grid = List GridRow

type GameResult = Win | Loss | Undecided

type alias Field = {
  id : String,
  width : Int,
  height : Int,
  count : Int,
  result : GameResult,
  grid : Grid
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
  field : Maybe Field
}
