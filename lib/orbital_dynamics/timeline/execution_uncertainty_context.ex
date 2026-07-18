defmodule OrbitalDynamics.Timeline.ExecutionUncertaintyContext do
  @moduledoc false

  def build(activity, callbacks) when is_list(callbacks) do
    uncertainty = activity_execution_uncertainty(activity, callbacks)

    cond do
      is_map(uncertainty) ->
        uncertainty
        |> execution_uncertainty_fields(callbacks)
        |> Map.merge(%{
          "execution_uncertainty_status" => "declared",
          "execution_uncertainty" => uncertainty
        })
        |> compact_map(callbacks)

      execution_uncertainty_relevant?(activity) ->
        %{"execution_uncertainty_status" => "missing"}

      true ->
        %{}
    end
  end

  defp activity_execution_uncertainty(activity, callbacks) do
    uncertainty =
      Map.get(activity, "execution_uncertainty") ||
        Map.get(activity, "maneuver_execution_uncertainty") ||
        get_in(activity, ["metadata", "execution_uncertainty"]) ||
        get_in(activity, ["metadata", "maneuver_execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      %{} = uncertainty ->
        normalize_execution_uncertainty(stringify_keys(uncertainty, callbacks), callbacks)

      _value ->
        nil
    end
  end

  defp execution_uncertainty_relevant?(%{"type" => "impulsive_burn"}), do: true
  defp execution_uncertainty_relevant?(_activity), do: false

  defp normalize_execution_uncertainty(%{} = uncertainty, callbacks) do
    uncertainty
    |> normalize_uncertainty_number("timing_3sigma_s", callbacks)
    |> normalize_uncertainty_triplet("delta_v_3sigma_km_s", callbacks)
    |> normalize_uncertainty_number("delta_v_3sigma_magnitude_km_s", callbacks)
  end

  defp normalize_uncertainty_number(%{} = uncertainty, key, callbacks) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_value(value, callbacks) do
          nil -> uncertainty
          number -> Map.put(uncertainty, key, number)
        end

      :error ->
        uncertainty
    end
  end

  defp normalize_uncertainty_triplet(%{} = uncertainty, key, callbacks) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_triplet(value, callbacks) do
          nil -> uncertainty
          triplet -> Map.put(uncertainty, key, triplet)
        end

      :error ->
        uncertainty
    end
  end

  defp execution_uncertainty_fields(uncertainty, callbacks) do
    delta_v_3sigma_km_s =
      numeric_triplet(Map.get(uncertainty, "delta_v_3sigma_km_s"), callbacks)

    %{
      "timing_3sigma_s" => numeric_value(Map.get(uncertainty, "timing_3sigma_s"), callbacks),
      "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
      "delta_v_3sigma_magnitude_km_s" => vector_norm(delta_v_3sigma_km_s, callbacks),
      "execution_uncertainty_source" =>
        Map.get(uncertainty, "source") || Map.get(uncertainty, "model")
    }
    |> compact_map(callbacks)
  end

  defp stringify_keys(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stringify_keys), [value])

  defp numeric_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :numeric_value), [value])

  defp numeric_triplet(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :numeric_triplet), [value])

  defp vector_norm(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :vector_norm), [value])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
