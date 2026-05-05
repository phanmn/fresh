defmodule Fresh.TestClient do
  @moduledoc false

  use Fresh

  def handle_preconnect(headers, state) do
    {:ok,
     [
       {"pid", state[:pid] |> :erlang.term_to_binary() |> Base.encode64()},
       {"ref", state[:ref] |> :erlang.term_to_binary() |> Base.encode64()}
     ] ++ headers, Map.put(Map.new(state), :preconnect, "preconnect")}
  end

  def handle_connect(_status, _headers, state) do
    {:reply, [{:text, state[:welcome]}, {:text, state[:preconnect]}], state}
  end

  def handle_control(frame, state) do
    send(state[:pid], {:control, frame})
    {:ok, state}
  end

  def handle_in({:text, "try closing from callback"}, state) do
    {:close, 1000, "normal", state}
  end

  def handle_in(frame, state) do
    send(state[:pid], {:data, frame})
    {:ok, state}
  end

  def handle_info({:send_frame, frame}, state) do
    {:reply, [frame], state}
  end

  def handle_info(message, state) do
    send(state[:pid], {:info, message})
    {:ok, state}
  end

  def handle_error(error, state) do
    send(state[:pid], {:error, error})
    :close
  end

  def handle_disconnect(code, reason, state) do
    send(state[:pid], {:close, code, reason})

    if code == 1013 do
      {:close, :shutdown}
    else
      :reconnect
    end
  end

  def handle_terminate(reason, state) do
    send(state[:pid], {:terminate, reason})
  end
end
