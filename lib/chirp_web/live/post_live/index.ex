defmodule ChirpWeb.PostLive.Index do
  use ChirpWeb, :live_view

  alias Chirp.{Timeline, AppCache}
  alias Chirp.Timeline.Post
  alias ChirpWeb.PostLive.{PostComponent, FormComponent}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Timeline.subscribe(nil)

    {
      :ok,
      socket
      |> assign(:posts, Timeline.list_posts()),
      temporary_assigns: [posts: []]
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)

    {:ok, _} = Timeline.delete_post(socket.assigns.logged_in_user, post)

    {:noreply, socket}
  end

  def handle_event("new", _, socket) do
    AppCache.del_post_params(nil)

    {:noreply,
     socket
     |> push_patch(to: Routes.post_index_path(socket, :new))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    AppCache.del_post_params(id)

    {:noreply,
     socket
     |> push_patch(to: Routes.post_index_path(socket, :edit, id))}
  end

  def handle_event("inc-likes", %{"id" => id}, socket) do
    logged_in_user = socket.assigns.logged_in_user

    {:ok, _} = Timeline.increment_likes_count(logged_in_user, id)

    {:noreply, socket}
  end

  def handle_event("inc-reposts", %{"id" => id}, socket) do
    logged_in_user = socket.assigns.logged_in_user

    {:ok, _} = Timeline.increment_reposts_count(logged_in_user, id)

    {:noreply, socket}
  end

  @impl true
  def handle_info({action, post, user}, socket) do
    logged_in_user = socket.assigns.logged_in_user

    socket =
      if action && logged_in_user.id == user.id do
        put_flash(
          socket,
          :info,
          "Post #{action} successfully"
        )
      else
        socket
      end

    {:noreply, update(socket, :posts, &[post | &1])}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    post = Timeline.get_post!(id)
    logged_in_user = socket.assigns.logged_in_user

    if post.user_id == logged_in_user.id do
      socket
      |> assign(:page_title, "Edit Post")
      |> assign(:post, post)
    else
      socket
      |> push_redirect(to: Routes.post_index_path(socket, :index))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 id="listing-posts" class="mb-4 text-3xl font-semibold">
      Listing Posts
    </h1>

    <%= if @logged_in_user do %>
      <button class="button is-info mb-6" id="new-post-trigger" phx-click="new">
        New Post
      </button>
    <% else %>
      <div class="italic text-red-400 font-bold mb-4">
        You need to log in to create chirps!
      </div>
    <% end %>

    <%= if @live_action in [:new, :edit] do %>
      <.modal return_to={Routes.post_index_path(@socket, :index)}>
        <.live_component
          module={FormComponent}
          id={@post.id || :new}
          title={@page_title}
          action={@live_action}
          post={@post}
          return_to={Routes.post_index_path(@socket, :index)}
          logged_in_user={@logged_in_user}
        />
      </.modal>
    <% end %>

    <div id="posts" class="posts" phx-update="prepend">
      <%= for post <- @posts do %>
        <.live_component
          module={PostComponent}
          id={post.id}
          post={post}
          mine={@logged_in_user && @logged_in_user.id == post.user_id}
          logged_in_user={@logged_in_user}
        />
      <% end %>
    </div>
    """
  end
end
