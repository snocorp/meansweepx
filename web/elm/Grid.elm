module Grid exposing (gridRows)

import Models exposing (Grid, GridRow, Msg)

import String exposing (join)
import Svg exposing (Svg, g, circle, rect, line, polygon, text', text)
import Svg.Attributes exposing (..)

blockSize : Int
blockSize =
  80

gridRows : Grid -> List (Svg Msg)
gridRows grid =
  List.indexedMap (\index row -> g [] (gridRow row index)) grid

gridRow : GridRow -> Int -> List (Svg Msg)
gridRow row rowIndex =
  List.indexedMap (\index gridBlock ->
    g [] [
      (gridRect index rowIndex),
      (if gridBlock.flagged then
        flagIcon (index * 100 + (blockSize // 2)) (rowIndex * 100 + (blockSize // 2))
      else if gridBlock.value == -1 then
        bombIcon (index * 100 + (blockSize // 2)) (rowIndex * 100 + (blockSize // 2)) (blockSize * 2 // 5)
      else if gridBlock.value == -2 then
        gridText index rowIndex "?"
      else if gridBlock.value == 0 then
        gridText index rowIndex ""
      else
        gridText index rowIndex (toString gridBlock.value))
      ]
    ) row


gridRect : Int -> Int -> Svg Msg
gridRect colIndex rowIndex =
  rect [
    x (toString (colIndex * 100)),
    y (toString (rowIndex * 100)),
    width (toString blockSize),
    height (toString blockSize),
    fill "#ccc"
    ] []

gridText : Int -> Int -> String -> Svg Msg
gridText colIndex rowIndex value =
  text' [
    x (toString (colIndex * 100 + (blockSize // 2))),
    y (toString (rowIndex * 100 + (blockSize // 2))),
    fontFamily "Arial",
    fontSize "35",
    fill "#777",
    alignmentBaseline "middle",
    textAnchor "middle"] [
    text value
    ]

bombIcon : Int -> Int -> Int -> Svg Msg
bombIcon centerX centerY radius =
  g [] [
    circle [strokeOpacity "0", cx (toString centerX), cy (toString centerY), r (toString radius), fill "#777"] [],
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
flagIcon centerX centerY =
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

pointsToString : List (List Int) -> String
pointsToString p =
  String.join " " (List.map (String.join ",") (List.map (List.map toString) p))
