defmodule Jaja.Release do
  @app :jaja

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          Ecto.Migrator.run(repo, :up, all: true)
          seed()
        end)
    end
  end

  defp seed do
    seed_script = Application.app_dir(@app, "priv/repo/seeds.exs")

    if File.exists?(seed_script) do
      Code.eval_file(seed_script)
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
