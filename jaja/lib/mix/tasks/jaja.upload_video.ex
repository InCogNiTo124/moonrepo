defmodule Mix.Tasks.Jaja.UploadVideo do
  @shortdoc "Uploads video file(s) to S3 and attaches them to an existing or archived batch"

  @moduledoc """
  Uploads one or more local video files to Hetzner Object Storage and links them in the database.

  ## Attach to an existing batch (by unique_reference or numeric id)

      mix jaja.upload_video path/to/clip.mp4 --batch aBc123

  ## Backfill standalone historical videos (creates inactive batches ordered by date)

      mix jaja.upload_video ~/Videos/old/*.mp4
      mix jaja.upload_video path/to/clip.mp4 --type eggs --date "2026-06-20 16:50:00"

  When `--date` is omitted for standalone files, the timestamp is inferred from a
  `YYYYMMDD_HHMMSS` pattern in the filename if present, falling back to the file's mtime.
  """

  use Mix.Task

  alias Jaja.Repo
  alias Jaja.Shop
  alias Jaja.Shop.Batch
  alias Jaja.Storage

  @switches [batch: :string, type: :string, date: :string]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    unless Storage.configured?() do
      Mix.raise(
        "Storage is not configured. Set S3_BUCKET, S3_ACCESS_KEY_ID, and S3_SECRET_ACCESS_KEY."
      )
    end

    {opts, files, _invalid} = OptionParser.parse(args, strict: @switches)

    if files == [] do
      Mix.raise(
        "Usage: mix jaja.upload_video <file1> [<file2> ...] [--batch REF_OR_ID] [--type eggs] [--date \"YYYY-MM-DD HH:MM:SS\"]"
      )
    end

    case Keyword.get(opts, :batch) do
      nil ->
        Enum.each(files, &upload_standalone_video(&1, opts))

      batch_ident ->
        if length(files) > 1 do
          Mix.raise("--batch can only be used with a single video file.")
        end

        upload_for_existing_batch(hd(files), batch_ident)
    end
  end

  defp upload_for_existing_batch(path, batch_ident) do
    ensure_file!(path)
    batch = find_batch!(batch_ident)
    key = Storage.video_key(batch.unique_reference, Path.basename(path))

    upload_bytes!(path, key)
    {:ok, updated} = Shop.set_batch_video(batch, key)

    Mix.shell().info(
      "Attached #{Path.basename(path)} to batch #{updated.unique_reference} (id=#{updated.id}) -> #{Storage.public_url(key)}"
    )
  end

  defp upload_standalone_video(path, opts) do
    ensure_file!(path)
    type = Keyword.get(opts, :type, "eggs")
    datetime = resolve_datetime(path, Keyword.get(opts, :date))
    ref = Nanoid.generate()
    key = Storage.video_key(ref, Path.basename(path))
    price = Shop.get_last_price_for_type(type) || 3.5

    upload_bytes!(path, key)

    {:ok, batch} =
      %Batch{active: false}
      |> Batch.changeset(%{
        type: type,
        amount: 1,
        price: price,
        datetime: datetime,
        unique_reference: ref,
        video_key: key
      })
      |> Repo.insert()

    Mix.shell().info(
      "Uploaded #{Path.basename(path)} as historical batch #{batch.unique_reference} (#{Calendar.strftime(batch.datetime, "%Y-%m-%d %H:%M:%S")}) -> #{Storage.public_url(key)}"
    )
  end

  defp upload_bytes!(path, key) do
    Storage.with_browser_compatible_file(path, fn upload_path, content_type ->
      body = File.read!(upload_path)

      case Storage.put_object(key, body, content_type: content_type) do
        {:ok, %{status_code: code}} when code in 200..299 ->
          :ok

        other ->
          Mix.raise("Failed to upload #{path} to S3: #{inspect(other)}")
      end
    end)
  end

  defp find_batch!(ident) do
    case Integer.parse(ident) do
      {id, ""} ->
        Repo.get(Batch, id) || Shop.get_batch_by_reference!(ident)

      _ ->
        Shop.get_batch_by_reference!(ident)
    end
  end

  defp ensure_file!(path) do
    unless File.regular?(path) do
      Mix.raise("File not found: #{path}")
    end
  end

  defp resolve_datetime(_path, date_str) when is_binary(date_str) do
    normalized = if String.length(date_str) == 10, do: date_str <> " 12:00:00", else: date_str

    case NaiveDateTime.from_iso8601(normalized) do
      {:ok, ndt} ->
        NaiveDateTime.truncate(ndt, :second)

      {:error, _} ->
        Mix.raise("Invalid --date #{inspect(date_str)}. Use \"YYYY-MM-DD HH:MM:SS\".")
    end
  end

  defp resolve_datetime(path, nil) do
    basename = Path.basename(path)

    case Regex.run(~r/(20\d{2})(\d{2})(\d{2})[_-](\d{2})(\d{2})(\d{2})/, basename) do
      [_, y, m, d, hh, mm, ss] ->
        NaiveDateTime.new!(
          String.to_integer(y),
          String.to_integer(m),
          String.to_integer(d),
          String.to_integer(hh),
          String.to_integer(mm),
          String.to_integer(ss)
        )

      nil ->
        %{mtime: mtime} = File.stat!(path, time: :posix)
        mtime |> DateTime.from_unix!() |> DateTime.to_naive()
    end
  end
end
