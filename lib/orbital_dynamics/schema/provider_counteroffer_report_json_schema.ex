defmodule OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "counteroffer_count",
    "reviewable_count",
    "counteroffer_cost_delta_count",
    "counteroffer_lock_deadline_count"
  ]

  @number_fields [
    "counteroffer_cost_delta_total",
    "earliest_counteroffer_lock_deadline_s"
  ]

  def models do
    [
      "artifact_only_provider_counteroffer_review",
      "preserved_provider_counteroffer_rows",
      "preserved_provider_counteroffer_plan_impact_summary",
      "preserved_provider_counteroffer_import_readiness_summary"
    ]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model", deps) do
    [models: fetch_dep!(deps, :models)]
  end

  def property_opts("counteroffer_negotiation_state_counts", deps) do
    [negotiation_states: fetch_dep!(deps, :negotiation_states)]
  end

  def property_opts("required_operator_action_counts", deps) do
    [operator_actions: fetch_dep!(deps, :operator_actions)]
  end

  def property_opts(_field, _deps), do: []

  def property_field?(field)
      when field in @count_fields or field in @number_fields or
             field in [
               "rows",
               "source_artifact_type",
               "model",
               "counteroffer_status_counts",
               "counteroffer_negotiation_state_counts",
               "required_operator_action_counts"
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

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("source_artifact_type", _opts) do
    %{
      "type" => "string",
      "enum" => ["station_calendar_provider.v1", "station_calendar_report.v1"]
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("counteroffer_status_counts", _opts) do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("counteroffer_negotiation_state_counts", opts) do
    opts
    |> Keyword.fetch!(:negotiation_states)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("required_operator_action_counts", opts) do
    opts
    |> Keyword.fetch!(:operator_actions)
    |> CommonJsonSchema.enum_count_map()
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
