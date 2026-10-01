defmodule JajaWeb.PaymentQrTest do
  use JajaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Jaja.Shop

  @revolut_url "https://revolut.me/smetko?currency=EUR&amount=600&note=Smetkova%20Jaja"
  @keks_url "https://kekspay.hr/keks?a=kekstag&tag=#marijans525"

  setup %{conn: conn} do
    Jaja.Repo.insert!(%Jaja.Shop.Product{name: "Eggs", slug: "eggs"})
    {:ok, batch} = Shop.create_batch(%{"type" => "eggs", "amount" => "10", "price" => "3.00"})
    {:ok, conn: conn, batch: batch}
  end

  defp reserve(conn, batch) do
    {:ok, view, _html} = live(conn, ~p"/order/#{batch.unique_reference}")

    {:ok, view, html} =
      view
      |> form("form", order: %{name: "Ana", amount: "2"})
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "Rezervacija potvrđena, Ana!"
    {view, html}
  end

  test "after reserving, a QR code per payment channel is rendered for fine-pointer devices", %{
    conn: conn,
    batch: batch
  } do
    {view, _html} = reserve(conn, batch)

    qr_row = view |> element("#payment-qr") |> render()

    assert qr_row =~ "Revolut"
    assert qr_row =~ "Keks Pay"
    assert length(String.split(qr_row, "<svg")) == 3
    assert has_element?(view, ~s(#payment-qr[class~="pointer-fine:flex"][class~="hidden"]))
  end

  test "each QR code links where its button does", %{conn: conn, batch: batch} do
    {view, _html} = reserve(conn, batch)

    assert has_element?(view, ~s(#payment-qr a[href="#{@revolut_url}"][target="_blank"] svg))
    assert has_element?(view, ~s(#payment-qr a[href="#{@keks_url}"][target="_blank"] svg))
  end

  test "each QR code carries its channel's logo", %{conn: conn, batch: batch} do
    {view, _html} = reserve(conn, batch)

    qr_row = view |> element("#payment-qr") |> render()

    assert qr_row =~ ~s(href="/images/revolut-logo.png")
    assert qr_row =~ ~s(href="/images/keks-logo.png")
  end

  test "the buttons stay for phones and hide on fine-pointer devices", %{conn: conn, batch: batch} do
    {view, _html} = reserve(conn, batch)

    assert has_element?(view, ~s(#payment-links[class~="pointer-fine:hidden"]))

    assert has_element?(
             view,
             ~s(#payment-links a[href="#{@revolut_url}"]),
             "Plati putem Revoluta"
           )

    assert has_element?(view, ~s(#payment-links a[href="#{@keks_url}"]), "Plati putem Keks Pay-a")
  end

  test "the helper sentence matches the variant", %{conn: conn, batch: batch} do
    {view, _html} = reserve(conn, batch)

    assert view |> element(~s(#payment-hint-links[class~="pointer-fine:hidden"])) |> render() =~
             "Molimo izvršite plaćanje putem linkova ispod."

    assert view |> element(~s(#payment-hint-qr[class~="pointer-fine:block"])) |> render() =~
             "Skenirajte QR kod mobitelom ili kliknite na njega kako biste izvršili plaćanje."
  end

  test "the QR hint sits between the amount and the codes", %{conn: conn, batch: batch} do
    {_view, html} = reserve(conn, batch)

    [{amount, _}] = :binary.matches(html, "Iznos za uplatu")
    [{hint, _}] = :binary.matches(html, "Skenirajte QR kod")
    [{codes, _}] = :binary.matches(html, ~s(id="payment-qr"))

    assert amount < hint and hint < codes
  end
end
