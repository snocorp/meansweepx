defmodule Meansweepx.FieldController do
  require DateTime
  require Logger
  require Enum
  require Map
  require Integer

  use Meansweepx.Web, :controller

  alias Meansweepx.Field
  alias Meansweepx.FieldParams
  alias Meansweepx.FlagParams

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

  def flag(conn, params) do
    cs = FlagParams.changeset(%FlagParams{}, params)
    case cs do
      %{:params => %{"field_id" => field_id, "x" => x, "y" => y}, :valid? => true} ->
        {x, _} = Integer.parse(x)
        {y, _} = Integer.parse(y)

        field = Repo.get!(Field, field_id)
        errors = validate_coordinate(%{}, x, 0, field.width, "x")
        errors = validate_coordinate(errors, y, 0, field.height, "y")

        cond do
          map_size(errors) > 0 ->
            conn
            |> put_status(:bad_request)
            |> render(Meansweepx.ErrorView, "400.json", errors: errors)
          !field.active ->
            conn
            |> put_status(:bad_request)
            |> render(Meansweepx.ErrorView, "400.json", errors: %{field: ["is inactive"]})
          true ->
            {_, grid} = Map.get_and_update(field.grid, "#{x},#{y}", fn(current_value) ->
              {
                current_value,
                %{
                  "value" => current_value["value"],
                  "flagged" => !current_value["flagged"],
                  "swept" => current_value["swept"]
                }
              }
            end)
            changeset = Field.changeset(field, %{grid: grid})
            case Repo.update(changeset) do
              {:ok, field} ->
                conn
                |> render("show.json", field: field)
              {:error, changeset} ->
                Logger.debug(inspect(grid))
                Logger.debug(inspect(changeset))

                conn
                |> put_status(:bad_request)
                |> render(Meansweepx.ChangesetView, "error.json", changeset: changeset)
            end
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Meansweepx.ChangesetView, "error.json", changeset: cs)
    end
  end

  def sweep(conn, %{"field_id" => field_id, "x" => x, "y" => y}) do
    field = Repo.get!(Field, field_id)
    render(conn, "show.json", field: field)
  end

  defp validate_coordinate(errors, c, min, max, name) do
    if c < min or c >= max do
      {_, errors} = Map.get_and_update(errors, name, fn(current_value) ->
        {
          current_value,
          if is_nil(current_value) do
            ["is invalid"]
          else
            current_value ++ ["is invalid"]
          end
        }
      end)
      errors
    else
      errors
    end
  end

  defp build_grid(height, width, chance) do
    range_x = 0..(width-1)
    range_y = 0..(height-1)

    # loop from top (0) to bottom (height-1)
    Enum.reduce(range_y, %{}, fn(y, acc_y) ->
      # loop from left (0) to right (width-1)
      Enum.reduce(range_x, acc_y, fn(x, acc_x) ->
        # build the key
        key = "#{x},#{y}"

        # if {x,y} is a bomb
        if :rand.uniform(100) <= chance do
          # get the list of valid neighbours
          n = neighbours(x, y, height, width)

          acc = update_neighbours(n, acc_x)

          # set the value to be a bomb
          Map.put(acc, key, %{value: -1, flagged: false, swept: false})
        else
          Map.put(acc_x, key, %{value: 0, flagged: false, swept: false})
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
