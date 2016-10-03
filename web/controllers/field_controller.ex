defmodule Meansweepx.FieldController do
  require DateTime
  require Logger
  require Enum
  require Map
  require Integer

  use Meansweepx.Web, :controller

  alias Meansweepx.Field
  alias Meansweepx.FieldParams

  def create(conn, params) do
    cs = FieldParams.changeset(%FieldParams{}, params)
    case cs do
      %{:params => %{"chance" => chance, "height" => height, "width" => width}, :valid? => true} ->
        grid = build_grid(height, width, chance)

        # count the bombs
        count = Enum.count(grid, fn(e) -> elem(e, 1) == -1 end)

        field_params = %{
          width: width,
          height: height,
          count: count,
          grid: grid,
          active: true
        }

        changeset = Field.changeset(%Field{}, field_params)

        case Repo.insert(changeset) do
          {:ok, field} ->
            conn
            |> put_status(:created)
            |> put_resp_header("location", field_path(conn, :show, field))
            |> render("show.json", field: field)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(Meansweepx.ChangesetView, "error.json", changeset: changeset)
        end
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Meansweepx.ChangesetView, "error.json", changeset: cs)
    end
  end

  def show(conn, %{"id" => id}) do
    field = Repo.get!(Field, id)
    render(conn, "show.json", field: field)
  end

  defp build_grid(height, width, chance) do
    range_x = 0..(width-1)
    range_y = 0..(height-1)

    # loop from top (0) to bottom (height-1)
    Enum.reduce(range_y, %{}, fn(y, acc_y) ->
      # loop from left (0) to right (width-1)
      Enum.reduce(range_x, acc_y, fn(x, acc_x) ->
        # if {x,y} is a bomb
        if :rand.uniform(100) <= chance do
          # build the key
          key = Integer.to_string(x) <> "," <> Integer.to_string(y)

          # get the list of valid neighbours
          n = neighbours(x, y, height, width)

          acc = update_neighbours(n, acc_x)

          # set the value to be a bomb
          Map.put(acc, key, -1)
        else
          # no changes required
          acc_x
        end
      end)
    end)
  end

  defp neighbours(x, y, height, width) do
    n = [
      {x-1,y-1},{x,y-1},{x+1,y-1},
      {x-1,y},{x,y},{x+1,y},
      {x-1,y+1},{x,y+1},{x+1,y+1}
    ]
    Enum.filter(n, fn(e) -> elem(e, 0) >= 0 and elem(e, 0) < width and elem(e, 1) >= 0 and elem(e, 1) < height end)
  end

  defp update_neighbours(n, acc) do
    # loop through the neighbours
    Enum.reduce(n, acc, fn(z, acc_z) ->
      # get the value of the neighbour and update
      {_, acc_z} = Map.get_and_update(
        acc_z,
        Integer.to_string(elem(z, 0)) <> "," <> Integer.to_string(elem(z, 1)),
        fn(current_value) ->
          {
            current_value,
            cond do
              # not yet set, assume 0 bomb neighbours
              is_nil(current_value) ->
                1
              # if it is a bomb, leave it as is
              current_value == -1 ->
                -1
              # increase the current value by 1
              true ->
                current_value + 1
            end
          }
        end
      )
      acc_z
    end)
  end
end
