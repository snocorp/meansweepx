defmodule Meansweepx.FieldControllerTest do
  require Ecto
  require Logger

  use Meansweepx.ConnCase

  alias Meansweepx.Field
  @valid_attrs %{chance: 42, height: 42, width: 42, grid: %{"0,0" => %{"value" => 0, "flagged" => false, "swept" => false}}}
  @invalid_attrs %{chance: 50, height: 0, width: 0}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "shows chosen resource", %{conn: conn} do
    field = Repo.insert! %Field{
      height: 1,
      width: 1,
      grid: %{"0,0" => %{"value" => 0, "flagged" => false, "swept" => false}}
    }
    conn = get conn, field_path(conn, :show, field)
    data = json_response(conn, 200)["data"]
    assert data["id"] == field.id
    assert data["width"] == field.width
    assert data["height"] == field.height
    assert data["count"] == field.count
    assert data["active"] == field.active
    assert data["grid"] == [Enum.map(Map.values(field.grid), fn(v) ->
      %{"v" => -2, "f" => v["flagged"], "s" => v["swept"]}
    end)]
    assert data["result"] == 0
    assert data["finish"] == nil
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    response = conn
      |> get(field_path(conn, :show, Ecto.UUID.generate()))
      |> json_response(404)

    expected = %{"errors" => %{"field" => ["not found"]}}

    assert response == expected
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, field_path(conn, :create), @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Field, %{id: json_response(conn, 201)["data"]["id"]})
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, field_path(conn, :create), @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "does not flag chosen grid and renders errors when data is invalid", %{conn: conn} do
    field = Repo.insert! %Field{}
    conn = post conn, field_path(conn, :flag, field, "a", "b")
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not flag chosen grid and renders errors when coords are invalid", %{conn: conn} do
    field = Repo.insert! %Field{height: 2, width: 2}
    conn = post conn, field_path(conn, :flag, field, 2, 2)
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not flag chosen grid and renders errors when field is inactive", %{conn: conn} do
    field = Repo.insert! %Field{active: false}
    conn = post conn, field_path(conn, :flag, field, 0, 0)
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not flag chosen grid and renders errors when field is not found", %{conn: conn} do
    conn = post conn, field_path(conn, :flag, Ecto.UUID.generate(), 0, 0)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "flags chosen grid and renders field", %{conn: conn} do
    field = Repo.insert! %Field{
      height: 2,
      width: 2,
      count: 0,
      grid: %{
        "0,0" => %{"value" => 0, "flagged" => false, "swept" => false},
        "0,1" => %{"value" => 0, "flagged" => false, "swept" => false},
        "1,0" => %{"value" => 0, "flagged" => false, "swept" => false},
        "1,1" => %{"value" => 0, "flagged" => false, "swept" => false},
      },
      active: true}
    conn = post conn, field_path(conn, :flag, field, 1, 0)
    field_response = json_response(conn, 200)["data"]
    assert field_response != %{}
    gridRow0 = Enum.at(field_response["grid"], 0)
    grid10 = Enum.at(gridRow0, 1)
    assert grid10["v"] == -2  # unknown
    assert grid10["f"] == true
    assert grid10["s"] == false
  end

  test "does not sweep chosen grid and renders errors when data is invalid", %{conn: conn} do
    field = Repo.insert! %Field{}
    conn = post conn, field_path(conn, :sweep, field, "a", "b")
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not sweep chosen grid and renders errors when coords are invalid", %{conn: conn} do
    field = Repo.insert! %Field{height: 2, width: 2}
    conn = post conn, field_path(conn, :sweep, field, 2, 2)
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not sweep chosen grid and renders errors when field is inactive", %{conn: conn} do
    field = Repo.insert! %Field{active: false}
    conn = post conn, field_path(conn, :sweep, field, 0, 0)
    assert json_response(conn, 400)["errors"] != %{}
  end

  test "does not sweep chosen grid and renders errors when field is not found", %{conn: conn} do
    conn = post conn, field_path(conn, :sweep, Ecto.UUID.generate(), 0, 0)
    assert json_response(conn, 404)["errors"] != %{}
  end

  test "sweeps chosen grid and neighbours and renders field with no bombs", %{conn: conn} do
    field = Repo.insert! %Field{
      height: 2,
      width: 2,
      count: 0,
      grid: %{
        "0,0" => %{"value" => 0, "flagged" => false, "swept" => false},
        "0,1" => %{"value" => 0, "flagged" => false, "swept" => false},
        "1,0" => %{"value" => 0, "flagged" => false, "swept" => false},
        "1,1" => %{"value" => 0, "flagged" => false, "swept" => false},
      },
      active: true}
    conn = post conn, field_path(conn, :sweep, field, 1, 0)
    field_response = json_response(conn, 200)["data"]
    assert field_response != %{}

    # all grids should be swept since there are no bombs
    Enum.each(List.flatten(field_response["grid"]), fn(v) ->
      assert is_number(v["v"])
      assert v["f"] == false
      assert v["s"] == true
    end)
  end

  test "sweeps chosen grid and neighbours and renders field with one bomb", %{conn: conn} do
    field = Repo.insert! %Field{
      height: 2,
      width: 2,
      count: 1,
      grid: %{
        "0,0" => %{"value" => -1, "flagged" => false, "swept" => false},
        "0,1" => %{"value" => 1, "flagged" => false, "swept" => false},
        "1,0" => %{"value" => 1, "flagged" => false, "swept" => false},
        "1,1" => %{"value" => 1, "flagged" => false, "swept" => false},
      },
      active: true}
    conn = post conn, field_path(conn, :sweep, field, 1, 0)
    field_response = json_response(conn, 200)["data"]
    assert field_response != %{}

    # only chosen grid should be swept
    Enum.each([0,1], fn(y) ->
      row = Enum.at(field_response["grid"], y)
      Enum.each([0,1], fn(x) ->
        v = Enum.at(row, x)
        assert is_number(v["v"])
        assert v["f"] == false
        assert v["s"] == (x == 1 && y == 0)
      end)
    end)
  end

  test "sweeps chosen grid and neighbours and renders 3x3 field with one bomb", %{conn: conn} do
    field = Repo.insert! %Field{
      height: 3,
      width: 3,
      count: 1,
      grid: %{
        "0,0" => %{"value" => -1, "flagged" => false, "swept" => false},
        "0,1" => %{"value" => 1, "flagged" => false, "swept" => false},
        "0,2" => %{"value" => 0, "flagged" => false, "swept" => false},
        "1,0" => %{"value" => 1, "flagged" => false, "swept" => false},
        "1,1" => %{"value" => 1, "flagged" => false, "swept" => false},
        "1,2" => %{"value" => 0, "flagged" => false, "swept" => false},
        "2,0" => %{"value" => 0, "flagged" => false, "swept" => false},
        "2,1" => %{"value" => 0, "flagged" => false, "swept" => false},
        "2,2" => %{"value" => 0, "flagged" => false, "swept" => false},
      },
      active: true}
    conn = post conn, field_path(conn, :sweep, field, 2, 0)
    field_response = json_response(conn, 200)["data"]
    assert field_response != %{}

    # only chosen grid should be swept
    Enum.each([0,1], fn(y) ->
      row = Enum.at(field_response["grid"], y)
      Enum.each([0,1], fn(x) ->
        v = Enum.at(row, x)
        assert is_number(v["v"])
        assert v["f"] == false
        assert v["s"] == (x != 0 || y != 0)
      end)
    end)
  end
end
