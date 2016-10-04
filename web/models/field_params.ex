defmodule Meansweepx.FieldParams do
  use Meansweepx.Web, :model

  schema "field_params" do
    field :width, :integer
    field :height, :integer
    field :chance, :integer
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:width, :height, :chance])
    |> validate_required([:width, :height, :chance])
    |> validate_number(:height, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:width, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:chance, greater_than: 0, less_than_or_equal_to: 100)
  end
end
