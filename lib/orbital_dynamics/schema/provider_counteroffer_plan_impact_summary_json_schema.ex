defmodule OrbitalDynamics.Schema.ProviderCounterofferPlanImpactSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "counteroffer_count",
    "reviewable_count",
    "timing_shift_counteroffer_count",
    "counteroffer_cost_delta_count"
  ]

  @stable_id_array_fields [
    "affected_station_calendar_entry_ids",
    "affected_provider_entry_ids",
    "impact_counteroffer_ids",
    "timing_shift_counteroffer_ids",
    "cost_delta_counteroffer_ids"
  ]

  def property_opts(field, deps) when field in ["rows", "impact_rows"] do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("plan_impact_status", deps) do
    [plan_impact_statuses: fetch_dep!(deps, :plan_impact_statuses)]
  end

  def property_opts("counteroffer_lock_deadline_status_counts", deps) do
    [lock_deadline_statuses: fetch_dep!(deps, :lock_deadline_statuses)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or
             field == "counteroffer_ids_by_lock_deadline_status" do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in [
               "rows",
               "impact_rows",
               "model",
               "source_artifact_type",
               "source_counteroffer_artifact_type",
               "counteroffer_cost_delta_total",
               "plan_impact_status",
               "counteroffer_lock_deadline_status_counts",
               "counteroffer_ids_by_lock_deadline_status"
             ],
      do: true

  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property(field, opts) when field in ["rows", "impact_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_provider_counteroffer_plan_impact_summary"}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["provider_counteroffer_report.v1"]}
  end

  def property("source_counteroffer_artifact_type", _opts) do
    %{
      "type" => "string",
      "enum" => ["station_calendar_provider.v1", "station_calendar_report.v1"]
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("counteroffer_cost_delta_total", _opts) do
    %{"type" => "number"}
  end

  def property("plan_impact_status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :plan_impact_statuses)}
  end

  def property("counteroffer_lock_deadline_status_counts", opts) do
    opts
    |> Keyword.fetch!(:lock_deadline_statuses)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("counteroffer_ids_by_lock_deadline_status", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
