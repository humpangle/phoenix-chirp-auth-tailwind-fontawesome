defmodule ChirpWeb.PostLiveTest do
  use ChirpWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chirp.TimelineFixtures

  @create_attrs %{
    body: "some body"
  }

  @update_attrs %{
    body: "some updated body"
  }

  @invalid_attrs %{
    body: nil
  }

  defp create_post(_) do
    {post, user} = post_fixture()
    %{post: post, user: user}
  end

  describe "Index" do
    setup [:create_post]

    test "lists all posts", %{conn: conn, post: post} do
      {:ok, _index_live, html} =
        live(conn, Routes.post_index_path(conn, :index))

      assert html =~ ~r/id="listing-posts".+Listing Posts/s

      assert html =~ post.body
    end

    test "logged in user can create new post", %{conn: conn, user: user} do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(Routes.post_index_path(conn, :index))

      index_live
      |> element("#new-post-trigger")
      |> render_click()

      assert_patch(index_live, Routes.post_index_path(conn, :new))

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      index_live
      |> form("#post-form", post: @create_attrs)
      |> render_submit()

      assert_patch(index_live, Routes.post_index_path(conn, :index))

      html = render(index_live)

      assert html =~ "Post created successfully"
      assert html =~ "some body"
    end

    test "logged in user can update post in listing", %{conn: conn, post: post} do
      %{user: user, id: id} = post

      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(Routes.post_index_path(conn, :index))

      index_live
      |> element("##{id}-edit")
      |> render_click()

      assert_patch(index_live, Routes.post_index_path(conn, :edit, post))

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      index_live
      |> form("#post-form", post: @update_attrs)
      |> render_submit()

      assert_patch(index_live, Routes.post_index_path(conn, :index))

      html = render(index_live)

      assert html =~ "Post updated successfully"
      assert html =~ "some updated body"
    end

    test "logged in user can delete post in listing", %{conn: conn, post: post} do
      %{user: user, id: id} = post

      deleted_regex =
        Regex.compile!(~s(id="#{id}".+class=".*hidden.*"), [:dotall])

      {:ok, index_live, html} =
        conn
        |> log_in_user(user)
        |> live(Routes.post_index_path(conn, :index))

      refute html =~ deleted_regex

      index_live
      |> element("##{id}-delete")
      |> render_click()

      # assert_patch(index_live, Routes.post_index_path(conn, :index))

      html = render(index_live)

      assert html =~ deleted_regex
    end
  end

  describe "Show" do
    setup [:create_post]

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} =
        live(conn, Routes.post_show_path(conn, :show, post))

      assert html =~ "Show Post"
      assert html =~ post.body
    end

    @tag :skip
    test "updates post within modal", %{conn: conn, post: post} do
      {:ok, show_live, _html} =
        live(conn, Routes.post_show_path(conn, :show, post))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(show_live, Routes.post_show_path(conn, :edit, post))

      assert show_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#post-form", post: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.post_show_path(conn, :show, post))

      assert html =~ "Post updated successfully"
      assert html =~ "some updated body"
    end
  end
end
