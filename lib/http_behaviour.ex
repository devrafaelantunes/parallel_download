defmodule Http.Behaviour do
  @moduledoc """
    Context used to implement the HTTPoison.get behaviour
    This behaviour is used by The Mox Library during tests
  """

  @typep url :: binary()
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @callback get(url, headers, options) :: {:ok, map()} | {:error, binary() | map()}
end
