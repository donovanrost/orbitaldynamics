defmodule OrbitalDynamics.Timeline.LifecycleTransitionPolicy do
  @moduledoc false

  def build(
        _field,
        value,
        value,
        _status_lifecycle_category,
        _approval_lifecycle_category,
        _status_transition_review,
        _approval_transition_review,
        _compact_map
      ),
      do: nil

  def build(
        field,
        nil,
        to,
        status_lifecycle_category,
        approval_lifecycle_category,
        status_transition_review,
        approval_transition_review,
        compact_map
      ),
      do:
        %{"field" => field, "transition_type" => "added", "to" => to}
        |> Map.merge(
          transition_semantics(
            field,
            nil,
            to,
            status_lifecycle_category,
            approval_lifecycle_category,
            status_transition_review,
            approval_transition_review,
            compact_map
          )
        )

  def build(
        field,
        from,
        nil,
        status_lifecycle_category,
        approval_lifecycle_category,
        status_transition_review,
        approval_transition_review,
        compact_map
      ),
      do:
        %{"field" => field, "transition_type" => "removed", "from" => from}
        |> Map.merge(
          transition_semantics(
            field,
            from,
            nil,
            status_lifecycle_category,
            approval_lifecycle_category,
            status_transition_review,
            approval_transition_review,
            compact_map
          )
        )

  def build(
        field,
        from,
        to,
        status_lifecycle_category,
        approval_lifecycle_category,
        status_transition_review,
        approval_transition_review,
        compact_map
      ),
      do:
        %{"field" => field, "transition_type" => "changed", "from" => from, "to" => to}
        |> Map.merge(
          transition_semantics(
            field,
            from,
            to,
            status_lifecycle_category,
            approval_lifecycle_category,
            status_transition_review,
            approval_transition_review,
            compact_map
          )
        )

  defp transition_semantics(
         "status",
         from,
         to,
         status_lifecycle_category,
         _approval_lifecycle_category,
         status_transition_review,
         _approval_transition_review,
         compact_map
       ) do
    %{
      "from_category" => status_lifecycle_category.(from),
      "to_category" => status_lifecycle_category.(to)
    }
    |> Map.merge(status_transition_review.(from, to))
    |> compact_map.()
  end

  defp transition_semantics(
         "approval_status",
         from,
         to,
         _status_lifecycle_category,
         approval_lifecycle_category,
         _status_transition_review,
         approval_transition_review,
         compact_map
       ) do
    %{
      "from_category" => approval_lifecycle_category.(from),
      "to_category" => approval_lifecycle_category.(to)
    }
    |> Map.merge(approval_transition_review.(from, to))
    |> compact_map.()
  end

  defp transition_semantics(
         _field,
         _from,
         _to,
         _status_lifecycle_category,
         _approval_lifecycle_category,
         _status_transition_review,
         _approval_transition_review,
         _compact_map
       ),
       do: %{}
end
