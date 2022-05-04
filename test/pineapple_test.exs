defmodule PineappleTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Pineapple.Workflow

  defmodule Jumper do
    use Pineapple.Job

    def run(%{args: arg} = workflow) when not is_nil(arg) do
      {:ok, assign(workflow, :wip, arg * 2)}
    end

    def run(%{assigns: assigns} = workflow) do
      {:done, assigns[:wip] * 2, workflow}
    end
  end

  defmodule Failure do
    use Pineapple.Job

    def run(%{args: arg} = workflow),
      do: {:error, arg, workflow}
  end

  defmodule Appender do
    use Pineapple.Job

    def run(%{args: arg} = workflow) do
      workflow = assign(workflow, &Map.update(&1, :count, 1, fn n -> n + 1 end))

      case arg do
        :step1 -> {:ok, add_step(workflow, {Appender, :step2})}
        :step2 -> {:ok, add_step(workflow, {Appender, :step3})}
        :step3 -> {:ok, add_step(workflow, Appender)}
        nil -> {:done, workflow.assigns[:count], workflow}
      end
    end
  end

  defmodule Forker do
    use Pineapple.Job

    def run(workflow) do
      outcomes =
        0..10
        |> Task.async_stream(fn n -> n end)
        |> Enum.map(fn {:ok, val} -> val end)

      {:ok, assign(workflow, :outcomes, outcomes)}
    end
  end

  defmodule Summer do
    use Pineapple.Job
    def run(%{assigns: %{outcomes: outcomes}} = workflow) do
      result = Enum.sum(outcomes)
      {:done, result, workflow}
    end
  end

  describe "Pineapple" do
    test "jobs can multiprocess with no issues" do
      [Forker, Summer]
      |> Workflow.define(target: self())
      |> Pineapple.begin()

      Process.sleep(100)
      assert_received {:finished, 55}
    end

    test "will run a simple workflow" do
      test_number = :rand.uniform(10_000)

      [{Jumper, test_number}, Jumper]
      |> Workflow.define(seed: test_number, target: self())
      |> Pineapple.begin()

      Process.sleep(100)
      expected_result = test_number * 4
      assert_received {:finished, ^expected_result}
    end

    test "errors get thrown through logger" do
      expected_error =
        :crypto.strong_rand_bytes(10)
        |> Base.encode64()

      assert capture_log(fn ->
               [{Failure, expected_error}]
               |> Workflow.define()
               |> Pineapple.begin()

               Process.sleep(100)
             end) =~ expected_error
    end

    test "errors get sent back to the caller if provided" do
      expected_error =
        :crypto.strong_rand_bytes(10)
        |> Base.encode64()

      capture_log(fn ->
        [{Failure, expected_error}]
        |> Workflow.define(target: self())
        |> Pineapple.begin()

        Process.sleep(100)
      end)

      assert_received {:failure, ^expected_error}
    end

    test "jobs can inject new steps into the workflow" do
      [{Appender, :step1}]
      |> Workflow.define(target: self())
      |> Pineapple.begin()

      Process.sleep(100)
      assert_received {:finished, 4}
    end
  end
end
