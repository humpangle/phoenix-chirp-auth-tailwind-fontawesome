defmodule ChirpWeb.PostLive.PostComponent do
  use ChirpWeb, :live_component

  @class "p-2 border mb-1"

  def render(assigns) do
    ~H"""
    <div id={@id} class={hidden_class?(@post)} phx-hook="PostDeleted">
      <article class="media">
        <figure class="media-left">
          <p class="image is-64x64">
            <img src={Routes.static_path(@socket, "/images/128x128.png")} />
          </p>
        </figure>

        <div class="media-content">
          <div class="content">
            <strong>
              <%= @post.user.username %>
            </strong>

            <pre class="p-0 bg-white">
              <%= @post.body %>
            </pre>

            <%= if length(@post.photo_urls) > 0  do %>
              <div>
                <%= for img_url <- @post.photo_urls  do %>
                  <img src={img_url} alt="Photo" class="h-20">
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <div class="media-right">
          <%= if @mine do %>
            <button
              class="delete bg-blue-500 hover:bg-blue-300 focus:bg-blue-300"
              id={"#{@id}-delete"}
              phx-click="delete"
              phx-value-id={@id}
              data={[confirm: "Are you sure?"]}
            >
            </button>
          <% end %>
        </div>
      </article>

      <div class="mt-4 flex justify-between px-6">
        <.icon_link
          id={"#{@id}-inc-likes_count"}
          phx-click={if @logged_in_user && !@mine, do: "inc-likes"}
          phx-value-id={@id}
        >
          <:icon>
            <i class="fa-regular fa-heart"></i>
          </:icon>
          <%= @post.likes_count %>
        </.icon_link>

        <.icon_link
          id={"#{@id}-inc-reposts"}
          phx-click={if @logged_in_user && !@mine, do: "inc-reposts"}
          phx-value-id={@id}
        >
          <:icon>
            <i class="fa-solid fa-retweet"></i>
          </:icon>
          <%= @post.reposts_count %>
        </.icon_link>

        <%= if @mine do %>
          <.icon_link id={"#{@id}-edit"} phx-click="edit" phx-value-id={@id}>
            <:icon>
              <i class="fa-regular fa-pen-to-square"></i>
            </:icon>
          </.icon_link>
        <% end %>

        <.icon_link
          href={Routes.post_show_path(@socket, :show, @id)}
          id={"#{@id}-show"}
        >
          <:icon>
            <i class="fa-regular fa-eye"></i>
          </:icon>
        </.icon_link>
      </div>
    </div>
    """
  end

  defp icon_link(assigns) do
    assigns =
      assigns
      |> assigns_to_attributes([:icon])
      |> then(&assign(assigns, :dynamic, &1))

    ~H"""
    <a class="text-blue-500 hover:text-blue-300 hover:scale-125" {@dynamic}>
      <span class="icon is-small">
        <%= render_slot(@icon) %>
      </span>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  defp hidden_class?(post) do
    if post.__meta__.state == :deleted do
      "#{@class} hidden"
    else
      @class
    end
  end
end
