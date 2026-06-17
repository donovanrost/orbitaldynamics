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
end
