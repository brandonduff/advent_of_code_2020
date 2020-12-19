class Machine
  attr_accessor :accumulator, :program_counter, :executed_instructions

  def initialize
    @accumulator = 0
    @program_counter = 0
  end

  def execute(instruction)
    instruction.execute(self)
    @program_counter += 1
  end

  def reset
    @accumulator = 0
    @program_counter = 0
    self
  end
end

class Program
  attr_reader :instructions

  def initialize(instructions)
    @instructions = instructions
    @executed_instructions = Set.new
  end

  def execute_on(machine)
    while machine.program_counter != @instructions.length
      next_instruction = @instructions[machine.program_counter]
      break if repeat_instruction?(next_instruction)

      machine.execute(next_instruction)
    end
  end

  def exited_normally?
    !@repeat_instruction
  end

  private

  def repeat_instruction?(instruction)
    @repeat_instruction = !@executed_instructions.add?(instruction)
  end
end

class Instruction
  attr_reader :argument

  def self.for(code, argument)
    descendants.detect(-> { raise 'bad input' }) { |descendant| descendant.name.downcase == code }.new(argument)
  end

  def initialize(argument)
    @argument = argument
  end
end

class Nop < Instruction
  def possibly_corrupt?
    true
  end

  def execute(_machine) end

  def to_opposite
    Jmp.new(@argument)
  end
end

class Acc < Instruction
  def possibly_corrupt?
    false
  end

  def execute(machine)
    machine.accumulator += @argument
  end
end

class Jmp < Instruction
  def possibly_corrupt?
    true
  end

  def execute(machine)
    machine.program_counter += @argument - 1
  end

  def to_opposite
    Nop.new(@argument)
  end
end

class String
  def words
    split(" ")
  end
end

class DayEightTest < Minitest::Test
  def setup
    @machine = Machine.new
  end

  def test_nop_instruction
    instruction = Instruction.for('nop', 0)
    @machine.execute(instruction)
    assert_equal 0, @machine.accumulator
    assert_equal 1, @machine.program_counter
  end

  def test_acc_instruction
    instruction = Acc.new(1)
    @machine.execute(instruction)
    assert_equal 1, @machine.accumulator
    assert_equal 1, @machine.program_counter
  end

  def test_jmp_instruction
    instruction = Jmp.new(2)
    @machine.execute(instruction)
    assert_equal 0, @machine.accumulator
    assert_equal 2, @machine.program_counter
  end

  def test_program_running_multiple_instructions
    program = Program.new([Acc.new(1)])
    program.execute_on(@machine)
    assert_equal 1, @machine.accumulator
  end

  def test_program_halts_before_executing_repeat_instruction
    instruction = Instruction.for('acc', 1)
    program = Program.new([instruction, instruction])
    program.execute_on(@machine)
    assert_equal 1, @machine.accumulator
  end

  def test_jumping_actually_jumps
    program = Program.new([Instruction.for('jmp', 2), Instruction.for('acc', 1), Instruction.for('acc', 2)])
    program.execute_on(@machine)
    assert_equal 2, @machine.accumulator
  end

  def test_program_can_report_exit_status
    good_program = Program.new([Instruction.for('acc', 1)])
    corrupt_program = Program.new([Instruction.for('jmp', 0)])

    good_program.execute_on(@machine)
    corrupt_program.execute_on(@machine.reset)

    assert good_program.exited_normally?
    refute corrupt_program.exited_normally?
  end

  def test_example
    input = <<~INPUT
      nop +0
      acc +1
      jmp +4
      acc +3
      jmp -3
      acc -99
      acc +1
      jmp -4
      acc +6
    INPUT

    instructions = input.lines.map(&:words).map { |instruction, argument| Instruction.for(instruction, argument.to_i) }
    program = Program.new(instructions)
    program.execute_on(@machine)
    assert_equal 5, @machine.accumulator
  end

  def test_part_one
    skip
    instructions = File.read('day_eight_input.txt').lines.map(&:words).map { |instruction, argument| Instruction.for(instruction, argument.to_i) }
    program = Program.new(instructions)
    program.execute_on(@machine)
    assert_equal 1446, @machine.accumulator
  end

  def test_part_two
    skip
    input_instructions.each_with_index do |instruction, index|
      next unless instruction.possibly_corrupt?
      input_instructions[index] = instruction.to_opposite

      candidate_program = Program.new(input_instructions)
      candidate_program.execute_on(@machine)
      break if candidate_program.exited_normally?

      input_instructions[index] = input_instructions[index].to_opposite
      @machine.reset
    end
    assert_equal 1403, @machine.accumulator
  end

  def input_instructions
    @input_instructions ||= File.read('day_eight_input.txt').lines.map(&:words).map { |instruction, argument| Instruction.for(instruction, argument.to_i) }
  end
end
