defmodule ChirpWeb.UserRegistrationControllerTest do
  use ChirpWeb.ConnCase, async: true

  import Chirp.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ ~r/id="user-register".+Register/s
    end

    test "redirects if already logged in", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> get(Routes.user_registration_path(conn, :new))

      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(email: email)
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)

      logged_in_regex =
        Regex.compile!(
          ~s(class=".*js-user-logged-in.*".+#{email}),
          [:dotall]
        )

      assert response =~ logged_in_regex
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "email" => "inv",
            "username" => "a b",
            "password" => "short"
          }
        })

      response = html_response(conn, 200)
      assert response =~ ~r/id="user-register".+Register/s
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
      assert response =~ ~r/"username-errors".+valid chars/s
    end
  end
end
