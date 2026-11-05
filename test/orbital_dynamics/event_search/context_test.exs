defmodule OrbitalDynamics.EventSearch.ContextTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector}
  alias OrbitalDynamics.EventSearch.{Context, Function, Source}

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({t, 1, 0}, {1, 0, 0}, Epoch.new!(t, :tai), frame())

  defp source(callback, start \\ 0, stop \\ 10),
    do: Source.new!(callback, Epoch.new!(start, :tai), Epoch.new!(stop, :tai), frame(), %{})

  defp function(id, callback), do: Function.new!(id, callback, units: "1", value_tolerance: 0)

  defp with_context(max, callback) do
    previous = Context.current()

    try do
      Context.open(max)
      callback.()
    after
      Context.restore(previous)
    end
  end

  defp captured_function(value) do
    anchors = Enum.to_list(1..1000) |> List.to_tuple()
    fn _ -> {:ok, value * elem(anchors, 999), nil, %{}} end
  end

  test "same-ID callbacks from one closure factory remain distinct, including struct updates" do
    f = function("shared", captured_function(1))
    g = %{f | evaluate: captured_function(-1)}
    h = %{f | id: "different"}
    s = state(1)

    with_context(3, fn ->
      assert {:ok, 1000, nil, %{}} = Function.call(f, s)
      assert {:ok, 1000, nil, %{}} = Function.call(%{f | units: "other"}, s)
      assert {:ok, -1000, nil, %{}} = Function.call(g, s)
      assert {:ok, 1000, nil, %{}} = Function.call(h, s)
      assert Context.counts() == %{source_queries: 0, function_evaluations: 3}

      assert Enum.map(Context.observations(f, source(fn t -> {:ok, state(t)} end)), & &1.value) ==
               [1000]

      assert Enum.map(Context.observations(g, source(fn t -> {:ok, state(t)} end)), & &1.value) ==
               [-1000]

      assert Enum.sort(Enum.map(Context.function_observations(["shared"]), & &1["value"])) == [
               -1000,
               1000
             ]
    end)

    assert Context.current() == nil
  end

  test "source identity retains sampler, coverage and frame; provenance does not change cache identity" do
    sampler = fn _ -> {:unknown, :gap} end
    a = source(sampler)
    b = source(sampler, 0.0, 10.0)
    c = %{a | stop: Epoch.new!(9, :tai)}
    d = %{a | frame: Frame.new!(:different, :toy, :other)}
    e = source(fn _ -> {:unknown, :other_gap} end)

    with_context(5, fn ->
      for s <- [a, b, c, d], do: assert({:unknown, :gap} = Source.at(s, 1))
      assert {:unknown, :gap} = Source.at(%{a | provenance: %{"different" => true}}, 1.0)
      assert {:unknown, :other_gap} = Source.at(e, 1)
      assert Context.counts() == %{source_queries: 5, function_evaluations: 0}
      # Both numeric representations remain visible to the unknown-span audit.
      assert length(Context.observations(function("unused", captured_function(1)), a)) == 2
    end)
  end

  test "full state identity and nested calls retain shared accounting, evidence and exhaustion" do
    sampler = source(fn t -> {:ok, state(t)} end)
    child = function("child", fn s -> {:ok, elem(s.position_km, 1), nil, %{}} end)

    parent =
      function("parent", fn s ->
        {:ok, sampled} = Source.at(sampler, s.epoch.seconds_since_j2000)
        Function.call(child, sampled)
      end)

    with_context(4, fn ->
      assert {:ok, 1, nil, %{}} = Function.call(parent, state(1))
      assert {:ok, 1, nil, %{}} = Function.call(parent, state(1))
      assert {:ok, 2, nil, %{}} = Function.call(child, %{state(1) | position_km: {1, 2, 0}})
      assert Context.counts() == %{source_queries: 1, function_evaluations: 3}
      assert length(Context.function_observations(["parent", "child"])) == 3

      assert catch_throw(Source.at(sampler, 2)) ==
               {:event_search_failed, :event_search_evaluation_budget_exhausted}

      assert Context.counts() == %{source_queries: 1, function_evaluations: 3}
    end)
  end
end
