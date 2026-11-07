defmodule Jaja.Storage do
  @moduledoc """
  Object storage for batch videos, backed by Hetzner Object Storage (S3 compatible).

  Uploads go straight from the browser to the bucket using a presigned `PUT` URL,
  so video bytes never pass through the application. Only the object key is stored
  on the batch; the bucket serves the file publicly at `public_url/1`.
  """

  @upload_expiry_seconds 3600

  @doc """
  Builds an object key for a batch video, e.g. `"batches/aBc123/clip.mp4"`.

  The batch reference namespaces the key so replacing a video never collides with
  another batch, and the random suffix means a replacement gets a fresh URL rather
  than serving a stale cached copy.
  """
  def video_key(batch_reference, filename) do
    extension = filename |> Path.extname() |> String.downcase()
    "batches/#{batch_reference}/#{Nanoid.generate()}#{extension}"
  end

  @doc """
  Presigned `PUT` URL the browser uploads to. Valid for one hour.
  """
  def presigned_upload_url(key) do
    ExAws.S3.presigned_url(config(), :put, bucket(), key, expires_in: @upload_expiry_seconds)
  end

  @doc """
  Uploads `body` directly to `key` in the configured bucket (used by CLI backfill tasks).
  """
  def put_object(key, body, opts \\ []) do
    bucket()
    |> ExAws.S3.put_object(key, body, opts)
    |> ExAws.request(Map.to_list(config()))
  end

  @doc """
  Checks an uploaded S3 object's video codec via `ffprobe` and, if it is not browser-universal
  H.264 (`h264` + `yuv420p` — e.g. phone `hevc`/H.265 recordings), transcodes it with `ffmpeg`
  and re-uploads it as `video/mp4`.
  """
  def ensure_browser_compatible(nil), do: :ok

  def ensure_browser_compatible(key) when is_binary(key) do
    url = public_url(key)

    if needs_transcode?(url) do
      tmp_out = Path.join(System.tmp_dir!(), "jaja-transcode-#{Nanoid.generate()}.mp4")

      try do
        case run_ffmpeg(url, tmp_out) do
          :ok ->
            put_object(key, File.read!(tmp_out), content_type: "video/mp4")
            :ok

          :error ->
            :ok
        end
      after
        File.rm(tmp_out)
      end
    else
      :ok
    end
  end

  @doc """
  Transcodes a local video file to a temporary H.264 `yuv420p` `.mp4` if needed,
  calling `fun.(upload_path, content_type)` and cleaning up any temporary file.
  """
  def with_browser_compatible_file(path, fun) do
    if needs_transcode?(path) do
      tmp_out = Path.join(System.tmp_dir!(), "jaja-transcode-#{Nanoid.generate()}.mp4")

      try do
        case run_ffmpeg(path, tmp_out) do
          :ok -> fun.(tmp_out, "video/mp4")
          :error -> fun.(path, MIME.from_path(path))
        end
      after
        File.rm(tmp_out)
      end
    else
      fun.(path, MIME.from_path(path))
    end
  end

  defp needs_transcode?(input) do
    with ffprobe when not is_nil(ffprobe) <- System.find_executable("ffprobe"),
         {output, 0} <-
           System.cmd(
             ffprobe,
             [
               "-v",
               "error",
               "-select_streams",
               "v:0",
               "-show_entries",
               "stream=codec_name,pix_fmt",
               "-of",
               "csv=p=0",
               input
             ],
             stderr_to_stdout: true
           ) do
      String.trim(output) not in ["h264,yuv420p", "h264,yuvj420p"]
    else
      _ -> false
    end
  end

  defp run_ffmpeg(input, output_path) do
    with ffmpeg when not is_nil(ffmpeg) <- System.find_executable("ffmpeg"),
         {_out, 0} <-
           System.cmd(
             ffmpeg,
             [
               "-y",
               "-v",
               "error",
               "-i",
               input,
               "-vf",
               "format=yuv420p",
               "-c:v",
               "libx264",
               "-preset",
               "veryfast",
               "-crf",
               "23",
               "-c:a",
               "aac",
               "-movflags",
               "+faststart",
               output_path
             ],
             stderr_to_stdout: true
           ) do
      :ok
    else
      _ -> :error
    end
  end

  @doc """
  Public URL an uploaded object is served from. Returns nil when the batch has no video.

  Requires the bucket to allow public reads; nothing here signs the URL.
  """
  def public_url(nil), do: nil

  def public_url(key) do
    "#{scheme()}#{host()}/#{bucket()}/#{key}"
  end

  @doc """
  Whether the bucket is configured. Upload UI is hidden when it is not, so a missing
  credential shows up as an absent feature rather than a crash mid-upload.
  """
  def configured? do
    settings = Application.get_env(:jaja, __MODULE__, [])

    Enum.all?([:bucket, :access_key_id, :secret_access_key], fn key ->
      value = Keyword.get(settings, key)
      is_binary(value) and value != ""
    end)
  end

  defp config do
    settings = Application.get_env(:jaja, __MODULE__, [])

    ExAws.Config.new(:s3,
      access_key_id: Keyword.get(settings, :access_key_id),
      secret_access_key: Keyword.get(settings, :secret_access_key),
      region: Keyword.get(settings, :region, "fsn1"),
      scheme: scheme(),
      host: host(),
      port: 443,
      http_client: ExAws.Request.Req
    )
  end

  defp bucket, do: setting(:bucket)
  defp scheme, do: "https://"

  defp host do
    setting(:host) || "#{setting(:region) || "fsn1"}.your-objectstorage.com"
  end

  defp setting(key) do
    :jaja
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end
end
