defmodule Jaja.ShopFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jaja.Shop` context.
  """

  @doc """
  Generate a unique batch unique_reference.
  """
  def unique_batch_unique_reference,
    do: "some unique_reference#{System.unique_integer([:positive])}"

  @doc """
  Generate a batch.
  """
  def batch_fixture(attrs \\ %{}) do
    {:ok, batch} =
      attrs
      |> Enum.into(%{
        amount: 42,
        datetime: ~N[2025-11-17 18:12:00],
        type: "some type",
        unique_reference: unique_batch_unique_reference(),
        price: 3.5
      })
      |> Jaja.Shop.create_batch()

    batch
  end

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    batch_reference =
      attrs[:batch_reference] ||
        (
          batch = batch_fixture()
          batch.unique_reference
        )

    {:ok, order} =
      attrs
      |> Enum.into(%{
        amount: 42,
        batch_reference: batch_reference,
        datetime: ~N[2025-11-17 18:13:00],
        name: "some name"
      })
      |> Jaja.Shop.create_order()

    order
  end

  @doc """
  Generate a unique product slug.
  """
  def unique_product_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "some name",
        slug: unique_product_slug()
      })
      |> Jaja.Shop.create_product()

    product
  end
end
