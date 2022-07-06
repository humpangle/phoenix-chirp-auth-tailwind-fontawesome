defmodule Chirp.TimelineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chirp.Timeline` context.
  """

  alias Chirp.AccountsFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    user = AccountsFixtures.user_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        body: "some body",
        user_id: user.id
      })

    {:ok, post} = Chirp.Timeline.create_post(user, attrs)

    {%{post | user: user}, user}
  end
end
