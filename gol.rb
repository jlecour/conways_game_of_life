# encoding utf-8
require 'minitest/autorun'
require 'minitest/spec'

class DeadCell
  def alive?
    false
  end

  def mutate(alive_neighbors)
    if alive_neighbors == 3
      LiveCell.new
    else
      self
    end
  end
end

class LiveCell
  def alive?
    true
  end

  def mutate(alive_neighbors)
    if alive_neighbors == 2 || alive_neighbors == 3
     self
    else
      DeadCell.new
    end
  end
end

class Position

  attr_reader :x, :y

  def initialize(x, y)
    @x, @y = x, y
  end

  def eql?(other)
    self.x == other.x && self.y == other.y
  end
  alias :== :eql?

  private

  def hash
    [x, y].hash
  end

end

class Grid

  attr_reader :cells

  def initialize
    @cells = {}
  end

  def cell_at(position)
    # @cells.fetch(position, DeadCell.new)
    @cells[position] || DeadCell.new
  end

  def add_cell(position, cell = LiveCell.new)
    @cells[position] = cell
  end

  def live_cells_count
    @cells.size
  end

  def mutate_cell_at(position)
    cell = cell_at(position)
    count = live_neighbors_count_for(position)
    cell.mutate(count)
  end

  def live_neighbors_count_for(position)
    adjacent_positions_of(position).inject(0) { |count, neighbor_position|
      cell_at(neighbor_position).alive? ? count + 1 : count
    }
  end

  def positions
    cells.keys
  end

  private

  def adjacent_positions_of(position)
    (-1..1).map { |x|
      (-1..1).map { |y|
        unless x == 0 && y == 0
          new_x = position.x + x
          new_y = position.y + y
          Position.new(new_x, new_y)
        end
      }
    }.flatten.compact
  end
end

class Generation

  def initialize(grid)
    @grid = grid
  end

  def next_grid
    next_grid = Grid.new
    @grid.positions.each { |position, _|
      next_grid.add_cell(position, @grid.mutate_cell_at(position))
    }
    next_grid
  end

end


# TESTS


describe Generation do

  before do
    # -------
    # |•|•|•|
    # -------
    # | |•| |
    # -------
    # |•| |•|
    # -------

    @grid = Grid.new
    @grid.add_cell(Position.new(0,0), LiveCell.new)
    @grid.add_cell(Position.new(0,1), LiveCell.new)
    @grid.add_cell(Position.new(0,2), LiveCell.new)
    @grid.add_cell(Position.new(1,0), DeadCell.new)
    @grid.add_cell(Position.new(1,1), LiveCell.new)
    @grid.add_cell(Position.new(1,2), DeadCell.new)
    @grid.add_cell(Position.new(2,0), LiveCell.new)
    @grid.add_cell(Position.new(2,1), DeadCell.new)
    @grid.add_cell(Position.new(2,2), LiveCell.new)

  end

  it "returns a grid" do
    Generation.new(@grid).next_grid.must_be_instance_of Grid
  end

  it "returns a grid with correct mutations" do

    @grid.cell_at(Position.new(0,0)).alive?.must_equal true
    @grid.cell_at(Position.new(0,1)).alive?.must_equal true
    @grid.cell_at(Position.new(0,2)).alive?.must_equal true
    @grid.cell_at(Position.new(1,0)).alive?.must_equal false
    @grid.cell_at(Position.new(1,1)).alive?.must_equal true
    @grid.cell_at(Position.new(1,2)).alive?.must_equal false
    @grid.cell_at(Position.new(2,0)).alive?.must_equal true
    @grid.cell_at(Position.new(2,1)).alive?.must_equal false
    @grid.cell_at(Position.new(2,2)).alive?.must_equal true

    new_grid = Generation.new(@grid).next_grid

    # -------
    # |•|•|•|
    # -------
    # | | | |
    # -------
    # | |•| |
    # -------

    new_grid.cell_at(Position.new(0,0)).alive?.must_equal true
    new_grid.cell_at(Position.new(0,1)).alive?.must_equal true
    new_grid.cell_at(Position.new(0,2)).alive?.must_equal true
    new_grid.cell_at(Position.new(1,0)).alive?.must_equal false
    new_grid.cell_at(Position.new(1,1)).alive?.must_equal false
    new_grid.cell_at(Position.new(1,2)).alive?.must_equal false
    new_grid.cell_at(Position.new(2,0)).alive?.must_equal false
    new_grid.cell_at(Position.new(2,1)).alive?.must_equal true
    new_grid.cell_at(Position.new(2,2)).alive?.must_equal false

  end

