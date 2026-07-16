defmodule OrbitalDynamics.Validation.ModelAcceptanceReport do
  @moduledoc false

  def build(models, opts, context)
      when is_list(models) and is_list(opts) and is_map(context) do
    intended_use =
      opts
      |> Keyword.get(:intended_use, "analysis")
      |> to_string()
      |> normalize_intended_use(context.intended_uses)

    rows =
      models
      |> Enum.with_index(1)
      |> Enum.map(fn {model, rank} ->
        model_acceptance_row(model, rank, intended_use, context)
      end)

    accepted_count = model_acceptance_status_count(rows, "accepted")
    review_required_count = model_acceptance_status_count(rows, "review_required")
    blocked_count = model_acceptance_status_count(rows, "blocked")
    unknown_model_count = Enum.count(rows, &(Map.get(&1, "validation_level") == "unknown"))

    status =
      cond do
        blocked_count > 0 -> "blocked"
        review_required_count > 0 -> "review_required"
        true -> "accepted_for_use"
      end

    model_ids =
      rows
      |> Enum.map(& &1["model_id"])
      |> Enum.reject(&is_nil/1)

    %{
      "schema_contract" => context.schema_contract,
      "schema_version" => 1,
      "model" => "registry_model_acceptance_classifier",
      "report_id" =>
        Keyword.get(opts, :report_id) || model_acceptance_report_id(intended_use, rows),
      "intended_use" => intended_use,
      "status" => status,
      "model_count" => length(rows),
      "accepted_count" => accepted_count,
      "review_required_count" => review_required_count,
      "blocked_count" => blocked_count,
      "unknown_model_count" => unknown_model_count,
      "status_counts" => model_acceptance_status_counts(rows),
      "validation_level_counts" => validation_level_counts(rows),
      "model_ids_by_status" => model_acceptance_model_ids_by(rows, "status"),
      "model_ids_by_validation_level" => model_acceptance_model_ids_by(rows, "validation_level"),
      "model_ids_by_intended_use" => %{intended_use => model_ids},
      "records" =>
        rows
        |> Enum.map(&Map.get(&1, "validation_record"))
        |> Enum.reject(&is_nil/1),
      "rows" => rows,
      "assumptions" => %{
        "intended_use" => intended_use,
        "accepted_validation_levels" => accepted_validation_levels(intended_use),
        "review_required_validation_levels" => review_required_validation_levels(intended_use),
        "blocked_validation_levels" => blocked_validation_levels(intended_use, context),
        "input_model_ids" => model_ids
      },
      "model_limits" => context.known_limits
    }
  end

  defp normalize_intended_use(intended_use, intended_uses) do
    if Enum.member?(intended_uses, intended_use), do: intended_use, else: "analysis"
  end

  defp model_acceptance_row(model, rank, intended_use, context) do
    case model_acceptance_record(model, context) do
      {:ok, record} ->
        record = stringify_keys(record)
        record = Map.put_new(record, "schema_contract", "validation_record.v1")
        validation_level = Map.get(record, "validation_level")
        status = model_acceptance_row_status(validation_level, intended_use)

        %{
          "id" => "model_acceptance:#{intended_use}:#{rank}:#{Map.get(record, "id")}",
          "rank" => rank,
          "model_id" => Map.get(record, "id"),
          "implementation" => Map.get(record, "implementation"),
          "validation_level" => validation_level,
          "status" => status,
          "reason" => model_acceptance_reason(validation_level, intended_use, status),
          "validation_record" => record
        }

      {:error, id} ->
        %{
          "id" => "model_acceptance:#{intended_use}:#{rank}:unknown",
          "rank" => rank,
          "model_id" => id,
          "validation_level" => "unknown",
          "status" => "blocked",
          "reason" => "model is not registered in OrbitalDynamics.Validation"
        }
    end
  end

  defp model_acceptance_record(%{} = record, _context) do
    record = stringify_keys(record)

    if Map.has_key?(record, "id") and Map.has_key?(record, "validation_level") do
      {:ok, record}
    else
      {:error, Map.get(record, "id") || "unknown"}
    end
  end

  defp model_acceptance_record(id_or_module, context) do
    case context.record.(id_or_module) do
      {:ok, record} -> {:ok, record}
      :error -> {:error, context.implementation_name.(id_or_module)}
    end
  end

  defp model_acceptance_row_status(validation_level, intended_use) do
    cond do
      validation_level in accepted_validation_levels(intended_use) -> "accepted"
      validation_level in review_required_validation_levels(intended_use) -> "review_required"
      true -> "blocked"
    end
  end

  defp accepted_validation_levels("demonstration"),
    do: ["educational", "analysis", "artifact_contract", "validated"]

  defp accepted_validation_levels("analysis"), do: ["analysis", "artifact_contract", "validated"]
  defp accepted_validation_levels("artifact_contract"), do: ["artifact_contract", "validated"]
  defp accepted_validation_levels("operational_import"), do: ["artifact_contract", "validated"]

  defp review_required_validation_levels("demonstration"), do: ["assumption_declared"]
  defp review_required_validation_levels("analysis"), do: ["educational"]
  defp review_required_validation_levels("artifact_contract"), do: ["analysis"]
  defp review_required_validation_levels("operational_import"), do: ["analysis"]

  defp blocked_validation_levels(intended_use, context) do
    declared_levels = context.tolerance_policy.()["validation_levels"] |> Map.keys()

    (declared_levels ++ ["unknown"])
    |> Enum.reject(&(&1 in accepted_validation_levels(intended_use)))
    |> Enum.reject(&(&1 in review_required_validation_levels(intended_use)))
    |> Enum.sort()
  end

  defp model_acceptance_reason(validation_level, intended_use, "accepted") do
    "#{validation_level} evidence is accepted for #{intended_use}"
  end

  defp model_acceptance_reason(validation_level, intended_use, "review_required") do
    "#{validation_level} evidence requires operator review for #{intended_use}"
  end

  defp model_acceptance_reason(validation_level, intended_use, "blocked") do
    "#{validation_level} evidence is not sufficient for #{intended_use}"
  end

  defp model_acceptance_status_count(rows, status),
    do: Enum.count(rows, &(Map.get(&1, "status") == status))

  defp model_acceptance_status_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "status", "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {status, count} -> {to_string(status), count} end)
  end

  defp validation_level_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "validation_level", "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {level, count} -> {to_string(level), count} end)
  end

  defp model_acceptance_model_ids_by(rows, field) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, field) || "unknown"),
      &Map.get(&1, "model_id")
    )
    |> Map.new(fn {value, model_ids} ->
      {to_string(value), Enum.reject(model_ids, &is_nil/1)}
    end)
  end

  defp model_acceptance_report_id(intended_use, rows) do
    model_part =
      rows
      |> Enum.map(&Map.get(&1, "model_id", "unknown"))
      |> Enum.map(&String.replace(to_string(&1), ~r/[^A-Za-z0-9._:@-]/, "_"))
      |> Enum.join("__")

    "model_acceptance:#{intended_use}:#{model_part}"
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
