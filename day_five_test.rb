class String
  def lower_half?
    self == 'F' || self == 'L'
  end

  def upper_half?
    self == 'B' || self == 'R'
  end

  def row_identifier
    self[0..6]
  end

  def seat_identifier
    self[7..9]
  end
end

class BinarySpacePartition
  def initialize(string, range)
    @string = string
    @min = range.first
    @max = range.last
    @current_position = 0
  end

  def result
    advance until terminated?
    @max
  end

  def advance
    if current_character.lower_half?
      @max = @min + (@max - @min) / 2
    elsif current_character.upper_half?
      @min = (@min + @max + 1) / 2
    else
      raise 'bad input'
    end
    @current_position += 1
  end

  def terminated?
    @min == @max
  end

  def current_range
    @min..@max
  end

  private

  def current_character
    @string[@current_position]
  end
end

class AirplaneSeat
  def initialize(seat_string)
    @seat_string = seat_string
  end

  def seat_id
    row * 8 + column
  end

  def row
    BinarySpacePartition.new(@seat_string.row_identifier, 0..127).result
  end

  def column
    BinarySpacePartition.new(@seat_string.seat_identifier, 0..7).result
  end
end

class DayFiveTest < Minitest::Test
  def test_forward
    subject = BinarySpacePartition.new('F', 0..127)
    subject.advance
    assert_equal 0..63, subject.current_range
  end

  def test_backward
    subject = BinarySpacePartition.new('B', 0..127)
    subject.advance
    assert_equal 64..127, subject.current_range
  end

  def test_continuation
    subject = BinarySpacePartition.new('FF', 0..127)
    subject.advance
    subject.advance
    assert_equal 0..31, subject.current_range
  end

  def test_left_and_right
    subject = BinarySpacePartition.new('LRL', 0..7)
    assert_equal 2, subject.result
  end

  def test_bsp_termination
    subject = BinarySpacePartition.new('LRL', 0..7)
    refute subject.terminated?
    subject.advance
    refute subject.terminated?
    subject.advance
    subject.advance
    assert subject.terminated?
  end

  def test_airplane_seat_location
    subject = AirplaneSeat.new('FBFBBFFRLR')
    assert_equal 44, subject.row
    assert_equal 5, subject.column
    assert_equal 357, subject.seat_id
  end

  def test_another_example
    assert_equal 820, AirplaneSeat.new('BBFFBBFRLL').seat_id
  end

  def test_part_one
    result = seats.max_by { |seat| seat.seat_id }
    assert_equal 994, result.seat_id
  end

  def test_part_two
    seat_before = seats.map(&:seat_id).sort.each_cons(2).detect { |before, after| before + 1 == after - 1 }.first
    assert_equal 741, seat_before + 1
  end

  def seats
    File.read('day_five_input.txt').split.map { |string| AirplaneSeat.new(string) }
  end
end
