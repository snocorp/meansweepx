defmodule Meansweepx.FieldView do
  use Meansweepx.Web, :view

  def render("show.json", %{field: field}) do
    %{data: render_one(field, Meansweepx.FieldView, "field.json")}
  end

  def render("field.json", %{field: field}) do
    %{id: field.id,
      width: field.width,
      height: field.height,
      count: field.count,
      active: field.active,
      grid: field.grid}
  end
end
