defmodule ScenicUI.Component.DraggableGroup do
  use Scenic.Component, has_children: true

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:group, 3}, {:update_opts, 2}]

  # --------------------------------------------------------
  def info(data) do
    """
    #{IO.ANSI.red()}#{__MODULE__} data must be a tuple of the graph itself and a list of valid uids of other elements in the graph.
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  def verify({%Graph{} = graph, builder}) when is_function(builder) do
    {:ok, {graph, builder}}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  def init({_graph, builder}, opts) do
    id = opts[:id] || make_ref()
    opts = Keyword.put(opts, :id, id)
    t = Map.get(opts[:styles], :t, {0, 0})

    graph =
      Graph.build()
      |> group(builder, opts)
      # this works around behavior that may be a bug
      |> Graph.modify(id, &update_opts(&1, t: t))
      |> push_graph()

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(opts[:viewport])

    state = %{
      graph: graph,
      id: id,
      vp_width: vp_width,
      vp_height: vp_height,
      origin: {0, 0},
      offset: {0, 0},
      t: t
    }

    {:ok, state}
  end

  # ============================================================================

  def filter_event(
        {:move, {pointer_x, pointer_y}},
        _context,
        %{graph: graph, id: id, offset: {x_offset, y_offset}, vp_width: vp_width, vp_height: vp_height} = state
      )
      when pointer_x > 0 and pointer_x < vp_width and pointer_y > 0 and pointer_y < vp_height do
    x = pointer_x - x_offset
    y = pointer_y - y_offset

    graph =
      graph
      |> Graph.modify(id, &update_opts(&1, t: {x, y}))
      |> push_graph()

    {:continue, {:move, id, {x, y}}, %{state | graph: graph, t: {x, y}}}
  end

  def filter_event({:move, _}, _context, state) do
    {:stop, state}
  end

  def filter_event({:begin_move, {pointer_x, pointer_y}}, _context, %{id: id, t: {group_x, group_y} = t} = state) do
    x_offset = pointer_x - group_x
    y_offset = pointer_y - group_y

    x = pointer_x - x_offset
    y = pointer_y - y_offset

    {:continue, {:begin_move, id, {x, y}}, %{state | offset: {x_offset, y_offset}, origin: t}}
  end

  def filter_event({:end_move, {pointer_x, pointer_y}}, _context, %{id: id, graph: graph, offset: {x_offset, y_offset}} = state) do
    x = pointer_x - x_offset
    y = pointer_y - y_offset

    {:continue, {:end_move, id, {x, y}}, %{state | graph: graph}}
  end

  def filter_event(:cancel_move, _context, %{id: id, graph: graph, origin: origin} = state) do
    graph =
      graph
      |> Graph.modify(id, &update_opts(&1, t: origin))
      |> push_graph()

    {:stop, %{state | graph: graph, t: origin}}
  end

  def filter_event(event, _context, state) do
    {:continue, event, state}
  end
end
