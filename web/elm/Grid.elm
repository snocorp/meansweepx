module Grid exposing (gridSvg)

import Models exposing (..)

import Array exposing (Array)
import String exposing (join)
import Svg exposing (Svg, g, circle, rect, line, polygon, svg, text', text)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)

blockSize : Int
blockSize =
  80

gridOffset : Int
gridOffset =
  blockSize // 2

gridSize : Int
gridSize =
  100

gridSvg : Field -> Svg Msg
gridSvg field =
  svg [ viewBox (gridViewBox field.width field.height), width "100%" ]
    (gridRows field)

gridViewBox : Int -> Int -> String
gridViewBox h w =
  String.join " " (List.map toString [0, 0, w * gridSize + gridOffset * 2, h * gridSize + gridOffset * 2])

gridRows : Field -> List (Svg Msg)
gridRows field =
  let
    gridList = Array.toList field.grid
  in
    List.indexedMap (\index row -> g [] (gridRow field row index)) gridList

gridRow : Field -> GridRow -> Int -> List (Svg Msg)
gridRow field row rowIndex =
  let
    rowList = Array.toList row
    layer1 =
      List.indexedMap (\index gridBlock ->
        g [] [
          (gridRect index rowIndex),
          (if gridBlock.flagged then
            flagIcon index rowIndex
          else if gridBlock.value == -1 then
            bombIcon index rowIndex
          else if gridBlock.value == -2 then
            gridText index rowIndex "?"
          else if gridBlock.value == 0 then
            gridText index rowIndex ""
          else
            gridText index rowIndex (toString gridBlock.value)),
          (gridRectOverlay (gridBlock.flagged || gridBlock.value == -2) index rowIndex)
          ]
        ) rowList
    layer2 =
      case field.activeBlock of
        Just (x, y) ->
          let
            maybeGridRow = Array.get y field.grid
            maybeGridBlock =
              case maybeGridRow of
                Just row ->
                  Array.get x row
                Nothing ->
                  Nothing
            flagged =
              case maybeGridBlock of
                Just gridBlock ->
                  gridBlock.flagged
                Nothing ->
                  False
          in
            [(flagOrClearRect flagged field.id x y)]
        Nothing ->
          []
  in
    layer1 ++ layer2

flagOrClearRect : Bool -> String -> Int -> Int -> Svg Msg
flagOrClearRect flagged gameId colIndex rowIndex =
  let
    flagX = (indexToPoints colIndex) - (blockSize // 2)
    flagY = (indexToPoints rowIndex)
    clearX = flagX + blockSize
    clearY = flagY
    flagColor =
      if flagged then "#e9ec79" else "#f3aaaa"
  in
    g [] [
      rect [
        x (toString flagX),
        y (toString flagY),
        width (toString blockSize),
        height (toString blockSize),
        fill flagColor,
        onClick (Flag gameId colIndex rowIndex)
        ] [],
      rect [
        x (toString clearX),
        y (toString clearY),
        width (toString blockSize),
        height (toString blockSize),
        fill "#97de9a",
        onClick (Sweep gameId colIndex rowIndex)
        ] []
      ]

gridRect : Int -> Int -> Svg Msg
gridRect colIndex rowIndex =
  rect [
    x (toString (indexToPoints colIndex)),
    y (toString (indexToPoints rowIndex)),
    width (toString blockSize),
    height (toString blockSize),
    fill "#ccc"
    ] []

gridRectOverlay : Bool -> Int -> Int -> Svg Msg
gridRectOverlay active colIndex rowIndex =
  let
    eventHandlers =
      if active then
        [onClick (ActivateBlock colIndex rowIndex)]
      else
        []
  in
    rect ([
      x (toString (indexToPoints colIndex)),
      y (toString (indexToPoints rowIndex)),
      width (toString blockSize),
      height (toString blockSize),
      fill "rgba(0,0,0,0)"
      ] ++ eventHandlers) []

gridText : Int -> Int -> String -> Svg Msg
gridText colIndex rowIndex value =
  text' [
    x (toString ((indexToPoints colIndex) + (blockSize // 2))),
    y (toString ((indexToPoints rowIndex) + (blockSize // 2))),
    fontFamily "Arial",
    fontSize "35",
    fill "#777",
    alignmentBaseline "middle",
    textAnchor "middle"
    ] [text value]

bombIcon : Int -> Int -> Svg Msg
bombIcon colIndex rowIndex =
  let
    radius = (blockSize * 2 // 5)
    centerX = (indexToPoints colIndex) + (blockSize // 2)
    centerY = (indexToPoints rowIndex) + (blockSize // 2)
  in
    g [] [
      circle [
        strokeOpacity "0",
        cx (toString centerX),
        cy (toString centerY),
        r (toString radius),
        fill "#777"
        ] [],
      longLine centerX centerY radius 0,
      longLine centerX centerY radius 60,
      longLine centerX centerY radius -60,
      shortLine centerX centerY radius 90,
      shortLine centerX centerY radius 30,
      shortLine centerX centerY radius -30,
      g [] [
        circle [
          r (toString (radius // 2)),
          cx (toString centerX),
          cy (toString centerY),
          strokeWidth (toString (radius // 4)),
          stroke "#fff",
          fill "#777"
          ] [],
        circle [
          stroke "#fff",
          r (toString (radius // 6)),
          cx (toString centerX),
          cy (toString centerY),
          strokeWidth "0",
          fill "#fff"
          ] []
        ]
      ]

circleLine : Int -> Int -> Int -> Int -> (Int -> Int) -> Svg Msg
circleLine centerX centerY radius rotation multiplier =
    let
      baseAttrs = [
        stroke "#fff",
        strokeWidth (toString (radius // 8)),
        x1 (toString centerX),
        y1 (toString (centerY - (multiplier radius))),
        x2 (toString centerX),
        y2 (toString (centerY + (multiplier radius)))
        ]
      attrs = if rotation == 0 then
        baseAttrs
      else
        transform ("rotate("++(toString rotation)++", "++(toString centerX)++", "++(toString centerY)++")") :: baseAttrs
    in
      line attrs []

longLine : Int -> Int -> Int -> Int -> Svg Msg
longLine centerX centerY radius rotation =
  circleLine centerX centerY radius rotation (\n -> n)

shortLine : Int -> Int -> Int -> Int -> Svg Msg
shortLine centerX centerY radius rotation =
  circleLine centerX centerY radius rotation (\n -> n * 4 // 5)

flagIcon : Int -> Int -> Svg Msg
flagIcon colIndex rowIndex =
  let
    centerX = indexToPoints colIndex + (blockSize // 2)
    centerY = indexToPoints rowIndex + (blockSize // 2)
  in
    g [] [
      polygon [
        strokeWidth (toString (blockSize // 20)),
        stroke "#777",
        fill "#fff",
        points (pointsToString [
            [(centerX - (blockSize * 7 // 32)), (centerY - blockSize // 4)],
            [(centerX - (blockSize * 7 // 32)), (centerY + blockSize // 4)],
            [(centerX + (blockSize * 7 // 32)), centerY]
          ])
        ] []
      ]

indexToPoints : Int -> Int
indexToPoints index =
  gridOffset + (index * 100) + (gridSize - blockSize) // 2

pointsToString : List (List Int) -> String
pointsToString p =
  String.join " " (List.map (String.join ",") (List.map (List.map toString) p))
