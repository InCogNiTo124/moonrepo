defmodule JajaWeb.BatchVideoTest do
  use JajaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Jaja.Shop
  alias Jaja.Storage

  setup %{conn: conn} do
    Jaja.Repo.insert!(%Jaja.Shop.Product{name: "Eggs", slug: "eggs"})
    {:ok, conn: Plug.Test.init_test_session(conn, admin_user: "tester")}
  end

  defp configure_storage do
    original = Application.get_env(:jaja, Storage)

    Application.put_env(:jaja, Storage,
      bucket: "jaja-videos",
      region: "fsn1",
      access_key_id: "AKIAEXAMPLE",
      secret_access_key: "secretexample"
    )

    on_exit(fn -> Application.put_env(:jaja, Storage, original) end)
  end

  describe "admin create form" do
    test "offers a video input once storage is configured", %{conn: conn} do
      configure_storage()

      {:ok, _view, html} = live(conn, ~p"/admin")

      assert html =~ "Video (optional)"
      assert html =~ ~s(type="file")
    end

    test "hides the video input when storage is not configured", %{conn: conn} do
      Application.put_env(:jaja, Storage, [])
      {:ok, _view, html} = live(conn, ~p"/admin")

      refute html =~ "Video (optional)"
    end
  end

  describe "order page" do
    test "renders a video player when the batch has one", %{conn: conn} do
      configure_storage()

      {:ok, batch} =
        Shop.create_batch(%{
          "type" => "eggs",
          "amount" => "10",
          "price" => "3.00",
          "video_key" => "batches/aBc123/clip.mp4"
        })

      {:ok, _view, html} = live(conn, ~p"/order/#{batch.unique_reference}")

      assert html =~ "<video"
      assert html =~ "https://fsn1.your-objectstorage.com/jaja-videos/batches/aBc123/clip.mp4"
    end

    test "renders no player when the batch has no video", %{conn: conn} do
      configure_storage()

      {:ok, batch} = Shop.create_batch(%{"type" => "eggs", "amount" => "10", "price" => "3.00"})

      {:ok, _view, html} = live(conn, ~p"/order/#{batch.unique_reference}")

      refute html =~ "<video"
    end
  end
end
