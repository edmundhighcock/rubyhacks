require 'helper'

class TestRubyhacks < Test::Unit::TestCase
	def test_float_hash
		fh = FloatHash.new
		fh[0.4325] = 0.2342437
		fh[0.4232432] = 0.232443
		assert_equal(0.2342437, fh[0.433])
		assert_equal(0.2342437, fh[5.0])
		assert_raise(TypeError){fh['bb'] = 55}
	end
	def test_paginate
		File.read(__FILE__).paginate
	end
end
