defmodule Fresh.TestRouter do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  plug :match
  plug :dispatch

  get "/websocket" do
    with [pid] <- get_req_header(conn, "pid"),
         [ref] <- get_req_header(conn, "ref") do
      pid = pid |> Base.decode64!() |> :erlang.binary_to_term()
      ref = ref |> Base.decode64!() |> :erlang.binary_to_term()

      send(pid, {ref, :header})
    end

    conn
    |> WebSockAdapter.upgrade(Fresh.WebSocketHandler, [], timeout: :infinity)
    |> halt()
  end
end
