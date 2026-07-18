defmodule OrbitalDynamics.Timeline.TransitionApplicationPolicy do
  @moduledoc false

  def selection("preserve_source", source, _replacement) when is_map(source) do
    %{
      "application_status" => "source_preserved_pending_review",
      "selected_activity_source" => "source",
      "selected_activity" => source
    }
    |> maybe_put_selected_provenance(source)
  end

  def selection("record", _source, replacement) when is_map(replacement) do
    %{
      "application_status" => "replacement_recorded",
      "selected_activity_source" => "replacement",
      "selected_activity" => replacement
    }
    |> maybe_put_selected_provenance(replacement)
  end

  def selection("none", source, _replacement) when is_map(source) do
    %{
      "application_status" => "source_unchanged",
      "selected_activity_source" => "source",
      "selected_activity" => source
    }
    |> maybe_put_selected_provenance(source)
  end

  def selection("none", _source, replacement) when is_map(replacement) do
    %{
      "application_status" => "replacement_unchanged",
      "selected_activity_source" => "replacement",
      "selected_activity" => replacement
    }
    |> maybe_put_selected_provenance(replacement)
  end

  def selection("none", _source, _replacement) do
    %{"application_status" => "no_activity"}
  end

  def selection("review", _source, _replacement) do
    %{"application_status" => "operator_review_required"}
  end

  def selection(_decision, _source, _replacement) do
    %{"application_status" => "operator_review_required"}
  end

  def put_provenance(activity, helper, field, transition, compact_map) do
    Map.put(
      activity,
      "transition_application_provenance",
      provenance(helper, field, transition, compact_map)
    )
  end

  defp provenance(helper, field, nil, _compact_map) do
    %{
      "helper" => helper,
      "field" => field,
      "transition_type" => "unchanged",
      "requires_operator_review" => false,
      "operator_action_reason" => no_change_reason(field)
    }
  end

  defp provenance(helper, field, transition, compact_map) when is_map(transition) do
    transition
    |> Map.take([
      "field",
      "transition_type",
      "from",
      "to",
      "transition_category",
      "requires_operator_review",
      "operator_action_reason"
    ])
    |> Map.put("helper", helper)
    |> Map.put_new("field", field)
    |> Map.put_new("requires_operator_review", false)
    |> compact_map.()
  end

  defp no_change_reason("approval_status"), do: "no_approval_status_change"
  defp no_change_reason(_field), do: "no_status_change"

  defp maybe_put_selected_provenance(application, selected_activity) do
    case Map.get(selected_activity, "transition_application_provenance") do
      %{} = provenance -> Map.put(application, "transition_application_provenance", provenance)
      _other -> application
    end
  end
end
