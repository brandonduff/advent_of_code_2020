class Passport
  def self.from_string(string, field_level_validation: true)
    new(string.split.map(&:to_field), field_value_validation: field_level_validation)
  end

  attr_reader :fields

  def initialize(fields, field_value_validation:)
    @fields = fields
    @field_level_validation = field_value_validation
  end

  def valid?
    return false unless keys_valid?
    return false unless fields_valid? if perform_field_value_validation?

    true
  end

  private

  def fields_valid?
    fields.all?(&:valid?)
  end

  def perform_field_value_validation?
    @field_level_validation
  end

  def keys_valid?
    present_keys = fields.map(&:code)
    required_keys.all? { |key| key.in?(present_keys) }
  end

  def required_keys
    Field.required_keys
  end
end

class Field
  def self.for(key, value)
    descendants.detect(->{ self }) { |descendant| descendant.code == key }.new(value)
  end

  def self.required_keys
    descendants.map(&:code)
  end

  def self.code

  end

  def code
    self.class.code
  end

  def initialize(value)
    @value = value
  end

  def valid?
    true
  end
end

def validate_field(code, &block)
  new_field = Class.new(Field)
  new_field.define_singleton_method(:code) { code }
  new_field.define_method(:valid?) { instance_exec(@value, &block) }
end

validate_field('iyr') { |value| value.to_i.between?(2010, 2020) }
validate_field('byr') { |value| value.to_i.between?(1920, 2002) }
validate_field('eyr') { |value| value.to_i.between?(2020, 2030) }
validate_field('hgt') { |value| value.to_inches.between?(59, 76) }
validate_field('hcl') { |value| value =~ /\A#[0-9a-f]{6}\z/ }
validate_field('ecl') { |value| value.in?(%w(amb blu brn gry grn hzl oth)) }
validate_field('pid') { |value| value =~ /\A\d{9}\Z/ }

class String
  def to_inches
    if ends_with?('cm')
      (to_i / (150.to_f/59)).floor
    else
      to_i
    end
  end

  def to_field
    Field.for(*split(':'))
  end
end

class DayFourTest < Minitest::Test
  def setup
    skip
  end

  def test_passport_validates_required_fields
    missing_fields = Passport.from_string('ecl:gry')
    valid_passport = Passport.from_string('ecl:gry pid:860033327 eyr:2020 hcl:#fffffd byr:1937 iyr:2017 cid:147 hgt:183cm')
    refute missing_fields.valid?
    assert valid_passport.valid?
  end

  def test_part_one
    skip
    result = input.map { |fields_string| Passport.from_string(fields_string, field_level_validation: false) }.count(&:valid?)
    assert_equal 254, result
  end

  def test_birth_year_validation_on_passport
    valid_passport = Passport.from_string('byr:1972 ecl:gry pid:860033327 eyr:2020 hcl:#fffffd iyr:2017 cid:147 hgt:183cm')
    invalid_passport = Passport.from_string('byr:3000 ecl:gry pid:860033327 eyr:2020 hcl:#fffffd iyr:2017 cid:147 hgt:183cm')
    assert valid_passport.valid?
    refute invalid_passport.valid?
  end

  def test_issue_year_validation
    assert_within 'iyr', 2010, 2020
  end

  def test_expiration_year_validation
    assert_within 'eyr', 2020, 2030
  end

  def test_height
    assert Field.for('hgt', '150cm').valid?
    assert Field.for('hgt', '193cm').valid?

    refute Field.for('hgt', '149cm').valid?
    assert Field.for('hgt', '59in').valid?
  end

  def test_hair_color
    assert Field.for('hcl', '#3a91bc').valid?
    assert Field.for('hcl', '#000000').valid?
    refute Field.for('hcl', '#00000012').valid?
    refute Field.for('hcl', '3a91bc').valid?
    refute Field.for('hcl', '#wombat').valid?
    refute Field.for('hcl', '#abc').valid?
  end

  def test_eye_color
    assert Field.for('ecl', 'amb').valid?
    refute Field.for('ecl', 'xyz').valid?
  end

  def test_pid
    assert Field.for('pid', '012345678').valid?
    refute Field.for('pid', '123').valid?
    refute Field.for('pid', '123455678919').valid?
    refute Field.for('pid', 'abcdefghi').valid?
  end

  def test_examples
    skip
    passports = "eyr:1972 cid:100
hcl:#18171d ecl:amb hgt:170 pid:186cm iyr:2018 byr:1926

iyr:2019
hcl:#602927 eyr:1967 hgt:170cm
ecl:grn pid:012533040 byr:1946

hcl:dab227 iyr:2012
ecl:brn hgt:182cm pid:021572410 eyr:2020 byr:1992 cid:277

hgt:59cm ecl:zzz
eyr:2038 hcl:74454a iyr:2023
pid:3556412378 byr:2007

pid:087499704 hgt:74in ecl:grn iyr:2012 eyr:2030 byr:1980
hcl:#623a2f

eyr:2029 ecl:blu cid:129 byr:1989
iyr:2014 pid:896056539 hcl:#a97842 hgt:165cm

hcl:#888785
hgt:164cm byr:2001 iyr:2015 cid:88
pid:545766238 ecl:hzl
eyr:2022

iyr:2010 hgt:158cm hcl:#b6652a ecl:blu byr:1944 eyr:2021 pid:09315471".split("\n\n")
    assert passports.all? { |string| Passport.from_string(string) }
  end

  def test_part_two
    skip
    result = input.map { |fields_string| Passport.from_string(fields_string) }.count(&:valid?)
    assert_equal 184, result
  end

  def input
    File.read('day_four_input.txt').split("\n\n")
  end

  def assert_within(code, min, max)
    assert Field.for(code, min).valid?
    assert Field.for(code, max).valid?
    refute Field.for(code, min - 1).valid?
    refute Field.for(code, max + 1).valid?
  end
end
