defmodule OrbitalDynamics.CandidateRefresh.EncodedValueTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  defmodule SampleStruct do
    defstruct [:status, :nested]
  end

  test "stringify_keys converts nested keys and scalar values" do
    value = %SampleStruct{
      status: :declared,
      nested: %{
        row_state: [:accepted, {:source, :report}],
        values: [%{contact_id: :primary_contact}]
      }
    }

    assert EncodedValue.stringify_keys(value) == %{
             "status" => "declared",
             "nested" => %{
               "row_state" => ["accepted", ["source", "report"]],
               "values" => [%{"contact_id" => "primary_contact"}]
             }
           }
  end

  test "stringify_keys_preserving_values only converts nested map keys" do
    value = %{
      status: :declared,
      nested: [%{row_state: :accepted}],
      tuple_value: {:source, :report}
    }

    assert EncodedValue.stringify_keys_preserving_values(value) == %{
             "status" => :declared,
             "nested" => [%{"row_state" => :accepted}],
             "tuple_value" => {:source, :report}
           }
  end

  test "stringify_keys_with_keyword_maps preserves list traversal semantics" do
    value = %{rows: [[contact_id: :primary_contact, state: [status: :accepted]]]}

    assert EncodedValue.stringify_keys_with_keyword_maps(value) == %{
             "rows" => [
               [
                 ["contact_id", "primary_contact"],
                 ["state", %{"status" => "accepted"}]
               ]
             ]
           }
  end
end