end

describe Grid do

  before do
    @grid = Grid.new
  end

  it "should count alive cells" do
    @grid.live_cells_count.must_equal 0

    position = Position.new(0, 0)
    @grid.add_cell(position, LiveCell.new)

    @grid.live_cells_count.must_equal 1
  end

  it "should find the cell at a position" do
    cell = LiveCell.new

    @grid.add_cell(Position.new(0, 0), cell)

    @grid.cell_at(Position.new(0, 0)).must_equal cell
  end

  it "should return a dead cell on an empty position" do
    position = Position.new(0, 0)

    @grid.cell_at(position).alive?.must_equal false
  end

  it "should count live neighbors of a cell" do
    @grid.add_cell(Position.new(0, 0), LiveCell.new)
    @grid.add_cell(Position.new(1, 0), LiveCell.new)
    @grid.add_cell(Position.new(0, 1), LiveCell.new)

    @grid.live_neighbors_count_for(Position.new(0, 0)).must_equal 2
  end

  it "should return adjacent positions" do
    positions = @grid.send(:adjacent_positions_of, Position.new(0, 0))

    positions.must_include Position.new(1, 1)
    positions.must_include Position.new(1, 0)
    positions.must_include Position.new(1, -1)
    positions.must_include Position.new(0, 1)
    positions.must_include Position.new(0, -1)
    positions.must_include Position.new(-1, 1)
    positions.must_include Position.new(-1, 0)
    positions.must_include Position.new(-1, -1)

  end

  it "should mutate a cell" do
    @grid.add_cell(Position.new(0, 0), LiveCell.new)
    @grid.add_cell(Position.new(1, 0), LiveCell.new)
    @grid.add_cell(Position.new(0, 1), LiveCell.new)

    @grid.mutate_cell_at(Position.new(1, 1)).alive?.must_equal true

  end

end

describe Position do

  it "must have x and y coordinates" do
    assert_raises(ArgumentError) {
      Position.new
    }
    position = Position.new(1, 2)
    position.x.must_equal 1
    position.y.must_equal 2
  end

  it "should compare positions by coordinates" do
    Position.new(0,0).must_equal Position.new(0,0)
    Position.new(1,0).wont_equal Position.new(0,0)
    Position.new(0,1).wont_equal Position.new(0,0)
  end

end

describe LiveCell do

  before do
    @cell = LiveCell.new
  end

  it "should be alive" do
    @cell.alive?.must_equal true
  end

  it "should stay alive with 3 alive neighbors" do
    @cell.mutate(2).must_be_instance_of LiveCell
    @cell.mutate(3).must_be_instance_of LiveCell
  end

  it "should die with less than 2 alive neighbors" do
    @cell.mutate(0).must_be_instance_of DeadCell
    @cell.mutate(1).must_be_instance_of DeadCell
  end

  it "should die with more than 3 alive neighbors" do
    @cell.mutate(4).must_be_instance_of DeadCell
    @cell.mutate(10).must_be_instance_of DeadCell
  end

end

describe DeadCell do

  before do
    @cell = DeadCell.new
  end

  it "should not be alive" do
    @cell.alive?.must_equal false
  end

  it "should live with 3 alive neighbors" do
    @cell.mutate(3).must_be_instance_of LiveCell
  end

  it "should stay dead with less than 3 alive neighbors" do
    @cell.mutate(0).must_be_instance_of DeadCell
    @cell.mutate(1).must_be_instance_of DeadCell
    @cell.mutate(2).must_be_instance_of DeadCell
  end

  it "should stay dead with more than 3 alive neighbors" do
    @cell.mutate(4).must_be_instance_of DeadCell
    @cell.mutate(10).must_be_instance_of DeadCell
  end

end