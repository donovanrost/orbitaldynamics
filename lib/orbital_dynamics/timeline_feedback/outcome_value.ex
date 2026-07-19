defmodule OrbitalDynamics.TimelineFeedback.OutcomeValue do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    ExecutionUncertainty,
    ProviderResult,
    SuccessFactor,
    Throughput
  }

  def contact_success(row, completion_statuses, failure_statuses)

  def contact_success(
        %{"feedback_kind" => "contact"} = row,
        completion_statuses,
        failure_statuses
      ) do
    realized_context_feedback_number(row, "contact_success_factor") ||
      boolean_success_value(row["contact_success"]) ||
      first_feedback_number(row, ["contact_success_factor"]) ||
      station_throughput(row) ||
      status_success_value(row, completion_statuses, failure_statuses)
  end

  def contact_success(_row, _completion_statuses, _failure_statuses), do: nil

  def station_throughput(%{"feedback_kind" => "contact"} = row) do
    feedback_number(row["throughput_completion_fraction"]) ||
      Throughput.derived_throughput_completion_fraction(row)
  end

  def station_throughput(_row), do: nil

  def observation_success(row, map_value_keys, completion_statuses, failure_statuses)

  def observation_success(
        %{"feedback_kind" => "observation"} = row,
        map_value_keys,
        completion_statuses,
        failure_statuses
      ) do
    realized_context_feedback_number(row, "observation_success_factor") ||
      provider_result_feedback_value(row["observation_result"], row, map_value_keys) ||
      first_feedback_number(row, ["observation_success_factor"]) ||
      realized_context_feedback_number(row, "image_quality_score") ||
      first_feedback_number(row, ["realized_image_quality_score"]) ||
      boolean_success_value(row["observation_success"]) ||
      status_success_value(row, completion_statuses, failure_statuses)
  end

  def observation_success(_row, _map_value_keys, _completion_statuses, _failure_statuses), do: nil

  def image_quality_score(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "image_quality_score") ||
      first_feedback_number(row, ["realized_image_quality_score", "image_quality_score"])
  end

  def image_quality_score(_row), do: nil

  def cloud_cover(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "cloud_cover_fraction") ||
      first_feedback_number(row, ["realized_cloud_cover_fraction", "cloud_cover_fraction"])
  end

  def cloud_cover(_row), do: nil

  def blur_score(%{"feedback_kind" => "observation"} = row) do
    realized_context_feedback_number(row, "blur_score") ||
      first_feedback_number(row, ["realized_blur_score", "blur_score"])
  end

  def blur_score(_row), do: nil

  def image_quality_status(%{"feedback_kind" => "observation"} = row) do
    first_feedback_string(row, [
      ["realized_activity_context", "image_quality_status"],
      "realized_image_quality_status",
      "image_quality_status"
    ])
  end

  def image_quality_status(_row), do: nil

  def image_quality_source(%{"feedback_kind" => "observation"} = row) do
    first_feedback_string(row, [
      ["realized_activity_context", "image_quality_source"],
      "image_quality_source"
    ])
  end

  def image_quality_source(_row), do: nil

  def maneuver_success(row, completion_statuses, failure_statuses)

  def maneuver_success(
        %{"feedback_kind" => "maneuver"} = row,
        completion_statuses,
        failure_statuses
      ) do
    realized_context_feedback_number(row, "maneuver_success_factor") ||
      boolean_success_value(row["maneuver_success"]) ||
      first_feedback_number(row, ["maneuver_success_factor"]) ||
      status_success_value(row, completion_statuses, failure_statuses)
  end

  def maneuver_success(_row, _completion_statuses, _failure_statuses), do: nil

  def command_success(row, completion_statuses, failure_statuses)

  def command_success(
        %{"feedback_kind" => kind} = row,
        completion_statuses,
        failure_statuses
      )
      when kind in ["command", "health_check"] do
    realized_context_feedback_number(row, "command_success_factor") ||
      boolean_success_value(row["command_success"]) ||
      first_feedback_number(row, ["command_success_factor"]) ||
      status_success_value(row, completion_statuses, failure_statuses)
  end

  def command_success(_row, _completion_statuses, _failure_statuses), do: nil

  def weighted_average(weighted_values) do
    {weighted_sum, total_weight} =
      Enum.reduce(weighted_values, {0.0, 0.0}, fn {value, weight}, {sum, total} ->
        {sum + value * weight, total + weight}
      end)

    weighted_sum / total_weight
  end

  def average_weight(%{"feedback_weight" => weight}) do
    case ExecutionUncertainty.numeric_value(weight) do
      weight when is_number(weight) and weight >= 0.0 -> weight * 1.0
      _weight -> 1.0
    end
  end

  def average_weight(_row), do: 1.0

  defp first_feedback_number(row, fields) do
    Enum.find_value(fields, fn field -> feedback_number(row[field]) end)
  end

  defp first_feedback_string(row, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> get_in(row, path)
          field -> Map.get(row, field)
        end

      case ArtifactValue.stringify_scalar(value) do
        value when is_binary(value) and value != "" -> value
        _value -> nil
      end
    end)
  end

  defp realized_context_feedback_number(row, field) do
    feedback_number(get_in(row, ["realized_activity_context", field]))
  end

  defp feedback_number(value), do: SuccessFactor.unit_interval_number_or_nil(value)

  defp boolean_success_value(true), do: 1.0
  defp boolean_success_value(false), do: 0.0
  defp boolean_success_value(_value), do: nil

  defp provider_result_feedback_value(nil, _row, _map_value_keys), do: nil

  defp provider_result_feedback_value(result, row, map_value_keys) do
    case ProviderResult.outcome(result, map_value_keys) do
      :failure -> 0.0
      :success -> completed_fraction_success_value(row, 1.0)
      :unknown -> nil
    end
  end

  defp status_success_value(
         %{"realized_status" => status} = row,
         completion_statuses,
         failure_statuses
       ) do
    cond do
      status in completion_statuses -> completed_fraction_success_value(row, 1.0)
      status == "partial" -> completed_fraction_success_value(row, 0.5)
      status == "delayed" -> 0.5
      status in failure_statuses -> 0.0
      true -> nil
    end
  end

  defp status_success_value(_row, _completion_statuses, _failure_statuses), do: nil

  defp completed_fraction_success_value(row, default) do
    case SuccessFactor.unit_interval_number_or_nil(row["completed_fraction"]) do
      value when is_number(value) -> value
      _value -> default
    end
  end
end
