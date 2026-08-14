defmodule JajaWeb.BatchDeleteTmpTest do
  use JajaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Jaja.Shop

  setup %{conn: conn} do
    Jaja.Repo.insert!(%Jaja.Shop.Product{name: "Eggs", slug: "eggs"})
    {:ok, batch} = Shop.create_batch(%{"type" => "eggs", "amount" => "10", "price" => "3.00"})
    {:ok, conn: Plug.Test.init_test_session(conn, admin_user: "tester"), batch: batch}
  end

  defp delete_button(batch), do: ~s(button[phx-click="delete_batch"][phx-value-id="#{batch.id}"])

  test "deletes a batch with no orders", %{conn: conn, batch: batch} do
    {:ok, view, html} = live(conn, ~p"/admin")
    assert html =~ ~s(id="active_batches-#{batch.id}")

    html = view |> element(delete_button(batch)) |> render_click()

    refute html =~ ~s(id="active_batches-#{batch.id}")
    assert Shop.list_batches() == []
  end

  test "the button is disabled once a batch has orders", %{conn: conn, batch: batch} do
    {:ok, _} =
      Shop.create_order(%{
        "batch_reference" => batch.unique_reference,
        "name" => "A",
        "amount" => "2"
      })

    {:ok, view, _html} = live(conn, ~p"/admin")

    assert has_element?(view, delete_button(batch) <> "[disabled]")
  end

  test "the server refuses even when the disabled button is bypassed, and keeps the orders", %{
    conn: conn,
    batch: batch
  } do
    {:ok, order} =
      Shop.create_order(%{
        "batch_reference" => batch.unique_reference,
        "name" => "A",
        "amount" => "2"
      })

    {:ok, view, _html} = live(conn, ~p"/admin")

    # bypasses the DOM entirely, the way a crafted client event would
    html = render_click(view, "delete_batch", %{"id" => to_string(batch.id)})

    assert html =~ "Batch has orders and cannot be deleted"
    assert html =~ ~s(id="active_batches-#{batch.id}")
    assert Shop.get_batch!(batch.id)
    assert Shop.get_order!(order.id)
  end

  test "the context refuses directly too", %{batch: batch} do
    {:ok, _} =
      Shop.create_order(%{
        "batch_reference" => batch.unique_reference,
        "name" => "A",
        "amount" => "2"
      })

    assert {:error, :has_orders} = Shop.delete_batch(batch)
  end

  test "the button carries a confirmation prompt", %{conn: conn, batch: batch} do
    {:ok, view, html} = live(conn, ~p"/admin")

    assert has_element?(view, delete_button(batch) <> "[data-confirm]")
    assert html =~ "This cannot be undone."
  end
end
