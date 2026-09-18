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
      port: 443
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
