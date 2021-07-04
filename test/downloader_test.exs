defmodule ParallelDownload.DownloaderTest do
  use ExUnit.Case, async: true

  import Mox
  import ExUnit.CaptureLog

  alias Http.Mock
  alias ParallelDownload.Downloader

  setup :verify_on_exit!

  defp download(url) do
    capture_log(fn ->
      Downloader.start(url)
    end)
  end

  describe "start/1" do
    test "with a single valid url" do
      valid_url = [
        "https://www.google.com"
      ]

      # The mock is expected to be called once
      expect(Mock, :get, fn _, _, _ ->
        # Sets the latency to 50ms
        Process.sleep(50)

        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      assert download(valid_url) =~ "GET #{valid_url} -> 50ms 200"
    end

    test "with multiple valid urls" do
      valid_urls = [
        "https://www.google.com",
        "https://www.amazon.com",
        "https://www.apple.com"
      ]

      # The mock is expected to be called three times
      expect(Mock, :get, 3, fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200}} end)

      log = download(valid_urls)

      Enum.each(valid_urls, fn url ->
        assert log =~ "GET #{url} -> 0ms 200"
      end)
    end

    test "ignores the request when the url is invalid" do
      invalid_url = ["notanurl"]

      # The mock is not expected to be called
      expect(Mock, :get, 0, fn _, _, _ -> :not_called end)

      assert download(invalid_url) =~ "IGNORED #{invalid_url}"
    end

    test "timesout when the url is unreachable" do
      unreachable_url = ["https://unreachableurl.com:81"]

      # The mock is expected to be called once
      expect(Mock, :get, fn _, _, _ -> {:error, %{reason: :timeout}} end)

      assert download(unreachable_url) =~ "TIMEOUT #{unreachable_url}"
    end

    test "returns nxdomain when the url is inactive" do
      inactive_url = ["https://inactivedomain.com"]

      # The mock is expected to be called once
      expect(Mock, :get, fn _, _, _ -> {:error, %{reason: :nxdomain}} end)

      assert download(inactive_url) =~ "GET #{inactive_url} -> 0ms nxdomain"
    end
  end
end
