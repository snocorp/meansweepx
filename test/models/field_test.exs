defmodule Meansweepx.FieldTest do
  use Meansweepx.ModelCase

  alias Meansweepx.Field

  @valid_attrs %{active: true, count: 42, height: 42, width: 42, grid: %{}, result: 0}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Field.changeset(%Field{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Field.changeset(%Field{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "height must be greater than 0" do
    attrs = %{@valid_attrs | height: 0}
    assert {:height, "must be greater than 0"} in errors_on(%Field{}, attrs)
  end

  test "height must be less than or equal to 100" do
    attrs = %{@valid_attrs | height: 101}
    assert {:height, "must be less than or equal to 100"} in errors_on(%Field{}, attrs)
  end

  test "width must be greater than 0" do
    attrs = %{@valid_attrs | width: 0}
    assert {:width, "must be greater than 0"} in errors_on(%Field{}, attrs)
  end

  test "width must be less than or equal to 100" do
    attrs = %{@valid_attrs | width: 101}
    assert {:width, "must be less than or equal to 100"} in errors_on(%Field{}, attrs)
  end

  test "result must be between 0 and 2" do
    attrs = %{@valid_attrs | result: -1}
    refute {:result, "must be greater than 0"} in errors_on(%Field{}, attrs)
  end
end
