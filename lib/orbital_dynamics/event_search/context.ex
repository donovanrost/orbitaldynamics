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
      functions: %{},
      identities: %{states: [], functions: []}
    })
  end

  def restore(nil), do: Process.delete(@key)
  def restore(context), do: Process.put(@key, context)

  def observations(f, source) do
    context = current()

    # Auditing historically includes numerically equal coverage bounds, even
    # when integer/float representations occupy different exact cache entries.
    function_ids = matching_identities(context.identities.functions, {f.id, f.evaluate})
    source_ids = matching_identities(context.identities.states, source_identity(source))

    values =
      for {{id, token, state}, result} <- context.functions,
          id == f.id and token in function_ids do
        case result do
          {:ok, value, _, _} ->
            %{t: state.epoch.seconds_since_j2000, status: :known, value: value}

          _ ->
            %{t: state.epoch.seconds_since_j2000, status: :unknown}
        end
      end

    missing =
      for {{token, t}, result} <- context.states,
          token in source_ids,
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

  def state(source, t, callback),
    do: memo(:states, :source_queries, source_identity(source), t * 1.0, callback)

  def function(f, state, callback),
    do: memo(:functions, :function_evaluations, {f.id, f.evaluate}, {f.id, state}, callback)

  # Keep the original identity rules, but do not hash callback environments on
  # every query. Closures may capture an entire constellation's integration
  # anchors. The small per-search registry uses exact equality, not a hash/digest
  # that could collide or confuse callbacks produced by the same closure factory.
  defp source_identity(source),
    do: {source.sampler, source.start, source.stop, source.frame}

  defp find_identity(entries, identity) do
    Enum.find_value(entries, fn {original, token} ->
      if original === identity, do: token
    end)
  end

  defp matching_identities(entries, identity),
    do: for({original, token} <- entries, original == identity, do: token)

  defp intern(context, cache, identity) do
    entries = context.identities[cache]

    case find_identity(entries, identity) do
      nil ->
        token = length(entries) + 1
        {token, put_in(context, [:identities, cache], [{identity, token} | entries])}

      token ->
        {token, context}
    end
  end

  defp memo(cache, counter, identity, query, callback) do
    case current() do
      nil ->
        callback.()

      c ->
        {token, c} = intern(c, cache, identity)

        key =
          case cache do
            :states ->
              {token, query}

            :functions ->
              {id, state} = query
              {id, token, state}
          end

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
