defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.ImportReadiness.StatusRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common

  def gate_status(summary) do
    case quality_gate_status_row_ids_by_status(summary) do
      {:ok, ids_by_status} ->
        cond do
          length(Map.get(ids_by_status, "blocked", [])) > 0 ->
            "blocked"

          length(Map.get(ids_by_status, "analysis_only", [])) > 0 ->
            "analysis_only"

          length(Map.get(ids_by_status, "review_required", [])) > 0 ->
            "review_required"

          true ->
            nil
        end

      :missing ->
        cond do
          length(summary["blocked_quality_gate_row_ids"] || []) > 0 ->
            "blocked"

          length(summary["analysis_only_quality_gate_row_ids"] || []) > 0 ->
            "analysis_only"

          length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []) >
              0 ->
            "analysis_only"

          length(summary["review_required_quality_gate_row_ids"] || []) > 0 ->
            "review_required"

          true ->
            nil
        end
    end
  end

  def gate_reason("blocked"), do: "import readiness summary blocks import"

  def gate_reason("analysis_only"), do: "import readiness summary requires analysis"

  def gate_reason(_status), do: "import readiness summary requires review"

  def single_gate_id([id | _rest]) when id not in [nil, ""], do: id
  def single_gate_id(_ids), do: "cadence_import"

  def source_row(
        summary,
        review_required_quality_gate_row_ids,
        analysis_only_quality_gate_row_ids,
        blocked_quality_gate_row_ids,
        stale_or_unknown_freshness_quality_gate_row_ids,
        import_preparation_quality_gate_row_ids,
        blocked_import_quality_gate_row_ids
      ) do
    %{
      "gate_id" => single_gate_id(summary["import_readiness_gate_ids"]),
      "quality_gate_row_ids_by_status" => summary["quality_gate_row_ids_by_status"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "review_required_quality_gate_row_ids" => review_required_quality_gate_row_ids,
      "blocked_quality_gate_row_ids" => blocked_quality_gate_row_ids,
      "ready_quality_gate_row_ids" => summary["ready_quality_gate_row_ids"],
      "analysis_only_quality_gate_row_ids" => analysis_only_quality_gate_row_ids,
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        stale_or_unknown_freshness_quality_gate_row_ids,
      "import_preparation_quality_gate_row_ids" => import_preparation_quality_gate_row_ids,
      "blocked_import_quality_gate_row_ids" => blocked_import_quality_gate_row_ids,
      "import_readiness_gate_ids" => summary["import_readiness_gate_ids"]
    }
    |> Common.compact_map()
  end

  def quality_gate_status_row_ids(summary, status) do
    status = to_string(status)

    case quality_gate_status_row_ids_by_status(summary) do
      {:ok, ids_by_status} ->
        Map.get(ids_by_status, status, [])

      :missing ->
        summary
        |> Map.get(quality_gate_status_row_ids_field(status))
        |> import_readiness_string_ids()
    end
  end

  def quality_gate_status_scoped_row_ids(summary, field, statuses) do
    row_ids = import_readiness_string_ids(Map.get(summary, field))

    case quality_gate_status_row_ids_by_status(summary) do
      {:ok, ids_by_status} ->
        allowed_ids =
          statuses
          |> Enum.flat_map(&Map.get(ids_by_status, to_string(&1), []))
          |> MapSet.new()

        Enum.filter(row_ids, &MapSet.member?(allowed_ids, &1))

      :missing ->
        row_ids
    end
  end

  def summary_flag(summary, field, row_ids) do
    case quality_gate_status_row_ids_by_status(summary) do
      {:ok, _ids_by_status} -> length(row_ids) > 0
      :missing -> summary[field]
    end
  end

  defp quality_gate_status_row_ids_by_status(summary) do
    case Map.fetch(summary, "quality_gate_row_ids_by_status") do
      {:ok, %{} = ids_by_status} ->
        {:ok,
         ids_by_status
         |> Common.stringify_keys()
         |> Enum.map(fn {status, ids} -> {status, import_readiness_string_ids(ids)} end)
         |> Map.new()}

      _value ->
        :missing
    end
  end

  defp quality_gate_status_row_ids_field("analysis_only"),
    do: "analysis_only_quality_gate_row_ids"

  defp quality_gate_status_row_ids_field("blocked"), do: "blocked_quality_gate_row_ids"

  defp quality_gate_status_row_ids_field(_status),
    do: "review_required_quality_gate_row_ids"

  defp import_readiness_string_ids(values) do
    values
    |> List.wrap()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end
end
