defmodule Chirp.Timeline do
  @moduledoc """
  The Timeline context.
  """

  import Ecto.Query, warn: false

  alias Chirp.{Repo, AppCache}
  alias Chirp.Timeline.Post

  @topic "posts"

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    caller = self()

    {_, posts} =
      AppCache.fetch_posts(fn ->
        posts =
          from(
            p in post_and_user_query(),
            order_by: [desc: p.inserted_at]
          )
          |> Repo.all(caller: caller)

        {:commit, posts}
      end)

    posts
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id) do
    caller = self()

    AppCache.fetch_post(id, fn ->
      try do
        post =
          from(
            p in post_and_user_query(),
            where: p.id == ^id
          )
          |> Repo.one!(caller: caller)

        {:commit, post}
      rescue
        e ->
          {:ignore, {e, __STACKTRACE__}}
      end
    end)
    |> case do
      {_, {e, stack}} ->
        reraise e, stack

      {_, post} ->
        post
    end
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(user, %{field: value})
      {:ok, %Post{}}

      iex> create_post(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(user, attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
    |> broadcast(:created, user)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(user, post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(user, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(user, %Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> broadcast(:updated, user)
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(user, %Post{} = post) do
    Repo.delete(post)
    |> broadcast(:deleted, user)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> increment_likes_count(user, id)
      %Post{}

  """
  def increment_likes_count(user, id),
    do: increment_count(user, id, :likes_count)

  @doc """
  Increments post count.

  ## Examples

      iex> increment_reposts_count(user, id)
      %Post{}

  """
  def increment_reposts_count(user, id),
    do: increment_count(user, id, :reposts_count)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def subscribe(_user), do: Phoenix.PubSub.subscribe(Chirp.PubSub, @topic)

  defp post_and_user_query(),
    do: from(p in Post, join: u in assoc(p, :user), preload: [user: u])

  defp broadcast({:ok, post}, action, user) do
    post = %{post | user: user}

    case action do
      :deleted ->
        AppCache.del_post(post.id)

      _ ->
        AppCache.put_post(post)
    end

    Phoenix.PubSub.broadcast(Chirp.PubSub, @topic, {action, post, user})

    {:ok, post}
  end

  defp broadcast(result, _action, _user), do: result

  defp increment_count(user, id, attribute) do
    {1, [post]} =
      from(
        p in Post,
        where: p.id == ^id,
        select: p
      )
      |> Repo.update_all(inc: [{attribute, 1}])

    broadcast({:ok, post}, nil, user)
  end
end
