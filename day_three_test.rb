Point = Struct.new(:x, :y) do
  def +(other)
    self.class.new(x + other.x, y + other.y)
  end
end

class Route
  include Enumerable
  extend Forwardable
  def_delegators :@current_position, :x, :y

  def initialize(x_advance, y_advance, map)
    @current_position = Point.new(0, 0)
    @route_coordinates = Point.new(x_advance, y_advance)
    @map = map
  end

  def tree_count
    select(&:tree?).count
  end

  def next
    advance
    self
  end

  def tree?
    current_position_character == '#'
  end

  private

  def each
    yield self
    yield self.next while within?(@map.height)
  end

  def advance
    @current_position += @route_coordinates
  end

  def within?(height)
    @current_position.y < height - 1
  end

  def current_position_character
    @map.at(y, x % @map.width)
  end
end

class Map
  def initialize(map_string)
    @map_string = map_string
  end

  def height
    map.count
  end

  def width
    map.first.length
  end

  def at(y, x)
    map[y][x]
  end

  private

  def map
    @map_string.split("\n")
  end
end

class DayThreeTest < Minitest::Test
  def test_enumerating
    map = Map.new(<<~MAP)
      ..
      .#
      ..
      .#
    MAP

    route = Route.new(1, 1, map)

    assert_equal 2, route.tree_count
  end

  def test_complex_example
    map = Map.new(<<~MAP)
      ..##.......
      #...#...#..
      .#....#..#.
      ..#.#...#.#
      .#...##..#.
      ..#.##.....
      .#.#.#....#
      .#........#
      #.##...#...
      #...##....#
      .#..#...#.#
    MAP

    route = Route.new(3, 1, map)

    assert_equal 7, route.tree_count
  end

  def test_day_one
    input = File.read('day_three_input.txt')
    map = Map.new(input)
    route = Route.new(3, 1, map)
    assert_equal 223, route.tree_count
  end

  def test_day_one_part_two
    skip
    input = File.read('day_three_input.txt')
    map = Map.new(input)
    routes = [
      Route.new(1, 1, map),
      Route.new(3, 1, map),
      Route.new(5, 1, map),
      Route.new(7, 1, map),
      Route.new(1, 2, map)
    ]
    puts routes.map(&:tree_count).reduce(:*)
  end
end
