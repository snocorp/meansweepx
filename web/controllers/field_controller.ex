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
        count = Enum.count(grid, fn({_, v}) -> v["value"] == -1 end)

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
    case field = Repo.get(Field, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(Meansweepx.ErrorView, "404.json", errors: %{field: ["not found"]})
      _ ->
        render(conn, "show.json", field: field)
    end
  end

  def flag(conn, params) do
    cs = FlagParams.changeset(%FlagParams{}, params)
    case cs do
      %{:params => %{"field_id" => field_id, "x" => x, "y" => y}, :valid? => true} ->
        case field = Repo.get(Field, field_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Meansweepx.ErrorView, "404.json", errors: %{field: ["not found"]})
          _ ->
            {x, _} = Integer.parse(x)
            {y, _} = Integer.parse(y)

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
                    conn
                    |> put_status(:bad_request)
                    |> render(Meansweepx.ChangesetView, "error.json", changeset: changeset)
                end
            end
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Meansweepx.ChangesetView, "error.json", changeset: cs)
    end
  end

  def sweep(conn, params) do
    cs = FlagParams.changeset(%FlagParams{}, params)
    case cs do
      %{:params => %{"field_id" => field_id, "x" => x, "y" => y}, :valid? => true} ->
        case field = Repo.get(Field, field_id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> render(Meansweepx.ErrorView, "404.json", errors: %{field: ["not found"]})
          _ ->
            {x, _} = Integer.parse(x)
            {y, _} = Integer.parse(y)

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
                key = "#{x},#{y}"

                # sweep
                {_, grid} = Map.get_and_update(field.grid, key, fn(current_value) ->
                  {
                    current_value,
                    %{
                      "value" => current_value["value"],
                      "flagged" => current_value["flagged"],
                      "swept" => true
                    }
                  }
                end)

                changes = cond do
                  grid[key]["value"] == 0 ->
                    n = unswept_neighbours(grid, x, y, field.height, field.width)
                    grid = sweep_neighbours(n, grid, field.height, field.width)
                    result = calculate_result(grid)
                    %{active: result == 0, result: result, grid: grid}
                  grid[key]["value"] > 0 ->
                    result = calculate_result(grid)
                    %{active: result == 0, result: result, grid: grid}
                  # bomb
                  true ->
                    %{active: false, result: 2, grid: grid}
                end

                changeset = Field.changeset(field, changes)
                case Repo.update(changeset) do
                  {:ok, field} ->
                    conn
                    |> render("show.json", field: field)
                  {:error, changeset} ->
                    conn
                    |> put_status(:bad_request)
                    |> render(Meansweepx.ChangesetView, "error.json", changeset: changeset)
                end
            end
        end
      _ ->
        conn
        |> put_status(:bad_request)
        |> render(Meansweepx.ChangesetView, "error.json", changeset: cs)
    end
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
        cond do
          # set the value to be a bomb
          :rand.uniform(100) <= chance ->
            # get the list of valid neighbours
            n = neighbours(x, y, height, width)

            acc = update_neighbours(n, acc_x)

            Map.put(acc, key, %{"value" => -1, "flagged" => false, "swept" => false})
          # key already exists
          Map.has_key?(acc_x, key) ->
            acc_x
          true ->
            Map.put(acc_x, key, %{"value" => 0, "flagged" => false, "swept" => false})
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

  defp unswept_neighbours(grid, x, y, height, width) do
    Enum.filter(neighbours(x, y, height, width), fn({x,y}) ->
      key = "#{x},#{y}"
      !grid[key]["swept"]
    end)
  end

  defp update_neighbours(n, acc) do
    Logger.warn("update_neighbours")
    # loop through the neighbours
    Enum.reduce(n, acc, fn(z, acc_z) ->
      key = "#{elem(z, 0)},#{elem(z, 1)}"
      # get the value of the neighbour and update
      {_, acc_z} = Map.get_and_update(
        acc_z,
        key,
        fn(current_value) ->

          {
            current_value,
            cond do
              is_nil(current_value) ->
                %{
                  "value" => 1,
                  "flagged" => false,
                  "swept" => false
                }
              # if it is a bomb, leave it as is
              current_value["value"] == -1 ->
                current_value
              # increase the current value by 1
              true ->
                %{
                  "value" => current_value["value"] + 1,
                  "flagged" => current_value["flagged"],
                  "swept" => current_value["swept"]
                }
            end
          }
        end
      )
      acc_z
    end)
  end

  defp sweep_neighbours([], grid, _height, _width) do
    grid
  end

  defp sweep_neighbours(n, grid, height, width) do
    Enum.reduce(n, grid, fn({x,y}, acc) ->
      key = "#{x},#{y}"
      {e, acc} = Map.get_and_update(acc, key, fn(current_value) ->
        {
          current_value,
          %{
            "value" => current_value["value"],
            "flagged" => current_value["flagged"],
            "swept" => true
          }
        }
      end)
      if e["value"] == 0 do
        sweep_neighbours(unswept_neighbours(acc, x, y, height, width), acc, height, width)
      else
        acc
      end
    end)
  end

  defp calculate_result(grid) do
    if Enum.all?(grid, fn({_, v}) -> v["swept"] or v["value"] == -1 end) do
      1 # win
    else
      0 # no result
    end
  end
end
