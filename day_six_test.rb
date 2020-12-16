require 'minitest/autorun'

class String
  def &(other)
    (chars & other.chars).join
  end
end

def compute(string)
  string.split("\n\n").map { |group| group.delete("\n") }.sum { |group| group.chars.uniq.count }
end

def compute_part_two(string)
  string.split("\n\n").map { |group| group.split("\n") }.sum { |answers| answers.reduce(&:&).length }
end

class DaySixText < Minitest::Test
  def test_simple_example
    input = <<~input
      abc

      a
      b
      c

      ab
      ac

      a
      a
      a
      a

      b
    input

    assert_equal 11, compute(input)
  end

  def test_part_one
    assert_equal 6583, compute(input)
  end

  def test_part_two
    assert_equal 3290, compute_part_two(input)
  end

  def input
    File.read('day_six_input.txt')
  end
end
