defmodule ProxyCat.HttpTest do
  use ProxyCat.BaseCase, async: true

  alias ProxyCat.Http
  alias ProxyCat.Http.Error
  alias ProxyCat.Http.Request
  alias ProxyCat.Http.Response

  setup [:verify_on_exit!]

  @default_tag [
    options: [
      url: URI.parse("http://service.com"),
      body: "somebody",
      headers: [{"accept", "*/*"}],
      method: :get
    ],
    extra_options: [decode_body: false]
  ]

  describe "request/1" do
    @tag @default_tag
    test "returns ok with request and response when 200", %{
      options: options,
      extra_options: extra_options
    } do
      response = %Response{
        status: 200,
        body: "response",
        headers: [{"content-type", "application/json"}]
      }

      mock_http(options, extra_options, fn _request, _extra_options ->
        {:ok, response}
      end)

      assert {:ok, request, ^response} =
               options
               |> Keyword.merge(extra_options)
               |> Http.request()

      assert_request(request, options)
    end

    @tag @default_tag
    test "returns ok with request and response when non 200", %{
      options: options,
      extra_options: extra_options
    } do
      response = %Response{
        status: 404,
        body: "response",
        headers: [{"content-type", "application/json"}]
      }

      mock_http(options, extra_options, fn _request, _extra_options ->
        {:ok, response}
      end)

      assert {:ok, request, ^response} =
               options
               |> Keyword.merge(extra_options)
               |> Http.request()

      assert_request(request, options)
    end

    @tag @default_tag
    test "returns error request when failed", %{
      options: options,
      extra_options: extra_options
    } do
      error = %Error{
        error: "Error",
        detail: "error"
      }

      mock_http(options, extra_options, fn _request, _extra_options ->
        {:error, error}
      end)

      assert {:error, request, ^error} =
               options
               |> Keyword.merge(extra_options)
               |> Http.request()

      assert_request(request, options)
    end
  end

  describe "request_200/1" do
    @tag @default_tag
    test "200 request remains successful", %{options: options, extra_options: extra_options} do
      response = %Response{
        status: 200,
        body: "Body",
        headers: [{"content-type", "application/json"}]
      }

      mock_http(options, extra_options, fn _request, _extra_options ->
        {:ok, response}
      end)

      assert {:ok, request, ^response} =
               options
               |> Keyword.merge(extra_options)
               |> Http.request_200()

      assert_request(request, options)
    end

    @tag @default_tag
    test "converts non 200 requests to error", %{options: options, extra_options: extra_options} do
      response = %Response{
        status: 404,
        body: "Not found",
        headers: [{"content-type", "application/json"}]
      }

      mock_http(options, extra_options, fn _request, _extra_options ->
        {:ok, response}
      end)

      assert {:error, request, ^response} =
               options
               |> Keyword.merge(extra_options)
               |> Http.request_200()

      assert_request(request, options)
    end
  end

  defp mock_http(options, extra_options, response_callback) do
    Mox.expect(ProxyCat.Http.Adapter.Mock, :request, fn request, ^extra_options ->
      assert_request(request, options)

      response_callback.(request, extra_options)
    end)
  end

  defp assert_request(request, options) do
    url = Keyword.fetch!(options, :url)
    body = Keyword.fetch!(options, :body)
    headers = Keyword.fetch!(options, :headers)
    method = Keyword.fetch!(options, :method)

    assert %Request{
             url: ^url,
             body: ^body,
             headers: ^headers,
             method: ^method
           } = request
  end
end
