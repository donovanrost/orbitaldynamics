defmodule OrbitalDynamics.Schema.CampaignRepairJsonSchema do
  @moduledoc false

  def property("activities", opts) do
    array_of(Keyword.fetch!(opts, :planned_activity_schema))
  end

  def property("source_candidate_activities", opts) do
    array_of(Keyword.fetch!(opts, :candidate_activity_schema))
  end

  def property("deltas", opts) do
    array_of(Keyword.fetch!(opts, :plan_delta_schema))
  end

  def property("approval_requirements", opts) do
    array_of(Keyword.fetch!(opts, :approval_requirement_schema))
  end

  def property("timeline_transition_application_report", opts) do
    required_fields = Keyword.fetch!(opts, :required_fields)
    optional_fields = Keyword.fetch!(opts, :optional_fields)
    property_fun = Keyword.fetch!(opts, :property_fun)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" =>
        (required_fields ++ optional_fields)
        |> Enum.uniq()
        |> Enum.sort()
        |> Map.new(&{&1, property_fun.(&1)})
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end
end
