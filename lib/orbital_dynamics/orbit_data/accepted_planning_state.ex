defmodule OrbitalDynamics.OrbitData.AcceptedPlanningState do
  @moduledoc false

  def build([], _opts), do: {:error, {:missing_field, "state_estimates"}}

  def build([_ | _] = estimates, opts) do
    with {:ok, snapshot_id} <- required_option(opts, :snapshot_id),
         {:ok, accepted_at} <- required_option(opts, :accepted_at),
         {:ok, source} <- source_map(Keyword.get(opts, :source), "source"),
         {:ok, quality} <- quality_map(Keyword.get(opts, :quality), "quality"),
         {:ok, provenance} <- optional_map(Keyword.get(opts, :provenance, %{}), "provenance"),
         {:ok, maneuver_execution_deltas} <-
           normalize_maneuver_execution_deltas(
             Keyword.get(opts, :maneuver_execution_deltas, []),
             provenance
           ),
         {:ok, spacecraft_states} <- state_estimates(estimates, provenance) do
      {:ok,
       %{
         "schema_version" => 1,
         "artifact_type" => "accepted_planning_state",
         "snapshot_id" => snapshot_id,
         "accepted_at" => accepted_at,
         "spacecraft_states" => spacecraft_states,
         "maneuver_execution_deltas" => maneuver_execution_deltas,
         "source" => source,
         "quality" => quality,
         "provenance" => provenance
       }}
    end
  end

  defp state_estimates(estimates, parent_provenance) do
    estimates
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {estimate, index}, {:ok, acc} ->
      case state_estimate(estimate, index, parent_provenance) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, states} -> {:ok, Enum.reverse(states)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp state_estimate(%{} = estimate, index, parent_provenance) do
    estimate = stringify_keys(estimate)
    path = "state_estimates[#{index}]"

    with {:ok, spacecraft_id} <- required_field(estimate, "spacecraft_id", path),
         {:ok, epoch} <- epoch(estimate, path),
         {:ok, frame} <- frame(estimate, path),
         {:ok, state_vector} <- state_vector(estimate, path),
         {:ok, source} <- source_map(Map.get(estimate, "source"), path <> ".source"),
         {:ok, quality} <- state_quality(estimate, path) do
      {:ok,
       %{
         "spacecraft_id" => spacecraft_id,
         "scenario_id" => encode_identifier(Map.get(estimate, "scenario_id", spacecraft_id)),
         "epoch" => epoch,
         "frame" => frame,
         "state_vector" => state_vector,
         "source" => source,
         "quality" => quality
       }
       |> maybe_put("dry_mass_kg", Map.get(estimate, "dry_mass_kg"))
       |> maybe_put("propellant_mass_kg", Map.get(estimate, "propellant_mass_kg"))
       |> maybe_put("trust_boundary", Map.get(estimate, "trust_boundary"))
       |> maybe_put(
         "provenance",
         Map.get(estimate, "provenance") || inherited_state_estimate_provenance(parent_provenance)
       )
       |> maybe_put("metadata", Map.get(estimate, "metadata"))}
    end
  end

  defp state_estimate(_estimate, index, _parent_provenance),
    do: {:error, {:invalid_field, "state_estimates[#{index}]"}}

  defp inherited_state_estimate_provenance(
         %{"trust_boundary" => trust_boundary} = parent_provenance
       )
       when is_binary(trust_boundary) and trust_boundary != "" do
    parent_provenance
    |> Map.take([
      "input_format",
      "import_adapter",
      "adapter",
      "adapter_version",
      "provider",
      "network_access",
      "trust_boundary"
    ])
    |> Map.put_new("source", "accepted_planning_state.provenance")
  end

  defp inherited_state_estimate_provenance(_parent_provenance), do: nil

  defp epoch(%{"epoch" => %{} = epoch}, path) do
    epoch = stringify_keys(epoch)

    with {:ok, seconds_since_j2000} <-
           number_field(epoch, "seconds_since_j2000", path <> ".epoch"),
         {:ok, time_scale} <- time_scale(epoch, path <> ".epoch") do
      {:ok, %{"seconds_since_j2000" => seconds_since_j2000, "time_scale" => time_scale}}
    end
  end

  defp epoch(%{"seconds_since_j2000" => _value} = estimate, path) do
    with {:ok, seconds_since_j2000} <- number_field(estimate, "seconds_since_j2000", path),
         {:ok, time_scale} <- time_scale(estimate, path) do
      {:ok, %{"seconds_since_j2000" => seconds_since_j2000, "time_scale" => time_scale}}
    end
  end

  defp epoch(_estimate, path), do: {:error, {:missing_field, path <> ".epoch"}}

  defp time_scale(source, _path) do
    case Map.get(source, "time_scale", Map.get(source, "scale", "tdb")) do
      scale when scale in ["tdb", "tai", "utc"] -> {:ok, scale}
      scale when scale in [:tdb, :tai, :utc] -> {:ok, Atom.to_string(scale)}
      _scale -> {:error, {:invalid_field, "time_scale"}}
    end
  end

  defp frame(estimate, path) do
    case Map.get(estimate, "frame", "earth_inertial_j2000") do
      frame when frame in ["earth_inertial_j2000", :earth_inertial_j2000] ->
        {:ok, "earth_inertial_j2000"}

      _frame ->
        {:error, {:invalid_field, path <> ".frame"}}
    end
  end

  defp state_vector(%{"state_vector" => %{} = vector}, path) do
    vector
    |> stringify_keys()
    |> state_vector_fields(path <> ".state_vector")
  end

  defp state_vector(estimate, path), do: state_vector_fields(estimate, path)

  defp state_vector_fields(source, path) do
    with {:ok, position_km} <- vector_field(source, "position_km", path),
         {:ok, velocity_km_s} <- vector_field(source, "velocity_km_s", path) do
      {:ok, %{"position_km" => position_km, "velocity_km_s" => velocity_km_s}}
    end
  end

  defp state_quality(estimate, path) do
    quality = stringify_keys(Map.get(estimate, "quality", %{"level" => "accepted"}))

    quality =
      quality
      |> maybe_put("position_sigma_km", Map.get(estimate, "position_sigma_km"))
      |> maybe_put("velocity_sigma_km_s", Map.get(estimate, "velocity_sigma_km_s"))
      |> maybe_put("covariance", Map.get(estimate, "covariance"))

    quality_map(quality, path <> ".quality")
  end

  def normalize_maneuver_execution_deltas(deltas, parent_provenance)
      when is_list(deltas) do
    deltas
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {delta, index}, {:ok, acc} ->
      case maneuver_execution_delta(delta, index, parent_provenance) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, reason} -> {:error, reason}
    end
  end

  def normalize_maneuver_execution_deltas(_deltas, _parent_provenance),
    do: {:error, {:invalid_field, "maneuver_execution_deltas"}}

  defp maneuver_execution_delta(%{} = delta, index, parent_provenance) do
    delta = stringify_keys(delta)
    path = "maneuver_execution_deltas[#{index}]"

    with {:ok, activity_id} <- required_field(delta, "activity_id", path),
         {:ok, status} <- required_field(delta, "status", path),
         {:ok, source} <- source_map(Map.get(delta, "source"), path <> ".source"),
         {:ok, quality} <- quality_map(Map.get(delta, "quality"), path <> ".quality") do
      {:ok,
       %{
         "activity_id" => activity_id,
         "status" => status,
         "source" => source,
         "quality" => quality
       }
       |> maybe_put("epoch_s", Map.get(delta, "epoch_s"))
       |> maybe_put("actual_epoch", Map.get(delta, "actual_epoch"))
       |> maybe_put("delta_v_km_s", Map.get(delta, "delta_v_km_s"))
       |> maybe_put("trust_boundary", Map.get(delta, "trust_boundary"))
       |> maybe_put(
         "provenance",
         Map.get(delta, "provenance") || inherited_delta_provenance(parent_provenance)
       )
       |> maybe_put("notes", Map.get(delta, "notes"))
       |> maybe_put("metadata", Map.get(delta, "metadata"))}
    end
  end

  defp maneuver_execution_delta(_delta, index, _parent_provenance),
    do: {:error, {:invalid_field, "maneuver_execution_deltas[#{index}]"}}

  defp inherited_delta_provenance(%{"trust_boundary" => trust_boundary} = parent_provenance)
       when is_binary(trust_boundary) and trust_boundary != "" do
    parent_provenance
    |> Map.take([
      "input_format",
      "import_adapter",
      "adapter",
      "adapter_version",
      "provider",
      "network_access",
      "trust_boundary"
    ])
    |> Map.put_new("source", "accepted_planning_state.provenance")
  end

  defp inherited_delta_provenance(_parent_provenance), do: nil

  defp required_option(opts, key) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      value when is_atom(value) -> {:ok, Atom.to_string(value)}
      _value -> {:error, {:missing_field, Atom.to_string(key)}}
    end
  end

  defp required_field(source, key, path) do
    case Map.get(source, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      value when is_atom(value) -> {:ok, Atom.to_string(value)}
      _value -> {:error, {:missing_field, path <> "." <> key}}
    end
  end

  defp number_field(source, key, path) do
    case Map.get(source, key) do
      value when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      _value -> {:error, {:invalid_field, path <> "." <> key}}
    end
  end

  defp vector_field(source, key, path) do
    case Map.get(source, key) do
      [x, y, z] when is_number(x) and is_number(y) and is_number(z) ->
        {:ok, [x * 1.0, y * 1.0, z * 1.0]}

      _value ->
        {:error, {:invalid_field, path <> "." <> key}}
    end
  end

  defp source_map(%{} = source, _path), do: {:ok, stringify_keys(source)}
  defp source_map(nil, path), do: {:error, {:missing_field, path}}
  defp source_map(_source, path), do: {:error, {:invalid_field, path}}

  defp quality_map(%{} = quality, path) do
    quality = stringify_keys(quality)

    case Map.get(quality, "level") do
      level when is_binary(level) and level != "" -> {:ok, quality}
      level when is_atom(level) -> {:ok, Map.put(quality, "level", Atom.to_string(level))}
      _level -> {:error, {:missing_field, path <> ".level"}}
    end
  end

  defp quality_map(nil, path), do: {:error, {:missing_field, path}}
  defp quality_map(_quality, path), do: {:error, {:invalid_field, path}}

  defp optional_map(%{} = value, _path), do: {:ok, stringify_keys(value)}
  defp optional_map(nil, _path), do: {:ok, %{}}
  defp optional_map(_value, path), do: {:error, {:invalid_field, path}}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, stringify_keys(value))

  defp encode_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_identifier(value), do: value

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_identifier(key), stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value
end
