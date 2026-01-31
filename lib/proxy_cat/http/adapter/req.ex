defmodule ProxyCat.Http.Adapter.Req do
  @moduledoc """
  Req adapter to make HTTP requests
  """
  @behaviour ProxyCat.Http.Adapter

  alias ProxyCat.Http.Error
  alias ProxyCat.Http.Request
  alias ProxyCat.Http.Response

  @impl ProxyCat.Http.Adapter
  def request(%Request{} = request, options) do
    req_options = to_options(request, options)

    case Req.request(req_options) do
      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:ok, %Response{status: status, body: body, headers: headers}}

      {:error, %error_type{} = error} ->
        {:error, %Error{error: error_type, detail: Exception.message(error)}}
    end
  end

  defp to_options(%Request{url: url, method: method, headers: headers, body: body}, options) do
    [
      body: body,
      headers: headers,
      url: url,
      method: method
    ]
    |> Enum.filter(&validate_option/1)
    |> Keyword.merge(options)
  end

  defp validate_option({:body, body}), do: not is_nil(body) and body != ""

  defp validate_option({:headers, headers}), do: Enum.any?(headers)

  defp validate_option(_other_option), do: true
end
