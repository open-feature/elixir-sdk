defmodule OpenFeature.EventEmitterTest do
  use ExUnit.Case, async: true
  alias OpenFeature.EventEmitter

  setup do
    pid = start_supervised!({EventEmitter, name: __MODULE__})
    %{pid: pid}
  end

  test "add_handler/3 adds a handler", %{pid: pid} do
    handler = fn _details -> :ok end
    EventEmitter.add_handler(pid, "domain", :ready, handler)
    assert EventEmitter.list_handlers(pid, "domain", :ready) == [handler]
  end

  test "remove_handler/3 removes a handler", %{pid: pid} do
    handler1 = fn _details -> :ok end
    handler2 = fn _details -> :ok end
    handler3 = fn _details -> :ok end
    EventEmitter.add_handler(pid, "domain1", "ready", handler1)
    EventEmitter.add_handler(pid, "domain1", "ready", handler2)
    EventEmitter.add_handler(pid, "domain2", "ready", handler3)
    EventEmitter.remove_handler(pid, "domain1", "ready", handler1)
    assert EventEmitter.list_handlers(pid, "domain1", "ready") == [handler2]
    assert EventEmitter.list_handlers(pid, "domain2", "ready") == [handler3]
  end

  test "list_handlers/2 lists handlers", %{pid: pid} do
    handler1 = fn _details -> :ok end
    handler2 = fn _details -> :ok end
    handler3 = fn _details -> :ok end
    EventEmitter.add_handler(pid, "domain1", "ready", handler1)
    EventEmitter.add_handler(pid, "domain1", "ready", handler2)
    EventEmitter.add_handler(pid, "domain2", "ready", handler3)
    assert EventEmitter.list_handlers(pid, "domain1", "ready") == [handler2, handler1]
  end

  test "clear_handlers/1 clears handlers", %{pid: pid} do
    handler = fn _details -> :ok end
    EventEmitter.add_handler(pid, "domain", "ready", handler)
    EventEmitter.clear_handlers(pid, "domain")
    assert EventEmitter.list_handlers(pid, "domain", "ready") == []
  end

  test "emit/3 calls handlers with correct details", %{pid: pid} do
    parent = self()
    handler = fn details -> send(parent, {:handler_called, details}) end
    EventEmitter.add_handler(pid, "domain", "ready", handler)
    EventEmitter.emit(pid, "domain", "ready", %{key: "value"})
    assert_receive {:handler_called, %{domain: "domain", key: "value"}}
  end
end
