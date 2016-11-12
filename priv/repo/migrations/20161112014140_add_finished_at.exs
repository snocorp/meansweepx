defmodule Meansweepx.Repo.Migrations.AddFinishedAt do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :finished_at, :datetime
    end
  end
end
