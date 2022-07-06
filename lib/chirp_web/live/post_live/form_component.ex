defmodule ChirpWeb.PostLive.FormComponent do
  use ChirpWeb, :live_component

  alias Chirp.{Timeline, AppCache}

  @impl true
  def mount(socket) do
    socket =
      allow_upload(socket, :photo,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 2,
        external: &presign_entry/2
      )

    {:ok, socket}
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Timeline.change_post(post, AppCache.get_post_params(post.id))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    post = socket.assigns.post

    AppCache.put_post_params(post.id, post_params)

    changeset =
      post
      |> Timeline.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    case Timeline.update_post(
           socket.assigns.logged_in_user,
           socket.assigns.post,
           post_params
         ) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    post_params = put_photo_urls(socket, post_params)

    case Timeline.create_post(socket.assigns.logged_in_user, post_params) do
      {:ok, post} ->
        after_save(socket, post)

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp put_photo_urls(socket, params) do
    {completed, []} = uploaded_entries(socket, :photo)

    urls =
      for entry <- completed do
        # Routes.static_path(socket, "/uploads/#{entry.uuid}.#{ext(entry)}")
        Path.join(s3_host(), filename(entry))
      end

    Map.put(params, "photo_urls", urls)
  end

  # move photo binaries to disk/s3
  defp after_save(socket, post) do
    consume_uploaded_entries(socket, :photo, fn _meta, _entry ->
      # filename = filename(entry)
      # dest = Path.join("priv/static/uploads", filename)
      # File.cp!(meta.path, dest)
      # {:ok, Routes.static_path(socket, "/uploads/#{filename}")}
      {:ok, ""}
    end)

    {:ok, post}
  end

  defp filename(entry), do: "#{entry.uuid}.#{ext(entry)}"

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp bucket, do: System.fetch_env!("AWS_BUCKET")

  defp s3_host(), do: "//#{bucket()}.s3.amazonaws.com"

  defp presign_entry(entry, socket) do
    uploads = socket.assigns.uploads
    key = filename(entry)

    config = %{
      scheme: "http://",
      host: "s3.amazonaws.com",
      region: "us-east-1",
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        config,
        bucket(),
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads.photo.max_file_size,
        expires_in: :timer.hours(1)
      )

    meta = %{uploader: "S3", key: key, url: s3_host(), fields: fields}
    {:ok, meta, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 id="upsert-post" class="mb-4 text-3xl font-semibold">
        <%= @title %>
      </h2>

      <.form
        let={f}
        for={@changeset}
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="field">
          <%= textarea(f, :body, class: "textarea") %>
          <%= error_tag(f, :body) %>
        </div>

        <div class="my-3">
          <%= for err <- upload_errors(@uploads.photo) do %>
            <p class="notification is-danger max-w-xs ">
              <%= Phoenix.Naming.humanize(err) %>
            </p>
          <% end %>

          <%= live_file_input(@uploads.photo) %>

          <div class="space-y-1">
            <%= for entry <- @uploads.photo.entries  do %>
              <div class="grid grid-cols-3 gap-3 first:mt-3">
                <div class="">
                  <%= live_img_preview(entry, style: "height: 80px") %>
                </div>

                <div>
                  <progress max="100" value={entry.progress}></progress>
                </div>

                <div>
                  <button
                    type="button"
                    class="button is-small is-warning"
                    phx-click="cancel-upload"
                    phx-target={@myself}
                    phx-value-ref={entry.ref}
                  >
                    Cancel
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <%= submit(
          "Save",
          phx_disable_with: "Saving...",
          class: "button is-info",
          id: "save-post"
        ) %>
      </.form>
    </div>
    """
  end
end
