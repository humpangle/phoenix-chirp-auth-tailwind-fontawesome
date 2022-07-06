defmodule ChirpWeb.PageControllerTest do
  use ChirpWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200) =~
             ~r/id="hero-title".+Chirp/s
  end
end
