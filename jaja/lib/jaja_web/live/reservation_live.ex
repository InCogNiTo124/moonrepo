defmodule JajaWeb.ReservationLive do
  @moduledoc """
  A customer's confirmation page, reachable any time by the order's reference.
  Shows what was reserved, what it costs, whether the farm has seen the payment,
  and the payment channels while it has not.
  """
  use JajaWeb, :live_view

  alias Jaja.PaymentChannel
  alias Jaja.Shop

  def mount(%{"reference" => reference}, _session, socket) do
    order = Shop.get_order_by_reference!(reference)
    batch = Shop.get_batch_by_reference!(order.batch_reference)

    total_eur = order.amount * batch.price
    revolut_url = PaymentChannel.revolut_url(round(total_eur * 100))
    keks_url = PaymentChannel.keks_url()

    {:ok,
     socket
     |> assign(:order, order)
     |> assign(:batch, batch)
     |> assign(:total_eur, total_eur)
     |> assign(:revolut_url, revolut_url)
     |> assign(:keks_url, keks_url)
     |> assign(
       :revolut_qr,
       PaymentChannel.qr_svg(revolut_url, logo: ~p"/images/revolut-logo.png")
     )
     |> assign(:keks_qr, PaymentChannel.qr_svg(keks_url, logo: ~p"/images/keks-logo.png"))}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md pointer-fine:max-w-xl p-6 mt-10 text-base-content">
      <div class="text-center">
        <h2 class="text-2xl font-bold text-success mb-4">Rezervacija potvrđena, {@order.name}!</h2>
        <p class="mb-4">Uspješno ste rezervirali proizvod: {translate_type(@batch.type)}.</p>

        <p
          :if={not @order.payment_received}
          id="payment-hint-links"
          class="text-sm text-base-content/70 mt-4 pointer-fine:hidden"
        >
          Molimo izvršite plaćanje putem linkova ispod.
        </p>

        <div class="my-6 p-4 bg-base-200 rounded-lg shadow-sm border border-base-300">
          <p class="text-base font-medium opacity-80 mb-1">Iznos za uplatu:</p>
          <p class="text-3xl font-extrabold text-primary">
            {:erlang.float_to_binary(@total_eur, decimals: 2)} €
          </p>
          <p class="text-sm text-base-content/60 mt-1">
            {@order.amount} × {format_price(@batch.price)}
          </p>
        </div>

        <div
          :if={@order.payment_received}
          id="payment-received"
          class="p-4 rounded-lg bg-success/10 text-success font-semibold"
        >
          Plaćanje zaprimljeno. Hvala!
        </div>

        <p
          :if={not @order.payment_received}
          id="payment-hint-qr"
          class="text-sm text-base-content/70 hidden pointer-fine:block"
        >
          Skenirajte QR kod mobitelom ili kliknite na njega kako biste izvršili plaćanje.
        </p>

        <%!-- Phones: deep links into the apps. Hidden where a mouse is the primary input. --%>
        <div
          :if={not @order.payment_received}
          id="payment-links"
          class="flex flex-col gap-3 mt-4 pointer-fine:hidden"
        >
          <a
            href={@revolut_url}
            class="btn bg-[#A78BFA] hover:bg-[#8B5CF6] text-[#1F1B2E] border-none"
            target="_blank"
          >
            Plati putem Revoluta
          </a>
          <a
            href={@keks_url}
            class="btn bg-[#00D986] hover:bg-[#00BF76] text-black border-none"
            target="_blank"
          >
            Plati putem Keks Pay-a
          </a>
        </div>

        <%!-- PCs: the same links as QR codes to scan with a phone. Still clickable,
             revolut.me can take a card payment in a desktop browser. --%>
        <div
          :if={not @order.payment_received}
          id="payment-qr"
          class="hidden pointer-fine:flex justify-center gap-16 mt-4"
        >
          <div class="flex flex-col items-center gap-2">
            <span class="text-sm font-semibold">Revolut</span>
            <a
              href={@revolut_url}
              target="_blank"
              aria-label="QR kod za Revolut"
              class="block w-52 p-2 bg-white rounded-lg [&>svg]:w-full [&>svg]:h-auto"
            >
              {raw(@revolut_qr)}
            </a>
          </div>
          <div class="flex flex-col items-center gap-2">
            <span class="text-sm font-semibold">Keks Pay</span>
            <a
              href={@keks_url}
              target="_blank"
              aria-label="QR kod za Keks Pay"
              class="block w-52 p-2 bg-white rounded-lg [&>svg]:w-full [&>svg]:h-auto"
            >
              {raw(@keks_qr)}
            </a>
          </div>
        </div>

        <p :if={@order.delivered} id="delivered" class="mt-4 text-sm text-success font-medium">
          Preuzeto ✓
        </p>

        <p class="mt-8 text-xs text-base-content/50">
          Ovu stranicu možete ponovno otvoriti bilo kada. Spremite poveznicu.
        </p>
      </div>
    </div>
    """
  end
end
