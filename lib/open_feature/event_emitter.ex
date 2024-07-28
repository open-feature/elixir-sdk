defmodule OpenFeature.EventEmitter do
  use GenServer
  require Logger
  alias OpenFeature.Types

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec add_handler(domain :: Types.domain(), type :: Types.event_type(), handler :: Types.event_handler()) :: :ok
  def add_handler(server \\ __MODULE__, domain, type, handler) do
    GenServer.cast(server, {:add, domain, type, handler})
  end

  @spec remove_handler(domain :: Types.domain(), type :: Types.event_type(), handler :: Types.event_handler()) :: :ok
  def remove_handler(server \\ __MODULE__, domain, type, handler) do
    GenServer.cast(server, {:remove, domain, type, handler})
  end

  @spec list_handlers(domain :: Types.domain(), type :: Types.event_type()) :: [Types.event_handler()]
  def list_handlers(server \\ __MODULE__, domain, type) do
    GenServer.call(server, {:list, domain, type})
  end

  @spec clear_handlers(domain :: Types.domain()) :: :ok
  def clear_handlers(server \\ __MODULE__, domain) do
    GenServer.cast(server, {:clear, domain})
  end

  @spec emit(domain :: Types.domain(), type :: Types.event_type(), details :: map()) :: :ok
  def emit(server \\ __MODULE__, domain, type, details) do
    GenServer.cast(server, {:emit, domain, type, details})
  end

  @impl true
  def init(:ok) do
    {:ok, %{}, :hibernate}
  end

  @impl true
  def handle_cast({:add, domain, type, handler}, state) do
    state =
      Map.update(state, {domain, type}, [handler], fn handlers ->
        [handler | handlers]
      end)

    {:noreply, state, :hibernate}
  end

  def handle_cast({:remove, domain, type, handler}, state) do
    state =
      case Map.pop(state, {domain, type}, []) do
        {[], state} ->
          state

        {handlers, state} ->
          handlers = List.delete(handlers, handler)
          Map.put(state, {domain, type}, handlers)
      end

    {:noreply, state, :hibernate}
  end

  def handle_cast({:clear, domain}, state) do
    state =
      Enum.reduce(state, %{}, fn
        {{^domain, _}, _handlers}, acc -> acc
        {key, handlers}, acc -> Map.put(acc, key, handlers)
      end)

    {:noreply, state, :hibernate}
  end

  def handle_cast({:emit, domain, type, details}, state) do
    generic_details = %{domain: domain}

    state
    |> Map.get({domain, type}, [])
    |> Enum.each(fn handler ->
      try do
        generic_details
        |> Map.merge(details)
        |> handler.()
      rescue
        e ->
          Logger.error("Error executing event handler. Error: #{e}")
      end
    end)

    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_call({:list, domain, type}, _from, state) do
    {:reply, Map.get(state, {domain, type}, []), state, :hibernate}
  end
end
