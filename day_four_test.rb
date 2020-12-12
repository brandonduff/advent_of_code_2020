require 'minitest/autorun'
require 'active_support/all'

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
    descendants.detect(->{ IgnoredField }) { |descendant| descendant.code == key }.new(value)
  end

  def self.required_keys
    descendants.excluding(IgnoredField).map(&:code)
  end

  def code
    self.class.code
  end

  def initialize(value)
    @value = value
  end
end

class IgnoredField < Field
  def self.code

  end

  def valid?
    true
  end
end

class IssueYear < Field
  def self.code
    'iyr'
  end

  def valid?
    @value.to_i.between?(2010, 2020)
  end
end

class BirthYear < Field
  def self.code
    'byr'
  end

  def valid?
    @value.to_i.between?(1920, 2002)
  end
end

class ExpirationYear < Field
  def self.code
    'eyr'
  end

  def valid?
    @value.to_i.between?(2020, 2030)
  end
end

class Height < Field
  def self.code
    'hgt'
  end

  def valid?
    @value.to_inches.between?(59, 76)
  end
end

class HairColor < Field
  def self.code
    'hcl'
  end

  def valid?
    @value =~ /\A#[0-9a-f]{6}\z/
  end
end

class EyeColor < Field
  def self.code
    'ecl'
  end

  def valid?
    @value.in?(%w(amb blu brn gry grn hzl oth))
  end
end

class PassportID < Field
  def self.code
    'pid'
  end

  def valid?
    @value =~ /\A\d{9}\Z/
  end
end

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
  def test_passport_validates_required_fields
    missing_fields = Passport.from_string('ecl:gry')
    valid_passport = Passport.from_string('ecl:gry pid:860033327 eyr:2020 hcl:#fffffd byr:1937 iyr:2017 cid:147 hgt:183cm')
    refute missing_fields.valid?
    assert valid_passport.valid?
  end

  def test_part_one
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
