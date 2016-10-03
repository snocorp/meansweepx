defmodule Meansweepx.Repo.Migrations.CreateField do
  use Ecto.Migration

  def change do
    create table(:fields, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :width, :integer
      add :height, :integer
      add :count, :integer
      add :active, :boolean, default: false, null: false
      add :grid, :map

      timestamps()
    end

  end
end
