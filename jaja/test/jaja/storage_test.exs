defmodule Jaja.StorageTest do
  use ExUnit.Case, async: false

  alias Jaja.Storage

  setup do
    original = Application.get_env(:jaja, Storage)

    Application.put_env(:jaja, Storage,
      bucket: "jaja-videos",
      region: "fsn1",
      access_key_id: "AKIAEXAMPLE",
      secret_access_key: "secretexample"
    )

    on_exit(fn -> Application.put_env(:jaja, Storage, original) end)
    :ok
  end

  describe "video_key/2" do
    test "namespaces the key by batch reference and keeps the extension" do
      key = Storage.video_key("aBc123", "Farm Clip.MP4")

      assert String.starts_with?(key, "batches/aBc123/")
      assert String.ends_with?(key, ".mp4")
    end

    test "is unique per call, so replacing a video never serves a cached copy" do
      refute Storage.video_key("aBc123", "clip.mp4") == Storage.video_key("aBc123", "clip.mp4")
    end
  end

  describe "presigned_upload_url/1" do
    test "signs a PUT against the Hetzner endpoint with an expiry" do
      {:ok, url} = Storage.presigned_upload_url("batches/aBc123/clip.mp4")

      assert url =~ "https://fsn1.your-objectstorage.com/jaja-videos/batches/aBc123/clip.mp4"
      assert url =~ "X-Amz-Signature="
      assert url =~ "X-Amz-Expires=3600"
    end
  end

  describe "public_url/1" do
    test "points at the same object the upload wrote" do
      assert Storage.public_url("batches/aBc123/clip.mp4") ==
               "https://fsn1.your-objectstorage.com/jaja-videos/batches/aBc123/clip.mp4"
    end

    test "returns nil when the batch has no video" do
      assert Storage.public_url(nil) == nil
    end
  end

  describe "configured?/0" do
    test "is false when credentials are missing" do
      Application.put_env(:jaja, Storage, bucket: "jaja-videos", region: "fsn1")
      refute Storage.configured?()
    end

    test "is false when a credential is blank" do
      Application.put_env(:jaja, Storage,
        bucket: "jaja-videos",
        access_key_id: "",
        secret_access_key: "secretexample"
      )

      refute Storage.configured?()
    end

    test "is true once bucket and credentials are set" do
      assert Storage.configured?()
    end
  end
end
