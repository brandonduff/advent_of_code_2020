class String
  def sentences
    split('.').map(&:strip)
  end

  def clauses
    split(',')
  end
end

class BagEdge # Get it? Bag-edge, baggage
  attr_reader :parent, :child, :quantity

  def initialize(parent:, child:, quantity:)
    @parent = parent
    @child = child
    @quantity = quantity
  end
end

class Bag
  def initialize(color)
    @color = color
    @edges = []
  end

  attr_reader :color

  def to_s
    color
  end

  def ==(other)
    other.to_s == color
  end

  def add_child(bag, quantity)
    edge = BagEdge.new(child: bag, parent: self, quantity: quantity)
    @edges << edge
    bag.add_edge(edge)
  end

  def add_edge(edge)
    @edges << edge
  end

  def children
    child_edges.map(&:child)
  end

  def parents
    parent_edges.map(&:parent)
  end

  def ancestors
    parents + parents.flat_map(&:ancestors)
  end

  def parent_edges
    @edges.select { |edge| edge.child == self }
  end

  def child_edges
    @edges.select { |edge| edge.parent == self }
  end

  def containing_bag_count
    child_edges.sum do |edge|
      (edge.quantity + edge.quantity * edge.child.containing_bag_count)
    end
  end
end

class Rule
  def initialize(bags, string)
    @bags = bags
    @string = string
  end

  def evaluate
    container_bag_string, contained_bags_string = @string.to_s.split('bags contain').map(&:strip)
    container_bag = @bags.bag_for(container_bag_string)
    return [] if contained_bags_string == 'no other bags'

    add_contained_bags(container_bag, contained_bags_string)
  end

  def add_contained_bags(container_bag, clauses_string)
    clauses_string.clauses.map do |clause|
      quantity, color = /(\d|no) (.*) bag/.match(clause).captures
      container_bag.add_child(@bags.bag_for(color), quantity.to_i)
    end
  end
end

class Bags
  include Enumerable
  delegate :each, to: :@elements

  def initialize
    @elements = []
  end

  def add(bag)
    @elements << bag
  end

  def evaluate_rule(rule)
    Rule.new(self, rule).evaluate
  end

  def [](bag)
    detect { |element| element == bag }
  end

  def bag_for(color)
    if include?(color)
      self[color]
    else
      Bag.new(color).tap do |bag|
        add(bag)
      end
    end
  end
end

class DaySevenTest < Minitest::Test
  def test_string_sentences
    assert_equal ['Here is one sentence', 'And here is another'], 'Here is one sentence. And here is another.'.sentences
    assert_equal ['Here is one sentence', 'And here is another'], "Here is one sentence.\nAnd here is another.".sentences
  end

  def test_multiple_clause_rule_creation
    bags = Bags.new
    bags.evaluate_rule('dim red bags contain 2 dim salmon bags, 2 faded orange bags, 5 muted aqua bags')

    assert_includes bags['dim red'].children, 'dim salmon'
    assert_includes bags['dim red'].children, 'faded orange'
    assert_includes bags['dim red'].children, 'muted aqua'
  end

  def test_connecting_bags
    child_bag = Bag.new('shiny gold')
    parent_bag = Bag.new('dim red')
    parent_bag.add_child(child_bag, 3)
    assert_includes parent_bag.children, child_bag
    assert_includes child_bag.parents, parent_bag
  end

  def test_ancestors
    child_bag = Bag.new('shiny gold')
    parent_bag = Bag.new('dim red')
    grandparent_bag = Bag.new('old yellow')
    grandparent_bag.add_child(parent_bag, 4)
    parent_bag.add_child(child_bag, 5)
    assert_includes child_bag.ancestors, parent_bag
    assert_includes child_bag.ancestors, grandparent_bag
  end

  def test_no_other_bags
    bags = Bags.new
    bags.evaluate_rule('poop brown bags contain no other bags')
    assert_empty bags['poop brown'].children
    assert_empty bags['poop brown'].parents
  end

  def test_example
    input = 'light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.'

    bags = Bags.new
    gold_bag = Bag.new('shiny gold')
    bags.add(gold_bag)
    input.sentences.each do |rule|
      bags.evaluate_rule(rule)
    end

    assert_equal 4, gold_bag.ancestors.uniq.count
  end

  def test_containing_one_bag
    bags = Bags.new
    bags.evaluate_rule('light red bags contain 3 bright white bags')
    assert_equal 3, bags['light red'].containing_bag_count
  end

  def test_quantities
    input = 'light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.'
    bags = Bags.new
    input.sentences.each do |rule|
      bags.evaluate_rule(rule)
    end

    assert_equal 32, bags['shiny gold'].containing_bag_count
  end

  def test_part_one_and_two
    input = File.read('day_seven_input.txt').strip
    bags = Bags.new
    input.sentences.each do |rule|
      bags.evaluate_rule(rule)
    end

    gold_bag = bags['shiny gold']

    assert_equal 229, gold_bag.ancestors.uniq.count
    assert_equal 6683, gold_bag.containing_bag_count
  end
end
