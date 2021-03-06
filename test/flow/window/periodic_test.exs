alias Experimental.Flow

defmodule Flow.Window.PeriodicTest do
  use ExUnit.Case, async: true

  defp single_window do
    Flow.Window.periodic(100, :millisecond)
  end

  test "emits based on intervals" do
    assert Flow.from_enumerable(Stream.concat(1..10, Stream.timer(:infinity)), max_demand: 5)
           |> Flow.partition(window: single_window(), stages: 1, max_demand: 10)
           |> Flow.reduce(fn -> 0 end, & &1 + &2)
           |> Flow.map_state(fn state, index, {:periodic, window, :done} -> {state, index, window} end)
           |> Flow.emit(:state)
           |> Enum.take(2) == [{55, {0, 1}, 0}, {0, {0, 1}, 1}]
  end

  test "emits based on intervals with count triggers" do
    assert Flow.from_enumerable(Stream.concat(1..10, Stream.timer(:infinity)), max_demand: 5, stages: 2)
           |> Flow.partition(window: single_window() |> Flow.Window.trigger_every(5),
                             stages: 1, max_demand: 10)
           |> Flow.reduce(fn -> 0 end, & &1 + &2)
           |> Flow.map_state(fn state, _, {:periodic, window, trigger} -> {state, window, trigger} end)
           |> Flow.emit(:state)
           |> Enum.take(3) == [{15, 0, {:every, 5}},
                               {55, 0, {:every, 5}},
                               {55, 0, :done}]
  end
end
