defmodule Chirp.TimelineTest do
  use Chirp.DataCase

  alias Chirp.{Timeline, AccountsFixtures}

  describe "posts" do
    alias Chirp.Timeline.Post

    import Chirp.TimelineFixtures

    @invalid_attrs %{
      body: nil
    }

    test "list_posts/0 returns all posts" do
      {post, _} = post_fixture()
      assert Timeline.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      {post, _} = post_fixture()
      assert Timeline.get_post!(post.id) == post
    end

    test "create_post/2 with valid data creates a post" do
      valid_attrs = %{
        body: "some body",
        likes_count: 42,
        photo_urls: [],
        reposts_count: 42
      }

      user = AccountsFixtures.user_fixture()

      assert {:ok, %Post{} = post} = Timeline.create_post(user, valid_attrs)
      assert post.body == "some body"
      assert post.likes_count == 42
      assert post.photo_urls == []
      assert post.reposts_count == 42
    end

    test "create_post/2 with invalid data returns error changeset" do
      user = AccountsFixtures.user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Timeline.create_post(user, @invalid_attrs)
    end

    test "update_post/3 with valid data updates the post" do
      {post, user} = post_fixture()

      update_attrs = %{
        body: "some updated body",
        likes_count: 43,
        photo_urls: [],
        reposts_count: 43
      }

      assert {:ok, %Post{} = post} =
               Timeline.update_post(user, post, update_attrs)

      assert post.body == "some updated body"
      assert post.likes_count == 43
      assert post.photo_urls == []
      assert post.reposts_count == 43
    end

    test "update_post/3 with invalid data returns error changeset" do
      {post, user} = post_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Timeline.update_post(user, post, @invalid_attrs)

      assert post == Timeline.get_post!(post.id)
    end

    test "delete_post/2 deletes the post" do
      {post, user} = post_fixture()

      assert {:ok, %Post{}} = Timeline.delete_post(user, post)

      assert_raise Ecto.NoResultsError, fn -> Timeline.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      {post, _} = post_fixture()
      assert %Ecto.Changeset{} = Timeline.change_post(post)
    end
  end
end
