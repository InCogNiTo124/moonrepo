defmodule JajaWeb.ReservationLiveTest do
  use JajaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Jaja.Shop

  setup %{conn: conn} do
    Jaja.Repo.insert!(%Jaja.Shop.Product{name: "Eggs", slug: "eggs"})
    {:ok, batch} = Shop.create_batch(%{"type" => "eggs", "amount" => "10", "price" => "3.00"})
    {:ok, conn: conn, batch: batch}
  end

  defp place_order(batch) do
    {:ok, order} =
      Shop.create_order(%{
        "batch_reference" => batch.unique_reference,
        "name" => "Ana",
        "amount" => "2"
      })

    order
  end

  test "reserving lands on the reservation page", %{conn: conn, batch: batch} do
    {:ok, view, _html} = live(conn, ~p"/order/#{batch.unique_reference}")

    result =
      view
      |> form("form", order: %{name: "Ana", amount: "2"})
      |> render_submit()

    assert {:error, {:live_redirect, %{to: "/reservation/" <> reference}}} = result
    assert Shop.get_order_by_reference!(reference).name == "Ana"

    {:ok, _view, html} = follow_redirect(result, conn)
    assert html =~ "Rezervacija potvrđena, Ana!"
  end

  test "the page opens again by its reference with everything on it", %{conn: conn, batch: batch} do
    order = place_order(batch)

    {:ok, _view, html} = live(conn, ~p"/reservation/#{order.reference}")

    assert html =~ "Rezervacija potvrđena, Ana!"
    assert html =~ "2 × #{JajaWeb.CoreComponents.format_price(batch.price)}"
    assert html =~ "6.00 €"
    assert html =~ "Plati putem Revoluta"
  end

  test "an unknown reference is a 404", %{conn: conn} do
    assert_error_sent 404, fn -> live(conn, ~p"/reservation/no-such-order") end
  end

  test "a paid reservation shows a receipt instead of payment options", %{
    conn: conn,
    batch: batch
  } do
    order = place_order(batch)
    {:ok, _} = Shop.update_order_admin(order, %{payment_received: true})

    {:ok, view, html} = live(conn, ~p"/reservation/#{order.reference}")

    assert html =~ "Plaćanje zaprimljeno"
    refute has_element?(view, "#payment-qr")
    refute has_element?(view, "#payment-links")
    refute has_element?(view, "#payment-hint-qr")
  end

  test "a delivered reservation says so", %{conn: conn, batch: batch} do
    order = place_order(batch)
    {:ok, _} = Shop.update_order_admin(order, %{payment_received: true, delivered: true})

    {:ok, view, _html} = live(conn, ~p"/reservation/#{order.reference}")

    assert has_element?(view, "#delivered")
  end
end
