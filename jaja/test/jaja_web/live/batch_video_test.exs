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

  describe "admin create form and existing batch video upload" do
    test "offers a video input once storage is configured", %{conn: conn} do
      configure_storage()

      {:ok, _view, html} = live(conn, ~p"/admin")

      assert html =~ "Video (optional)"
      assert html =~ ~s(type="file")
    end

    test "presigns a video upload on batch creation", %{conn: conn} do
      configure_storage()

      {:ok, view, _html} = live(conn, ~p"/admin")

      video =
        file_input(view, "#batch-form", :video, [
          %{
            name: "hens.mp4",
            content: "fake video bytes",
            size: 16,
            type: "video/mp4"
          }
        ])

      assert {:ok, %{ref: _ref, config: %{max_file_size: 200_000_000}, entries: entries}} =
               preflight_upload(video)

      [{_ref, meta}] = Enum.to_list(entries)
      assert meta.uploader == "S3"
      assert meta.key =~ ~r|^batches/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+\.mp4$|
      assert meta.url =~ "https://fsn1.your-objectstorage.com/jaja-videos/"
    end

    test "attaches or replaces a video on an existing batch", %{conn: conn} do
      configure_storage()

      {:ok, batch} =
        Shop.create_batch(%{
          "type" => "eggs",
          "amount" => "10",
          "price" => "3.00"
        })

      {:ok, view, html} = live(conn, ~p"/admin")
      assert html =~ "Add video"

      view
      |> element(~s(button[phx-click="edit_batch_video"][phx-value-id="#{batch.id}"]))
      |> render_click()

      video =
        file_input(view, "#batch-video-form-#{batch.id}", :existing_video, [
          %{
            name: "pasture.mp4",
            content: "fake video bytes",
            size: 16,
            type: "video/mp4"
          }
        ])

      html = render_upload(video, "pasture.mp4")

      assert html =~ "Video uploaded."
      assert html =~ "Replace video"

      updated = Shop.get_batch!(batch.id)
      assert updated.video_key =~ ~r|^batches/#{batch.unique_reference}/[A-Za-z0-9_-]+\.mp4$|
    end

    test "hides the video input when storage is not configured", %{conn: conn} do
      Application.put_env(:jaja, Storage, [])
      {:ok, _view, html} = live(conn, ~p"/admin")

      refute html =~ "Video (optional)"
    end
  end

  describe "home page video display and history" do
    test "shows video carousel starting at latest video and slides back/forward through history",
         %{conn: conn} do
      configure_storage()

      {:ok, older} =
        Shop.create_batch(%{
          "type" => "eggs",
          "amount" => "10",
          "price" => "3.00",
          "datetime" => ~N[2026-05-01 10:00:00],
          "video_key" => "batches/old123/older.mp4"
        })

      {:ok, latest} =
        Shop.create_batch(%{
          "type" => "eggs",
          "amount" => "10",
          "price" => "3.50",
          "datetime" => ~N[2026-06-01 10:00:00],
          "video_key" => "batches/new456/latest.mp4"
        })

      {:ok, view, _html} = live(conn, ~p"/")

      # Starts at index 1 (latest video)
      assert has_element?(
               view,
               ~s|#video-carousel-track[style="transform: translateX(-100%)"]|
             )

      assert has_element?(
               view,
               ~s|#video-slide-#{latest.id} video[src="https://fsn1.your-objectstorage.com/jaja-videos/batches/new456/latest.mp4"]|
             )

      assert has_element?(
               view,
               ~s|#video-slide-#{older.id} video[src="https://fsn1.your-objectstorage.com/jaja-videos/batches/old123/older.mp4"]|
             )

      # Clicking `<` (#older-video-btn) slides back to index 0 (older video)
      view |> element("#older-video-btn") |> render_click()

      assert has_element?(
               view,
               ~s|#video-carousel-track[style="transform: translateX(-0%)"]|
             )

      assert has_element?(view, "#older-video-btn[disabled]")

      # Clicking `>` (#newer-video-btn) slides forward to index 1 (latest video)
      view |> element("#newer-video-btn") |> render_click()

      assert has_element?(
               view,
               ~s|#video-carousel-track[style="transform: translateX(-100%)"]|
             )

      assert has_element?(view, "#newer-video-btn[disabled]")
    end

    test "does not render video player on /order/:reference", %{conn: conn} do
      configure_storage()

      {:ok, batch} =
        Shop.create_batch(%{
          "type" => "eggs",
          "amount" => "10",
          "price" => "3.00",
          "video_key" => "batches/aBc123/clip.mp4"
        })

      {:ok, _view, html} = live(conn, ~p"/order/#{batch.unique_reference}")

      refute html =~ "<video"
    end
  end
end
