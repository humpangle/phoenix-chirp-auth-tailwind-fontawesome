defmodule Chirp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text, null: false
      add :likes_count, :integer, default: 0
      add :reposts_count, :integer, default: 0
      add :photo_urls, {:array, :string}, default: []

      add(
        :user_id,
        references(:users, on_delete: :nothing, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create index(:posts, [:user_id])
  end
end
