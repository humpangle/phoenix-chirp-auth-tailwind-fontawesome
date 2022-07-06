defmodule ChirpWeb.LiveAuth do
  import Phoenix.LiveView

  alias Chirp.Accounts

  def on_mount(
        :default,
        _params,
        %{"user_token" => user_token} = _session,
        socket
      ) do
    socket =
      assign_new(socket, :logged_in_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)

    {:cont, socket}
  end

  def on_mount(_live_session_key, _params, _session, socket),
    do: {:cont, assign(socket, :logged_in_user, nil)}
end
