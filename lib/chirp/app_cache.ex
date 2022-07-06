defmodule Chirp.AppCache do
  @cache :chirp

  def fetch_posts(cb) do
    Cachex.fetch(@cache, posts_key(), cb)
  end

  def fetch_post(id, cb) do
    Cachex.fetch(@cache, post_key(id), cb)
  end

  def put_post(post) do
    Cachex.execute(@cache, fn cache ->
      Cachex.put(cache, post_key(post.id), post)
      Cachex.del(cache, posts_key())
    end)
  end

  def del_post(id) do
    Cachex.execute(@cache, fn cache ->
      Cachex.del(cache, post_key(id))
      Cachex.del(cache, posts_key())
    end)
  end

  def put_post_params(id, params),
    do: Cachex.put(@cache, post_params_key(id), params)

  def get_post_params(id) do
    {:ok, val} = Cachex.get(@cache, post_params_key(id))
    val || %{}
  end

  def del_post_params(id), do: Cachex.del(@cache, post_params_key(id))

  def posts_key(), do: "posts"

  def post_key(id), do: "post:#{id}"

  def post_params_key(id), do: "post_params:#{id}"

  def purge_all(), do: Cachex.clear(@cache)

  ############################# USER ###################################

  def put_user_by_token(token, user),
    do: Cachex.put(@cache, user_by_token_key(token), user)

  def fetch_user_by_token(token, cb),
    do: Cachex.fetch(@cache, user_by_token_key(token), cb)

  def del_user_by_token(token),
    do: Cachex.del(@cache, user_by_token_key(token))

  def put_user_by_id(id, user),
    do: Cachex.put(@cache, user_by_id_key(id), user)

  def user_by_token_key(token), do: "usert#{token}"

  def user_by_id_key(id), do: "user#{id}"
end
