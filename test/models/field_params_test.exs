defmodule Meansweepx.FieldParamsTest do
  use Meansweepx.ModelCase

  alias Meansweepx.FieldParams

  @valid_attrs %{height: 42, width: 42, chance: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = FieldParams.changeset(%FieldParams{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = FieldParams.changeset(%FieldParams{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "height must be greater than 0" do
    attrs = %{@valid_attrs | height: 0}
    assert {:height, "must be greater than 0"} in errors_on(%FieldParams{}, attrs)
  end

  test "height must be less than or equal to 100" do
    attrs = %{@valid_attrs | height: 101}
    assert {:height, "must be less than or equal to 100"} in errors_on(%FieldParams{}, attrs)
  end

  test "width must be greater than 0" do
    attrs = %{@valid_attrs | width: 0}
    assert {:width, "must be greater than 0"} in errors_on(%FieldParams{}, attrs)
  end

  test "width must be less than or equal to 100" do
    attrs = %{@valid_attrs | width: 101}
    assert {:width, "must be less than or equal to 100"} in errors_on(%FieldParams{}, attrs)
  end

  test "chance must be greater than 0" do
    attrs = %{@valid_attrs | chance: 0}
    assert {:chance, "must be greater than 0"} in errors_on(%FieldParams{}, attrs)
  end

  test "chance must be less than or equal to 100" do
    attrs = %{@valid_attrs | chance: 101}
    assert {:chance, "must be less than or equal to 100"} in errors_on(%FieldParams{}, attrs)
  end
end
