defmodule OrbitalDynamics.MissionAnalysis.Scheduling.Work do
  @moduledoc "Per-planning-invocation callback accounting, including failed trials and an optional shared hard cap."
  @key {__MODULE__, :context}
  @kinds ~w(attitude resource path endpoint)
  def validate!(nil), do: nil

  def validate!(%{"max_evaluations" => n} = c)
      when map_size(c) == 1 and is_integer(n) and n in 1..100_000_000, do: c

  def validate!(_),
    do: raise(ArgumentError, "work_budget requires max_evaluations in 1..100000000")

  def active?, do: Process.get(@key) != nil
  def exhausted?, do: active?() and Process.get(@key).exhausted
  def counts, do: if(active?(), do: Process.get(@key).counts, else: Map.new(@kinds, &{&1, 0}))

  def run(false, _, fun), do: fun.()

  def run(true, budget, fun) do
    previous = Process.get(@key)
    if previous, do: raise(ArgumentError, "nested planning work scopes are unsupported")

    Process.put(@key, %{
      counts: Map.new(@kinds, &{&1, 0}),
      max: if(budget, do: budget["max_evaluations"], else: nil),
      total: 0,
      exhausted: false,
      trials: []
    })

    try do
      result = fun.()
      c = Process.get(@key)

      evidence = %{
        "counts" => c.counts,
        "total_evaluations" => c.total,
        "max_evaluations" => c.max || :null,
        "budget_exhausted" => c.exhausted,
        "trials" => c.trials,
        "scope" =>
          "uncached attitude, resource-step and path-rule callbacks during service trials; endpoint callbacks are separately counted; opportunity generation, propagation and model preparation excluded"
      }

      case result do
        {:ok, a, d, b, r, search} ->
          {:ok, a, d, b, r, Map.put(search || %{}, "work_accounting", evidence)}

        {:error, :planning_work_budget_exhausted} ->
          {:error, {:planning_work_budget_exhausted, evidence}}

        error ->
          error
      end
    after
      Process.delete(@key)
    end
  end

  def charge!(kind) when kind in @kinds do
    if active?() do
      c = Process.get(@key)

      if c.max && c.total >= c.max do
        Process.put(@key, %{c | exhausted: true})
        throw(:planning_work_budget_exhausted)
      end

      Process.put(@key, %{c | total: c.total + 1, counts: Map.update!(c.counts, kind, &(&1 + 1))})
    end

    :ok
  end

  def guard(fun) do
    try do
      fun.()
    catch
      :planning_work_budget_exhausted -> {:error, :planning_work_budget_exhausted}
    end
  end

  def trial(order, pins, fun) do
    if active?() do
      before = counts()
      result = guard(fun)
      c = Process.get(@key)
      delta = Map.new(@kinds, fn k -> {k, c.counts[k] - before[k]} end)

      row = %{
        "trial" => length(c.trials) + 1,
        "opportunity_ids" => Enum.map(order, & &1["id"]),
        "reservations" =>
          Enum.map(pins, &Map.take(&1, ~w(request_id asset_id starts_at_s ends_at_s))),
        "counts" => delta,
        "total_evaluations_after" => c.total,
        "outcome" => if(match?({:ok, _, _, _, _}, result), do: "returned", else: "failed"),
        "failure" => if(match?({:error, _}, result), do: inspect(elem(result, 1)), else: :null)
      }

      Process.put(@key, %{c | trials: c.trials ++ [row]})
      result
    else
      fun.()
    end
  end
end
