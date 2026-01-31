defmodule ProxyCat.Http do
  @moduledoc """
  Generic HTTP client dependency free. It needs to be provided
  an adapter in configuration to use.
  """
  alias ProxyCat.Http.Error
  alias ProxyCat.Http.Request
  alias ProxyCat.Http.Response

  require Logger
  @type header :: {String.t(), String.t()}

  @type option ::
          {:method, Request.method()}
          | {:header, [header()]}
          | {:body, any()}
          | {:url, URI.t()}
          | {atom(), any()}
  @request_options ~w(method url body headers)a

  @doc "Performs a HTTP request with configured adapter"
  @spec request([option()]) :: {:ok, Request.t(), Response.t()} | {:error, Error.t()}
  def request(options) do
    {request_options, options} = Keyword.split(options, @request_options)

    request = %Request{
      method: Keyword.get(request_options, :method, :get),
      body: Keyword.get(request_options, :body),
      headers: Keyword.get(request_options, :headers, []),
      url: Keyword.fetch!(request_options, :url)
    }

    adapter = adapter()

    case adapter.request(request, options) do
      {:ok, %Response{} = response} ->
        log_response(:success, request, response)

        {:ok, request, response}

      {:error, error} ->
        log_response(:error, request, error)

        {:error, request, error}
    end
  end

  @doc "Performs an HTTP request expecting a 2XX response, returning error otherwise"
  @spec request_200([option()]) ::
          {:ok, Request.t(), Response.t()}
          | {:error, Request.t(), Response.t()}
          | {:error, Request.t(), Error.t()}
  def request_200(options) do
    with {:ok, request, %Response{status: status} = response} when status not in 200..299 <-
           request(options) do
      {:error, request, response}
    end
  end

  defp log_response(:error, request, error) do
    with level when level != false <- log_level(:error) do
      Logger.log(
        level,
        "[#{inspect(__MODULE__)}] [#{String.upcase(to_string(request.method))}] [error] #{inspect(error)}"
      )
    end
  end

  defp log_response(:success, request, response) do
    with level when level != false <- log_level(:success) do
      Logger.log(
        level,
        "[#{inspect(__MODULE__)}] [#{String.upcase(to_string(request.method))}] [#{response.status}] #{URI.to_string(request.url)}"
      )
    end
  end

  defp adapter do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:adapter)
  end

  defp log_level(:error) do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:log_levels)
    |> Keyword.fetch!(:error)
  end

  defp log_level(:success) do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:log_levels)
    |> Keyword.fetch!(:success)
  end
end
