defmodule JajaWeb.ErrorHTMLTest do
  use JajaWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(JajaWeb.ErrorHTML, "404", "html", [])
    assert html =~ "404"
    assert html =~ "Stranica nije pronađena"
  end

  test "renders 500.html" do
    assert render_to_string(JajaWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
