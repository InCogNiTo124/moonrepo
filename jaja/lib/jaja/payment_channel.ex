defmodule Jaja.PaymentChannel do
  @moduledoc """
  The out-of-band ways a customer can pay for an Order: Revolut and Keks Pay.

  Each channel is a fixed farm account. The shop never observes the payment; it
  hands the customer a link into the app, or the same link as a QR code to scan
  from a PC. Buttons and codes must read the same URLs from here so they cannot
  drift apart.
  """

  @revolut_handle "smetko"
  @revolut_note "Smetkova Jaja"
  @keks_url "https://kekspay.hr/keks?a=kekstag&tag=#marijans525"

  @doc """
  Revolut payment link with the order total prefilled, in cents.
  """
  def revolut_url(total_cents) when is_integer(total_cents) and total_cents >= 0 do
    "https://revolut.me/#{@revolut_handle}?currency=EUR&amount=#{total_cents}&note=#{URI.encode(@revolut_note)}"
  end

  @doc """
  Keks Pay link to the farm's tag. Keks tags carry no amount, so this never varies.
  """
  def keks_url, do: @keks_url

  @doc """
  The link as an inline SVG QR code, sized by `viewBox` so CSS decides the pixels.

  Rendered here rather than by `EQRCode.svg/2`: that emits one `<rect>` per module
  and comes to ~100 KB per code. The code is in the DOM for every reservation,
  phones included, so it is drawn as one run-length `<path>` instead, a few KB.

  Pass `logo: "/images/x.svg"` to cut a white square out of the middle and place the
  image in it. High error correction (30 % recoverable) is used so the cut-out,
  which covers under a tenth of the code, never makes it unreadable.
  """
  def qr_svg(url, opts \\ []) when is_binary(url) do
    %EQRCode.Matrix{matrix: matrix} = EQRCode.encode(url, :h)
    size = tuple_size(matrix)

    path =
      matrix
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.map(fn {row, y} -> dark_runs(Tuple.to_list(row), y) end)
      |> IO.iodata_to_binary()

    ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{size} #{size}" shape-rendering="crispEdges" role="img"><path d="#{path}"/>#{logo_cutout(size, opts[:logo])}</svg>)
  end

  # One `M x y h n v1 h-n z` rectangle per horizontal run of dark modules.
  defp dark_runs(row, y) do
    row
    |> Enum.with_index()
    |> Enum.chunk_by(fn {module, _x} -> module == 1 end)
    |> Enum.filter(fn [{module, _x} | _] -> module == 1 end)
    |> Enum.map(fn [{_, x} | _] = run ->
      n = length(run)
      "M#{x} #{y}h#{n}v1h-#{n}z"
    end)
  end

  # A white square, 30 % of the code's width and snapped to the module grid so it
  # stays centred, with the logo inset by one module.
  @logo_fraction 0.3

  defp logo_cutout(_size, nil), do: ""

  defp logo_cutout(size, logo) do
    side = round(size * @logo_fraction)
    side = if rem(size - side, 2) == 0, do: side, else: side + 1
    offset = div(size - side, 2)

    ~s(<rect x="#{offset}" y="#{offset}" width="#{side}" height="#{side}" rx="1" fill="#fff"/>) <>
      ~s(<image href="#{logo}" x="#{offset + 1}" y="#{offset + 1}" width="#{side - 2}" height="#{side - 2}" preserveAspectRatio="xMidYMid meet"/>)
  end
end
