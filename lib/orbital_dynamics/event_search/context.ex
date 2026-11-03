defmodule OrbitalDynamics.EventSearch.Context do
  @moduledoc false
  # Per-invocation accounting lets nested built-in geometry/derivative queries
  # share the same cache and budget without changing the public callback shape.
  @key {__MODULE__, :evaluation_context}
  def current, do: Process.get(@key)

  def open(max) do
    if current() != nil,
      do: raise(ArgumentError, "nested event searches are unsupported inside event callbacks")

    Process.put(@key, %{
      max: max,
      source_queries: 0,
      function_evaluations: 0,
      states: %{},
      functions: %{}
    })
  end

  def restore(nil), do: Process.delete(@key)
  def restore(context), do: Process.put(@key, context)

  def observations(f, source) do
    context = current()

    values =
      for {{id, callback, state}, result} <- context.functions,
          id == f.id and callback == f.evaluate do
        case result do
          {:ok, value, _, _} ->
            %{t: state.epoch.seconds_since_j2000, status: :known, value: value}

          _ ->
            %{t: state.epoch.seconds_since_j2000, status: :unknown}
        end
      end

    missing =
      for {{sampler, start, stop, frame, t}, result} <- context.states,
          sampler == source.sampler and start == source.start and stop == source.stop and
            frame == source.frame,
          match?({:unknown, _}, result),
          do: %{t: t, status: :unknown}

    values ++ missing
  end

  @doc false
  def function_observations(ids) do
    for {{id, _callback, state}, result} <- current().functions, id in ids do
      case result do
        {:ok, value, rate, metadata} ->
          %{
            "function_id" => id,
            "epoch_s" => state.epoch.seconds_since_j2000,
            "status" => "known",
            "value" => value,
            "rate" => rate || :null,
            "metadata" => metadata
          }

        {:unknown, reason} ->
          %{
            "function_id" => id,
            "epoch_s" => state.epoch.seconds_since_j2000,
            "status" => "unknown",
            "reason" => inspect(reason)
          }
      end
    end
    |> Enum.sort_by(&{&1["function_id"], &1["epoch_s"]})
  end

  def counts do
    c = current()
    %{source_queries: c.source_queries, function_evaluations: c.function_evaluations}
  end

  def state(source, t, callback) do
    key = {source.sampler, source.start, source.stop, source.frame, t * 1.0}
    memo(:states, :source_queries, key, callback)
  end

  def function(f, state, callback),
    do: memo(:functions, :function_evaluations, {f.id, f.evaluate, state}, callback)

  defp memo(cache, counter, key, callback) do
    case current() do
      nil ->
        callback.()

      c ->
        case Map.fetch(c[cache], key) do
          {:ok, value} ->
            value

          :error ->
            if c.source_queries + c.function_evaluations >= c.max,
              do: throw({:event_search_failed, :event_search_evaluation_budget_exhausted})

            Process.put(@key, Map.update!(c, counter, fn n when is_integer(n) -> n + 1 end))
            value = callback.()

            case value do
              {:error, reason} -> throw({:event_search_failed, reason})
              _ -> :ok
            end

            updated = current()
            Process.put(@key, Map.update!(updated, cache, &Map.put(&1, key, value)))
            value
        end
    end
  end
end
