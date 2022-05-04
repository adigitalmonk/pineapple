defmodule Pineapple.WorkflowTest do
  use ExUnit.Case
  alias Pineapple.Workflow
  doctest Pineapple.Workflow

  describe "creating a workflow" do
    test "has a unique reference" do
      assert Workflow.define([]).run_ref != Workflow.define([]).run_ref
    end
  end

  describe "assigns" do
    test "stores the data based on key/value pairs" do
      expected_data =
        :crypto.strong_rand_bytes(10)
        |> Base.encode64()

      workflow =
        []
        |> Workflow.define()
        |> Workflow.assign(:test_value, expected_data)

      assert workflow.assigns[:test_value] == expected_data
    end

    test "can assign using keyword list" do
      expected_data =
        :crypto.strong_rand_bytes(10)
        |> Base.encode64()

      workflow =
        []
        |> Workflow.define()
        |> Workflow.assign(
          test_value1: expected_data,
          test_value2: expected_data,
          test_value3: expected_data
        )

      assert workflow.assigns[:test_value1] == expected_data
      assert workflow.assigns[:test_value2] == expected_data
      assert workflow.assigns[:test_value3] == expected_data
    end

    test "can assign using a function" do
      expected_data =
        :crypto.strong_rand_bytes(10)
        |> Base.encode64()

      workflow =
        []
        |> Workflow.define()
        |> Workflow.assign(fn assigns ->
          Map.put(assigns, :test, expected_data)
        end)

      assert workflow.assigns[:test] == expected_data
    end
  end
end
