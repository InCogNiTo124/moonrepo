defmodule Jaja.PaymentChannelTest do
  use ExUnit.Case, async: true

  alias Jaja.PaymentChannel

  describe "revolut_url/1" do
    test "carries the exact amount in cents and the farm note" do
      assert PaymentChannel.revolut_url(600) ==
               "https://revolut.me/smetko?currency=EUR&amount=600&note=Smetkova%20Jaja"
    end
  end

  describe "keks_url/0" do
    test "is the fixed farm tag link" do
      assert PaymentChannel.keks_url() == "https://kekspay.hr/keks?a=kekstag&tag=#marijans525"
    end
  end

  describe "qr_svg/1" do
    test "renders a scalable svg" do
      svg = PaymentChannel.qr_svg("https://example.com")

      assert svg =~ "<svg"
      assert svg =~ "viewBox="
      assert svg =~ ~s(<path d="M)
    end

    test "stays small, phones carry it in the DOM without ever showing it" do
      svg =
        PaymentChannel.qr_svg(PaymentChannel.revolut_url(600), logo: "/images/revolut-logo.png")

      assert byte_size(svg) < 10_000
    end

    test "places a logo in a white cut-out in the middle when given one" do
      svg = PaymentChannel.qr_svg("https://example.com", logo: "/images/revolut-logo.png")

      assert svg =~ ~s(<rect x=")
      assert svg =~ ~s(<image href="/images/revolut-logo.png")
    end

    test "has no cut-out without a logo" do
      svg = PaymentChannel.qr_svg("https://example.com")

      refute svg =~ "<image"
      refute svg =~ "<rect"
    end

    test "different links render different codes" do
      refute PaymentChannel.qr_svg("https://example.com/a") ==
               PaymentChannel.qr_svg("https://example.com/b")
    end
  end
end
