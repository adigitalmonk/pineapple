defmodule Pineapple.Core do
  @moduledoc """
  Core logic for Pineapple functionality
  """
  alias Pineapple.{Job, Workflow}

  @doc """
  Run a given job and advance to the next step in the workflow when finished.
  """
  def process(workflow, module) do
    module
    |> apply(:run, [workflow])
    |> Job.resolve()
  end

  @doc """
  For a given workflow, run the next step.
  """
  def next(%Workflow{next: [{next, args} | rest]} = workflow) do
    workflow
    |> Map.put(:args, args)
    |> Map.put(:next, rest)
    |> Pineapple.continue(next)
  end

  def next(%Workflow{next: [next | rest]} = workflow) do
    workflow
    |> Map.put(:args, nil)
    |> Map.put(:next, rest)
    |> Pineapple.continue(next)
  end

  def next(%Workflow{next: []} = workflow) do
    finish(nil, workflow)
  end

  @doc """
  Handle the successful end state of the workflow.
  """
  def finish(result, %Workflow{target: target}) do
    send(target, {:finished, result})
  end

  def finish(_result, %Workflow{}) do
    # End abruptly
    :ok
  end

  require Logger

  @doc """
  Handle the failure scenario of a workflow.
  """
  def fail(reason, %Workflow{name: name, target: target}) do
    Logger.error(%{
      name: name,
      message: reason
    })

    if target do
      send(target, {:failure, reason})
    end
  end
end
