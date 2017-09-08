require 'active_record'
require 'active_record/base'
require File.expand_path('../../lib/sengiri', __FILE__)
require File.expand_path('../../lib/sengiri/model/base', __FILE__)

require "sqlite3"
require 'pry-byebug'

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |c|
  c.include Helpers
end
