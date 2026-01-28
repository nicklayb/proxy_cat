defmodule ProxyCat.Backend.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("oauth/callback/:key", to: ProxyCat.Backend.OauthHandler)

  match(_) do
    send_resp(conn, 400, "Not found")
  end
end
