require 'minitest/autorun'
require 'forwardable'
require 'active_support/all'

$LOAD_PATH << '.'
Dir.glob('*.rb') { |file| require file }
