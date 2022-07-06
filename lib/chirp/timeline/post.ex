defmodule Chirp.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chirp.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, :string
    field :likes_count, :integer, default: 0
    field :reposts_count, :integer, default: 0
    field :photo_urls, {:array, :string}, default: []
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :body,
      :likes_count,
      :reposts_count,
      :photo_urls,
      :user_id
    ])
    |> validate_required([:body])
    |> validate_length(:body, min: 2, max: 250)
  end
end
