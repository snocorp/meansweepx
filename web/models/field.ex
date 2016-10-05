defmodule Meansweepx.Field do
  use Meansweepx.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "fields" do
    field :width, :integer
    field :height, :integer
    field :count, :integer
    field :active, :boolean, default: false
    field :grid, :map
    field :result, :integer, default: 0

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:width, :height, :count, :active, :grid, :result])
    |> validate_required([:width, :height, :count, :active, :grid])
    |> validate_number(:height, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:width, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_inclusion(:result, 0..2)
  end
end
