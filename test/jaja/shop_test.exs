defmodule Jaja.ShopTest do
  use Jaja.DataCase

  alias Jaja.Shop

  describe "batches" do
    alias Jaja.Shop.Batch

    import Jaja.ShopFixtures

    @invalid_attrs %{type: nil, amount: nil, datetime: nil, unique_reference: nil, price: nil}

    test "list_batches/0 returns all batches" do
      batch = batch_fixture()
      assert Shop.list_batches() == [Repo.preload(batch, :orders)]
    end

    test "get_batch!/1 returns the batch with given id" do
      batch = batch_fixture()
      assert Shop.get_batch!(batch.id) == batch
    end

    test "create_batch/1 with valid data creates a batch" do
      valid_attrs = %{
        type: "some type",
        amount: 42,
        datetime: ~N[2025-11-17 18:12:00],
        unique_reference: "some unique_reference",
        price: 3.5
      }

      assert {:ok, %Batch{} = batch} = Shop.create_batch(valid_attrs)
      assert batch.type == "some type"
      assert batch.amount == 42
      assert batch.datetime == ~N[2025-11-17 18:12:00]
      assert batch.unique_reference == "some unique_reference"
      assert batch.price == 3.5
    end

    test "create_batch/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_batch(@invalid_attrs)
    end

    test "update_batch/2 with valid data updates the batch" do
      batch = batch_fixture()

      update_attrs = %{
        type: "some updated type",
        amount: 43,
        datetime: ~N[2025-11-18 18:12:00],
        unique_reference: "some updated unique_reference",
        price: 4.5
      }

      assert {:ok, %Batch{} = batch} = Shop.update_batch(batch, update_attrs)
      assert batch.type == "some updated type"
      assert batch.amount == 43
      assert batch.datetime == ~N[2025-11-18 18:12:00]
      assert batch.unique_reference == "some updated unique_reference"
      assert batch.price == 4.5
    end

    test "update_batch/2 with invalid data returns error changeset" do
      batch = batch_fixture()
      assert {:error, %Ecto.Changeset{}} = Shop.update_batch(batch, @invalid_attrs)
      assert batch == Shop.get_batch!(batch.id)
    end

    test "delete_batch/1 deletes the batch" do
      batch = batch_fixture()
      assert {:ok, %Batch{}} = Shop.delete_batch(batch)
      assert_raise Ecto.NoResultsError, fn -> Shop.get_batch!(batch.id) end
    end

    test "change_batch/1 returns a batch changeset" do
      batch = batch_fixture()
      assert %Ecto.Changeset{} = Shop.change_batch(batch)
    end
  end

  describe "orders" do
    alias Jaja.Shop.Order

    import Jaja.ShopFixtures

    @invalid_attrs %{name: nil, amount: nil, datetime: nil, batch_reference: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Shop.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Shop.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      batch = batch_fixture()
      valid_attrs = %{
        name: "some name",
        amount: 42,
        datetime: ~N[2025-11-17 18:13:00],
        batch_reference: batch.unique_reference
      }

      assert {:ok, %Order{} = order} = Shop.create_order(valid_attrs)
      assert order.name == "some name"
      assert order.amount == 42
      assert order.datetime == ~N[2025-11-17 18:13:00]
      assert order.batch_reference == batch.unique_reference
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      other_batch = batch_fixture()

      update_attrs = %{
        name: "some updated name",
        amount: 43,
        datetime: ~N[2025-11-18 18:13:00],
        batch_reference: other_batch.unique_reference
      }

      assert {:ok, %Order{} = order} = Shop.update_order(order, update_attrs)
      assert order.name == "some updated name"
      assert order.amount == 43
      assert order.datetime == ~N[2025-11-18 18:13:00]
      assert order.batch_reference == other_batch.unique_reference
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Shop.update_order(order, @invalid_attrs)
      assert order == Shop.get_order!(order.id)
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Shop.change_order(order)
    end
  end

  describe "products" do
    alias Jaja.Shop.Product

    import Jaja.ShopFixtures

    @invalid_attrs %{name: nil, slug: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Shop.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Shop.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{name: "some name", slug: "some slug"}

      assert {:ok, %Product{} = product} = Shop.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.slug == "some slug"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{name: "some updated name", slug: "some updated slug"}

      assert {:ok, %Product{} = product} = Shop.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.slug == "some updated slug"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Shop.update_product(product, @invalid_attrs)
      assert product == Shop.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Shop.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Shop.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Shop.change_product(product)
    end
  end
end
