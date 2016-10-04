defmodule Meansweepx.FlagParams do
  use Meansweepx.Web, :model

  schema "flag_params" do
    field :field_id, :binary_id
    field :x, :integer
    field :y, :integer
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:field_id, :x, :y])
    |> validate_required([:field_id, :x, :y])
    |> validate_number(:x, greater_than_or_equal_to: 0, less_than: 100)
    |> validate_number(:y, greater_than_or_equal_to: 0, less_than: 100)
  end
end
