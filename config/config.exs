use Mix.Config

config :parallel_download, :http_client, HTTPoison

import_config "#{Mix.env()}.exs"
