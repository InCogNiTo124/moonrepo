# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Jaja.Repo.insert!(%Jaja.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Jaja.Repo
alias Jaja.Shop.Product

products = [
  %{name: "Eggs", slug: "eggs"},
  %{name: "Turkey", slug: "turkey"}
]

for product <- products do
  case Repo.get_by(Product, slug: product.slug) do
    nil ->
      %Product{}
      |> Product.changeset(product)
      |> Repo.insert!()

    _ ->
      IO.puts("Product #{product.name} already exists.")
  end
end
