defmodule Pineapple.Job do
  @moduledoc """
  Support for processes "Jobs" that can be used as the steps in a workflow.
  """
  alias Pineapple.{Core, Workflow}

  @type job_result ::
          {:ok, Workflow.t()}
          | {:done, any(), Workflow.t()}
          | {:error, any(), Workflow.t()}

  @callback run(Workflow.t()) :: job_result()
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
      import Pineapple.Workflow
    end
  end

  def resolve({:ok, workflow}) do
    Core.next(workflow)
  end

  def resolve({:done, result, workflow}) do
    Core.finish(result, workflow)
  end

  def resolve({:error, reason, workflow}) do
    Core.fail(reason, workflow)
  end
end
