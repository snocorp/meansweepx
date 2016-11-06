defmodule Meansweepx.FieldView do
  use Meansweepx.Web, :view

  require Ecto.DateTime

  def render("show.json", %{field: field}) do
    %{data: render_one(field, Meansweepx.FieldView, "field.json")}
  end

  def render("field.json", %{field: field}) do
    grid_matrix = Enum.map(1..field.height, fn(y) ->
      Enum.map(1..field.width, fn(x) ->
        v = Map.get(field.grid, "#{x-1},#{y-1}")
        value = if v["swept"] do v["value"] else -2 end

        %{v: value, f: v["flagged"], s: v["swept"]}
      end)
    end)
    %{
      id: field.id,
      width: field.width,
      height: field.height,
      count: field.count,
      active: field.active,
      grid: grid_matrix,
      result: field.result,
      started: (Ecto.DateTime.to_iso8601 field.inserted_at) <> "Z"
    }
  end
end
