defmodule Meansweepx.FieldControllerTest do
  require Ecto

  use Meansweepx.ConnCase

  alias Meansweepx.Field
  @valid_attrs %{chance: 42, height: 42, width: 42}
  @invalid_attrs %{chance: 50, height: 0, width: 0}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "shows chosen resource", %{conn: conn} do
    field = Repo.insert! %Field{}
    conn = get conn, field_path(conn, :show, field)
    assert json_response(conn, 200)["data"] == %{"id" => field.id,
      "width" => field.width,
      "height" => field.height,
      "count" => field.count,
      "active" => field.active,
      "grid" => field.grid}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, field_path(conn, :show, Ecto.UUID.generate())
    end
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

  # test "updates and renders chosen resource when data is valid", %{conn: conn} do
  #   field = Repo.insert! %Field{}
  #   conn = put conn, field_path(conn, :update, field), field: @valid_attrs
  #   assert json_response(conn, 200)["data"]["id"]
  #   assert Repo.get_by(Field, @valid_attrs)
  # end
  #
  # test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
  #   field = Repo.insert! %Field{}
  #   conn = put conn, field_path(conn, :update, field), field: @invalid_attrs
  #   assert json_response(conn, 422)["errors"] != %{}
  # end
end
