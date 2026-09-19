defmodule Jaja.OrderReferenceTest do
  use Jaja.DataCase, async: true

  alias Jaja.Shop

  setup do
    Jaja.Repo.insert!(%Jaja.Shop.Product{name: "Eggs", slug: "eggs"})
    {:ok, batch} = Shop.create_batch(%{"type" => "eggs", "amount" => "10", "price" => "3.00"})
    %{batch: batch}
  end

  defp order_attrs(batch, extra \\ %{}) do
    Map.merge(
      %{"batch_reference" => batch.unique_reference, "name" => "Ana", "amount" => "1"},
      extra
    )
  end

  test "every order gets its own public reference", %{batch: batch} do
    {:ok, first} = Shop.create_order(order_attrs(batch))
    {:ok, second} = Shop.create_order(order_attrs(batch))

    assert is_binary(first.reference) and byte_size(first.reference) == 21
    refute first.reference == second.reference
  end

  test "the reference cannot be chosen by the customer", %{batch: batch} do
    {:ok, order} = Shop.create_order(order_attrs(batch, %{"reference" => "mine"}))

    refute order.reference == "mine"
  end

  test "an order is found by its reference", %{batch: batch} do
    {:ok, order} = Shop.create_order(order_attrs(batch))

    assert Shop.get_order_by_reference!(order.reference).id == order.id
  end
end
