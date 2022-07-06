defmodule Chirp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chirp.Accounts` context.
  """

  def unique_username, do: "user_#{Sequence.next("")}"
  def unique_user_email, do: "a#{Sequence.next("")}@a.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(
      attrs,
      %{
        username: unique_username(),
        email: unique_user_email(),
        password: valid_user_password()
      }
    )
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Chirp.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
