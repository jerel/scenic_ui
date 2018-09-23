defmodule ScenicUI.Component.DragHandle do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  def cancel_move(pid) do
    GenServer.cast(pid, :cancel_move)
  end

  # --------------------------------------------------------
  def info(_data) do
    """
    #{IO.ANSI.red()}The first argument must be {id, width, height} where id is the id you wish to receive with events.
    #{IO.ANSI.yellow()}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  def verify({_width, _height} = size) do
    {:ok, size}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  def init({width, height}, opts) do
    graph =
      Graph.build()
      |> rect({width, height}, opts)
      |> push_graph()

    state = %{
      graph: graph,
      pressed: false
    }

    {:ok, state}
  end

  def handle_input({:cursor_button, {:left, :press, _, _}}, %{raw_input: {_, {:left, :press, _, {x, y}}}} = context, state) do
    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])
    send_event({:begin_move, {x, y}})
    {:noreply, %{state | pressed: true}}
  end

  def handle_input({:cursor_button, {:left, :release, _, _}}, %{raw_input: {_, {:left, :release, _, {x, y}}}} = context, state) do
    ViewPort.release_input(context, [:cursor_button, :cursor_pos])
    send_event({:end_move, {x, y}})
    {:noreply, %{state | pressed: false}}
  end

  def handle_input({:cursor_pos, _}, %{raw_input: {:cursor_pos, {x, y}}}, %{pressed: true} = state) do
    send_event({:move, {x, y}})
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  def handle_cast(:cancel_move, state) do
    send_event(:cancel_move)
    {:noreply, state}
  end
end
