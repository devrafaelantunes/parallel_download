defmodule ParallelDownload.Downloader do
  @moduledoc """
    Context used to make GET requests to a list of validated URLs
    Uses HTTPoison, Logger, Elixir's Task module plus Erlang's URI and Time libraries
  """
  require Logger

  @typep url :: binary()

  # Retrieves the HttpClient based on the Enviroment
  @http_client Application.get_env(:parallel_download, :http_client)

  @valid_schemes ["http", "https"]

  # Request timeout limit (ms)
  @timeout 2000

  # Starts the Parallel Downloader
  # This function takes a list of URLs and makes GET requests to them in parallel.
  # It returns :ok and a log message for each request based on their result
  # Example of a valid URL: "http://www.telnyx.com" "https://rafaelantunes.com.br"
  # Example of an invalid URL: "www.mywebsite" (If not valid, the URL is ignored)
  @spec start(list(url)) :: :ok
  def start(websites \\ System.argv()) when is_list(websites) do
    websites
    |> validate_urls()
    |> Task.async_stream(&request/1, ordered: false)
    |> Stream.run()
  end

  defp request(website) do
    # Makes the request and uses the Erlang Timer library to calculate the latency
    {latency_usec, response} =
      :timer.tc(fn ->
        @http_client.get(website, [], timeout: @timeout, follow_redirect: true)
      end)

    # Converts the latency to milliseconds
    latency_ms = System.convert_time_unit(latency_usec, :microsecond, :millisecond)

    case response do
      # Returns the request status code and latency if the URL is active and valid
      {:ok, %{status_code: status_code}} ->
        Logger.info("GET #{website} -> #{latency_ms}ms #{status_code}")

      # Returns the latency and nxdomain if the URL does not exist
      {:error, %{reason: :nxdomain}} ->
        Logger.warn("GET #{website} -> #{latency_ms}ms nxdomain")

      # Timeout if the server does not respond
      {:error, %{reason: :timeout}} ->
        Logger.warn("TIMEOUT #{website}")

      # Catches other errors
      {:error, %{reason: reason}} ->
        Logger.error("ERROR #{website} -> #{reason}")
    end
  end

  defp validate_urls(urls) do
    Enum.reduce(urls, [], fn url, valid_urls ->
      uri = URI.parse(url)

      # Validates the URL
      if uri.scheme != nil and uri.scheme in @valid_schemes and uri.host =~ "." do
        # If valid, the URL is added to the accumulator
        [url | valid_urls]
      else
        # If invalid, the URL is ignored
        Logger.warn("IGNORED #{url}")
        valid_urls
      end
    end)
  end
end
