defmodule Meansweepx.Repo.Migrations.AlterFields do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :result, :integer, default: 0
    end
  end
end
