require 'fileutils'
require 'rbconfig'
require 'pp'
require 'thread'
# require 'rbgsl'
# $script_folder = File.dirname(File.expand_path(__FILE__))
# require $script_folder + "/long_regexen.rb"
$is_main = __FILE__ == $0

if RUBY_VERSION.to_f < 1.9
	raise "Ruby version 1.9 or greater required (current version is #{RUBY_VERSION})"
end
# 
# def pe(*args, bndng)
# 	args.each do |arg| 
# 		puts arg, eval(arg, binding).inspect
# 	end
# end

class Object
	def set(v, *args)
		send(v+"=".to_sym, *args)
	end
	
	def self.find_all_methods_like(method)
		method = method === Regexp ? method : Regexp.new(method)
		return constants.inject({}) do |hash,ob| 
			ob = const_get(ob)
			begin
				hash[ob] = (ob.methods + ob.instance_methods).find_all{|meth| meth =~ method}
				hash.delete(ob) if hash[ob].size == 0
			rescue
			end
			hash
		end
	end


end

module Kernel
	def eputs(*args)
		#raise "here!"
		$stderr.puts(*args)
	end
	def ep(*args)
		#raise "here!"
		$stderr.puts(*(args.map{|a| a.inspect}))
	end
	def eprint(*args)
		$stderr.print(*args)
	end
	def self.change_environment_with_shell_script(string)
# 		system "echo $PATH
		env = `#{string}\necho "XXXXXXZZZZZZXXXXXXX029340923"\n env`.split("XXXXXXZZZZZZXXXXXXX029340923")[-1]
		new_env = {}
		env.scan(/^(?<var>[a-zA-Z_][a-zA-Z_0-9]*)=(?<val>.*)/) do
# 			p $~
			new_env[$~[:var]] = $~[:val]
		end
# 		p new_env.keys.size - ENV.keys.size
# 		(ENV.keys + new_env.keys).uniq.each do |key|
# 			p "----|#{key}", new_env[key], ENV[key] unless new_env[key] == ENV[key]
# 		end
		(new_env.keys - ["OLDPWD", "_", "mc", "SHLVL"]).each do |key|
			ENV[key] = new_env[key]
		end
# 		ep ENV['PATH']
		
# 		p env
# 		p ENV
# 		system "module list"
# 		exit
	end
	
	def forkex(string)
		fork{exec string}
	end
	
# 	def reraise(err)
# 		raise(err, err.to_s, err.backtrace)
# 	end
		
end

module ObjectSpace

	def self.log_state(file, &block)
		File.open(file, 'w') do |file|
			each_object do |obj|
				if block
					PP.pp(obj, file) if yield(obj)
				else
					PP.pp(obj, file)
				end
			end
		end
	end

end

class Symbol
	def +(other)
		if other.class == String
			self.to_s + other
		elsif other.class == Symbol
			(self.to_s+other.to_s).to_sym
		else
			raise NoMethodError
		end
	end

	def =~(other)
		return self.to_s =~ other
	end
	def sign
		@sign ||= 1
		@sign
	end
	def -@
	    @sign ||= 1
	    @sign *= -1
	    self
	end
end

class Class

# 	def new_class_method(method, &block)
# 		self.class.send(:define_method,method, &block)
# 	end

	def new_class_method(method, &block)
		define_singleton_method(method, &block)
	end

	
	def aliold(sym)
		(eputs "Warning: This method: #{:old_+sym} already exists"; return) if instance_methods.include?(:old_+sym)
		
		alias_method((:old_+sym),sym)
	end

	aliold(:class_variable_get)
	def class_variable_get(var, *args)
		var = var.to_s=~ /^@@/ ? var : "@@" + var.to_s
		old_class_variable_get(var, *args)
	end

	aliold(:class_variable_set)
	def class_variable_set(var,*args)
		var = var.to_s=~ /^@@/ ? var : "@@" + var.to_s
		old_class_variable_set(var, *args)
	end

	def class_accessor(*args)
		args.each do |variable|
			new_class_method(variable){class_variable_get(variable)}
			new_class_method(variable+"=".to_sym) do |value|
					class_variable_set(variable,value)
			end
		end
	end

	def add_a_child_class(class_name, class_definitions="")
		class_eval("class #{class_name} < #{self}; end")
		new_class = const_get(class_name)
		new_class.class_eval(class_definitions)	
		new_class
	end
	
	def recursive_const_get(string)
		string.split(/::/).inject(nil){|const, name| const ? const.const_get(name) : const_get(name)}
	end

	public :include, :attr_accessor


	def instance_method?(meth)
		return instance_methods.include?(meth.to_sym)
	end
end

class Object
	aliold(:instance_variable_set)
	def instance_variable_set(var,*args)
		var = var.to_s=~ /^@/ ? var : "@" + var.to_s
		old_instance_variable_set(var, *args)
	end
end

class String
	alias old_plus +
	def +(other)
		if other.class == Symbol
			old_plus(other.to_s)
		else
			old_plus(other)
		end
	end

	def to_bool
		if self == "true" or self == "T" or self == "TRUE"
			return true
		elsif self == "false" or self == "F" or self == "FALSE"
			return false
		else 
			raise ArgumentError.new("Attempt to convert string: (#{self}) to boolean failed")
		end
	end
	alias :to_b :to_bool

	def one_page_at_a_time
		rows, columns = Terminal.terminal_size
		i = 0
		array = self.split("\n")
# 		puts array.size; gets;
		loop do 
			j = 0
			while j < rows - 8
				line = array[i]
				puts line
				i+=1
				break if i == array.size
				j+=(line.size / columns).ceiling
#  				puts i,j; gets
			end
			break if i == array.size
			puts "\nPress Enter to continue reading"
			gets
			3.times{print "\033[1A\033[K"}
		end
	end

	def to_h
		hash = eval(self)
		raise ArgumentError.new("Couldn't convert #{self} to hash") unless hash.class == Hash
# 		puts hash; gets
		return hash	
	end

	def rewind(offset=0)
		#clears a string from the terminal output and rewinds to its beginning (as long as it was the last thing sent to standard out)
# 		puts offset; gets
		(true_lines-offset).times{print "\033[A\033[K"}
	end


	def true_lines
		return split("\n", -1).inject(0) do |j, line|
			j + (line.size / Terminal.terminal_size[1]).ceiling
		end
	end

	aliold	:to_f
	def to_f
		sub(/\.[eE]/, '.0e').old_to_f
	end

	def grep(pattern)
		split("\n").grep(pattern).join("\n")
	end
	
	def grep_line_numbers(pattern)
		ans = []
		split("\n").each_with_index do |line, index|
			ans.push index + 1 if line =~ pattern
		end
		ans
	end
	
	def print_coloured_lines(terminal_size = nil) # terminal_size = [rows, cols]
# 		raise CRFatal.new("terminal size must be given if this is called any where except inside a terminal (for example if you've called this as a subprocess)") unless terminal_size or $stdout.tty?
		terminal_size ||= Terminal.terminal_size
		#lots of gritty terminal jargon in here. Edit at your peril!
		lines = self.split($/)
		i = 0; j=0
		lines.each do |line|
			colour =  j%2==0 ? j%4==0 ? "\033[0;36m" : "\033[1;32m" : "\033[1;37m" 
			print colour
			print line.gsub(/\|/, "\033[1;37m" + '|' + colour) 
			print "\033[K\n"
	# 				puts (line.size / Terminal.terminal_size[1]).class
	# 				puts (line.size / Terminal.terminal_size[1])

			i+=(line.sub(/\w*$/, '').size / terminal_size[1]).ceiling
			j+=1
		end
		puts "\033[1;37m"
# 		print 'rewind size is', rewind

	end
	
	def universal_escape(name = nil)
		raise ArgumentError if name unless name =~ /^[A-Za-z0-9]*$/
		arr = []
		self.each_codepoint{|cp| arr.push cp}
		if name
			return "UEBZXQF#{name}UEB#{arr.join('d')}UEEZXQF#{name}UEE"
		else 
			return arr.join('d')
		end
	end
	def universal_escape1
		arr = []
		self.each_byte{|cp| arr.push cp}
		arr.join('d')
	end

	def universal_unescape(name = nil)
# 		p arrxy = self.split('d').map{
# 		strxy = ""
# 		arrxy.each{|codepointx| print codepointx.to_i.pretty_inspect, ' '; strxy << codepointx.to_i}
# 		return strxy
		if name
			return self.gsub(Regexp.new("UEBZXQF#{name}UEB([\\dd]+)UEEZXQF#{name}UEE")) do
				$1.universal_unescape
			end
		else
			raise TypeError.new("This string is not a simple escaped string: #{self}") unless self =~ /^[\dd]*$/	
			self.sub(/^UEB.*UEB/, '').sub(/UEE.*UEE$/, '').split('d').map{|cp| cp.to_i}.pack('U*')
		end
	end

	def fortran_true?
		self =~ /^(T|\.T\.|\.true\.|\.t\.)$/
	end

	def fortran_false?
		self =~ /^(F|\.F\.|\.false\.|\.f\.)$/
	end



	FORTRAN_BOOLS = [".true.", ".false.", "T", "F", ".t.", ".f.", ".T.", ".F."]
	
	def sign
		@sign ||= 1
		@sign
	end
	def -@
	    @sign ||= 1
	    @sign *= -1
	    self
	end
	def get_sign
		if self[0,1] == '-'
			@sign = -1
			self.sub!(/^\-/, '')
		end
		self
	end
	alias :old_compare :<=>

	def <=> other
		begin
			@sign ||= 1
			if @sign == 1 
				return self.old_compare other
			else
				return other.old_compare self
			end
		rescue RuntimeError
			return self.old_compare other
		end
	end
	
	def esc_regex
		Regexp.new(Regexp.escape(self))
	end
	
	def variable_to_class_name
		self.gsub(/(?:^|_)(\w)/){"#$1".capitalize}
	end
	
	def delete_substrings(*strings)
		new_string = self
		strings.each do |str|
			new_string = new_string.sub(Regexp.new_escaped(str), '')
		end
		new_string
	end
	alias :delsubstr :delete_substrings
end

class TrueClass
	def to_s
		return "true"
	end
end

class FalseClass
	def to_s
		return "false"
	end
end






class Hash
	def +(other)
		temp = {}
		raise TypeError unless other.class == Hash
		self.each do |key, value|
			raise "Non unique key set for Hash + Hash" unless other[key].class == NilClass
			temp[key] = value
		end
		other.each do |key, value|
			raise "Non unique key set for Hash + Hash" unless self[key].class == NilClass
			temp[key] = value
		end
		return temp
	end
	

	def random_value
		self[random_key]
	end

	def random_key
		keys.random
	end
		
	def random
		key = random_key
		return {key =>  self[key]}
	end
	def modify(hash, excludes=[])
		hash.each do |key, value|
# 			p key
			begin
				self[key] = value.dup unless excludes.include? key
			rescue TypeError #immediate values cannot be dup'd
				self[key] = value unless excludes.include? key
			end
		end
		self
	end
	alias :absorb :modify

	def expand_bools
		self[:true].each do |key|
			self[key] = true
		end
		self[:false].each do |key|
			self[key] = false
		end
		self
	end
end

class Array
	def random
		self[rand(size)]
	end

	def slice_with_stride(stride, offset, slice_size = 1)
		raise ArgumentError.new("slice_size cannot be bigger than stride - offset") if slice_size > stride - offset
		i = 0; new_arr = []
		loop do
			for j in 0...slice_size
				new_arr.push self[i + offset + j]
			end
			i += stride
			break if i >= size
		end
		return new_arr
	end

	def pieces(no_pieces)
		ans = []
		piece_sizes  = []

		for i in 0...no_pieces 
			ans.push []; piece_sizes[i] = 0
		end
		for j in 0...size 
			piece_sizes[j % no_pieces] += 1
		end
# 		p ans, piece_sizes
		accum = 0
		piece_sizes.each_with_index do |piece_size, piece|
			ans[piece] = self.slice(accum...accum + piece_size)
			accum += piece_size
		end
		return ans
	end

	def sum 
		return inject{|old, new| old + new}
	end
	def product
		return inject{|old, new| old * new}
	end
	
	def nuniq
		arr = dup
		i=0; 
		while i < arr.size
			j=i+1
			while j < arr.size 
# 				p arr[i], arr[j]
				arr.delete_at(j) if (arr[j].to_f <=> arr[i].to_f) == 0
				j+=1
			end
			i+=1
		end
		arr
	end
				

		
end




class Module
	def aliold(sym)
		alias_method((:old_+sym),sym)
	end
end

class Fixnum
	def ceiling
		return floor + 1
	end
end

module Terminal

	case Config::CONFIG['host']
	when /i386-apple-darwin/
		TIOCGWINSZ = 0x40087468 
		OTHER_TIOCGWINSZ = 0x5413
	else
		TIOCGWINSZ = 0x5413
		OTHER_TIOCGWINSZ = 0x40087468 
	end

	class TerminalError < StandardError
	end
	
	def self.terminal_size
		return [ENV['ROWS'].to_i, ENV['COLS'].to_i] if ENV['ROWS'] and ENV['COLS']
		raise TerminalError.new("Tried to determine terminal size but this process is not being run from within a terminal (may be a sub process or called within another script). Set ENV['ROWS'] ($ROWS in shell) and ENV['COLS'] ($COLS in shell) to avoid this warning") unless STDOUT.tty?
		system_code = TIOCGWINSZ
		begin
			rows, cols = 25, 80
			buf = [0, 0, 0, 0].pack("SSSS")
			if STDOUT.ioctl(system_code, buf) >= 0 then
				rows, cols, row_pixels, row_pixels, col_pixels =  
			buf.unpack("SSSS")[0..1]
			end
			return [rows, cols]
		rescue
			puts "Warning: TIOCGWINSZ switched in Terminal.terminal_size"
			system_code = OTHER_TIOCGWINSZ 	
		retry
		end
	end	
	
	def self.rewind(nlines)
		print "\033[#{nlines}A"
	end

	def self.erewind(nlines)
		eprint "\033[#{nlines}A"
	end

	
	def self.reset
		print "\033[0;00m"
	end
	
	def self.default_colour
		"\033[00m"
	end

	RESET = "\033[0;00m"
	CLEAR_LINE = "\033[K"
	CYAN = "\033[2;36m"
	LIGHT_GREEN= "\033[1;32m" 
	WHITE = "\033[1;37m"
	RED = "\033[1;31m"
	BACKGROUND_BLACK = "\033[40m"
end

class Regexp
	def verbatim
		self.inspect.sub(/\A\//,'').sub(/\/[mix]*\Z/,'')
	end
	def self.properly_nested(left_delim, right_delim, start_anywhere=true, ext = "")
		raise ArgumentError.new("Left and right delimiters (#{left_delim.inspect}, #{right_delim.inspect}) cannot be the same") if left_delim == right_delim
		
		nodelim = "(?<nodelim#{ext}>\\\\\\\\|\\\\\\#{left_delim}|\\\\\\#{right_delim}|[^#{left_delim}#{right_delim}\\\\]|\\\\[^#{left_delim}#{right_delim}\\\\])"
		
		new("#{start_anywhere ? "(?<before#{ext}>#{nodelim}*?)" : ""}(?<group#{ext}>\\#{left_delim}#{start_anywhere ? "\\g<nodelim#{ext}>" : nodelim}*?(?:\\g<group#{ext}>\\g<nodelim#{ext}>*?)*\\#{right_delim})")
	end
	def self.quoted_string
		/"(?:\\\\|\\"|[^"\\]|\\[^"\\])*"|'(?:\\\\|\\'|[^'\\]|\\[^'\\])*'/
	end
	def self.whole_string(regex)
		new("\\A#{regex.to_s}\\Z")
	end
	def self.new_escaped(*args)
		new(escape(*args))
	end
end

class FloatHash < Hash

       def self.from_hash(hash)
       	   fh = new
	   hash.each{|k,v| fh[k]=v}
           fh
	end

	aliold :inspect
	def inspect
	   "FloatHash.from_hash(#{old_inspect})"
        end
	aliold :pretty_inspect
	def pretty_inspect
	   "FloatHash.from_hash(#{old_pretty_inspect})"
        end
	
	def []=(key, var)
# 		super(key.to_f, var)
# 		raise TypeError unless key.kind 
		old_key = self.find{|k, v| (k-key.to_f).abs < Float::EPSILON}
		if old_key
			super(old_key[0].to_f, var)
		else 
			super(key.to_f, var)
		end
	end

	def [](key)
# # # 		super(key.to_f)
# 		raise TypeError unless key.class == Float 
		old_key = self.find{|k, v| (k-key.to_f).abs < Float::EPSILON}
		if old_key
			return super(old_key[0])
		else 
			return nil
		end
	end



# 	def to_s
# 		return self.inject(""){ |str, (key,val)|
# 			str+ sprintf("[%f, %s],", key, val.to_s)}.chop
# 	end
end

class String
    def to_f_wsp
	    self.sub(/^\s*\-\s*/, '-').to_f
    end
end

class Numeric
  def to_mathematica_format
      return "0.0" if self.to_f == 0.0
      l = Math.log10(self.to_f.abs).floor
      return "#{self.to_f / 10.0**(l.to_f)}*10^(#{l})"
  end
end

class Dir
	class << self
		aliold(:entries)
		def entries(dir=pwd,opts={})
			old_entries(dir,opts)
		end
	end
end

module Log

	@@log_file = 'log.txt'

	def self.log_file
		@@log_file
	end

	def self.log_file=(file)
		@@log_file=file
	end

	def self.clean_up
		return unless @@log_file
		File.delete @@log_file if FileTest.exist? @@log_file
	end

	def Log.log(*messages)
#		p 'wanting to log', @@log_file
		return nil unless @@log_file
# 		return
# 		return unless @@log_file
#		puts 'logging'
		messages.each do |message|
			File.open(@@log_file, 'a'){|file| file.puts message}
		end
	end

	def log(*messages)
		return nil unless @@log_file
		Log.log(*messages)
	end

	def Log.logf(func_name)
		log("Function: " + func_name + ": " + self.to_s)
	end

	def logf(func_name)
# 		p func_name
# 		p "Function: " + func_name.to_s + ": " + self.class.to_s
		message = "Function: " + func_name.to_s + ": " + self.class.to_s
# 		p message.class
		log(message)
	end
	
	def logfc(func_name)
# 		p func_name
# 		p "Function: " + func_name.to_s + ": " + self.class.to_s
		message = "Function: " + func_name.to_s + ": complete :" + self.class.to_s 
# 		p message.class
		log(message)
	end

	def Log.logi(*messages)
		return nil unless @@log_file
		messages.each do |message|
			File.open(@@log_file, 'a'){|file| file.puts message.inspect}
		end
	end

	def logi(*messages)
		return nil unless @@log_file
		messages.each do |message|
			File.open(@@log_file, 'a'){|file| file.puts message.inspect}
		end
	end

	def logt
		log("Traceback \n" + caller.join("\n"))
	end

	def Log.logt
		log("Traceback \n" + caller.join("\n"))
	end

	def logd
		log("Current Directory: " + Dir.pwd)
	end

end
			

class Dir
	
	def self.recursive_entries(dirct=Dir.pwd, hidden = false, toplevel=true)
		found = []
# 		ep Dir.pwd
# 		ep Dir.entries.find_all{|file| File.directory? file}
		chdir(dirct) do
# 			ep 'b'
			entries(dirct).each do |file|
# 				ep 'c'
				next if file =~ /^\./ and not hidden
				found.push file
# 				ep file
				next if [".", ".."].include? file
				if FileTest.directory?(file)
# 					ep file, Dir.pwd, File.expand_path(file)
					more = recursive_entries(File.expand_path(file), hidden, false)
					found = found + more
				end
			end
		end
		return toplevel ? found.map{|f| dirct + '/' + f} : found.map{|f| File.basename(dirct) + '/' + f}
	end
end
					
module FileUtils
	
# 	def self.tail(file_name, lines = 10, sep = $/)
# 		file = File.open(file_name, 'r')
# 		string = ""
# 		pos = -1
# 		n = 0
# 		size = file.stat.size
# # 		return string if size == 0
# 		while size > 0
# 			file.sysseek(pos, IO::SEEK_END)
# 			char = file.sysread(1)
# 			n+= 1 if char == sep  
# 			break if n == lines + 1
# 			string = char + string
# 			break if pos == - size 
# 			pos -= 1
# 		end
# 		file.close
# 		return string
# 	end

	def self.tail(file_name, lines = 10, sep = $/)
		if lines > 49 and sep == "\n" # The command line utility will be much faster
			begin
				return `tail -n #{lines} #{file_name}`  
			rescue => err #in case the command tail can't be found
# 				puts err
			end
		end
		file = File.open(file_name, 'r')
		string = ""
		pos = -1
		n = 0
		size = file.stat.size
		while size > 0
			file.sysseek(size + pos)
			char = file.sysread(1)
			n+= 1 if char == sep and not pos == -1  
			break if n == lines 
			string = char + string
			break if pos == - size 
			pos -= 1
		end
		file.close
		return string
	end

# 	def self.tail(file_name, lines = 10, sep = $/)
# 		file = File.open(file_name, 'r')
# 		string = ""
# 		pos = -1
# 		buffer_pos = 0
# 		n = 0
# 		size = file.stat.size
# # 		return string if size == 0
# 		buffer = ""
# # 		buffer_size = 0
# 		while size > 0
# 			if -pos > -buffer_pos
# 				incr = [size + buffer_pos, 1000].min
# 				buffer_pos -= incr
# 				file.sysseek(size + buffer_pos)
# 				buffer = file.sysread(incr) + buffer
# 			end
# 			char = buffer[pos, 1]
# 			n+= 1 if char == sep  
# 			break if n == lines + 1
# 			string = char + string
# 			break if pos == - size 
# 			pos -= 1
# 		end
# 		file.close
# 		return string
# 	end

end

class Class
	def phoenix(file_name, &block)
		if FileTest.exist? file_name
			obj = eval(File.read(file_name), binding, file_name)
			raise "Corrupt File: #{file_name}" unless obj.class == self
		else 
			obj = new
			obj.phoenix(file_name)
		end
		if block
			yield(obj)
			obj.phoenix(file_name)
		else	
			return obj
		end
	end
end

class Object
	def phoenix(file_name)
		File.open(file_name, 'w'){|file| file.puts "# coding: utf-8"; file.puts self.pretty_inspect}
	end
end
	

class Complex
# 	aliold :inspect
	def inspect
		return %[Complex(#{real},#{imag})]
	end
end

class Integer
	def to_sym
		to_s.to_sym
	end
end

module Math
	def self.heaviside(num)
		return 1.0 if num >= 0.0
		return 0.0
	end
end

module GoTo
STACK = []


	class Label
		attr_accessor :name;
		attr_accessor :block;
		
		def initialize(name, block);
			@name = name
			@block = block
		end

		def ==(sym)
			@name == sym
		end
	end

	class Goto < Exception;
		attr_accessor :label
		def initialize(label); @label = label; end
	end

	def label_goto(sym, &block)
		STACK.last << Label.new(sym, block)
	end

	def frame_start_goto
		STACK << []
	end

	def frame_end_goto
		frame = STACK.pop
		idx = 0

		begin
			for i in (idx...frame.size)
				frame[i].block.call if frame[i].block
			end
		rescue Goto => g
			idx = frame.index(g.label)
			retry
		end
	end

	def goto(label)
		raise Goto.new(label)
	end

end
	
if $is_main #testing and debugging
	class Trial
		class_accessor(:box)
		attr_accessor :sweet 

		def initialize
			@sweet = true
		end

		@@box = "chocs" 
		
	end

	class Other
		@@box = "to"
	end

	@bt = "hello"

	p ({:a => :b} + {:c => :d})
	puts Trial.class_variable_get(:box)
	puts Trial.box
	begin; puts Other.box; rescue; puts "That method should fail"; end 
# 	puts Other.top
	puts instance_variable_get("@bt")
	puts Object.find_all_methods_like("alias_method")
# 	puts Object.find_all_methods_like("singleton_method")

# 	puts Kernel.global_variables.inspect
# 	puts Kernel.class_variable_get("$is_main")

	@forks=[]
	FileUtils.makedirs("temp")
	5.times do |i| 
		@forks[i] = i.to_f
		puts @forks[i].object_id
		fork do
			100000.times{ @forks[i] *= 1.00001} 
			File.open("temp/#{i}.msl", 'w'){|file| file.puts Marshal.dump(@forks[i])}
		end
	
	end
# 	Thread.list.each{|thr| thr.join unless thr==Thread.main}
	Process.waitall
	5.times{ |i| @forks[i] = Marshal.load(File.read("temp/#{i}.msl"))}
	p @forks
	a = Trial.new
	puts Marshal.dump(a)
	a.define_singleton_method(:alone){puts "I am a singleton"}
	begin
		puts Marshal.dump(a)
	rescue 
		puts "You can't dump a singleton"
	end


	d = Trial.add_a_child_class("TrialChild", <<EOF

	def hello
		puts "hello i am a TrialChild"
	end

EOF
)


	ch = d.new
	ch.hello
	che = Trial::TrialChild.new
	che.hello
	puts che.sweet
	puts Trial.constants[0].class

	module TrialMod
		def TrialMod.append_features(the_class)
			puts the_class.box
			def the_class.bricks
				puts "Build a wall"
				@@box = "bricks"
			end
			@@wall = "long"
			the_class.class_accessor(:mortar, :wall, :elephant)
			the_class.mortar = "cement"
			the_class.elephant = "wall-smasher"
			super
		end

		

		def check_sweet
			@sweet = "bricks aren't sweet"
			puts @sweet
		end
	end

	Trial.include(TrialMod)

	Trial.bricks
	
	puts Trial.mortar
	puts Trial.wall
	puts Trial.elephant

	class DoubleJeopardy
		class_accessor(:box)
		@@box = "trunk"
	end

	DoubleJeopardy.include(TrialMod)
	puts DoubleJeopardy.elephant
	DoubleJeopardy.elephant = "big grey"
	puts Trial.elephant
	puts Trial.box

	a.check_sweet

	puts :NotStarted =~ /N/

	puts /a
		b/x.inspect.sub(/\A\//,'').sub(/\/[mix]\Z/,'')

	puts /(?: \/   #comment
		)/x.verbatim

	 
# 	require 'pp' 
	p Config::CONFIG['host'] 

	puts Terminal.terminal_size

	puts /(?<a>a)(?:\g<a>)/.match('aa')

	puts "1.e-02".to_f

	puts [].push(1).inspect

	puts Float::EPSILON

	puts "12.".to_f

	puts "abc\nefg".grep(/a/)

	begin
		raise '1'
	rescue
		begin
			raise '2'
		rescue 
			puts "well that worked!"
		end
	end
	hash = {:a => :b, :c => :d}
	puts hash.find{|key, value| value == :d}.class

	puts 0.23.class

	a = FloatHash.new

	a[0.123e06] = "right"
	a[0.12300001e06] = "wrong"
	puts a[0.1230000e06]
	a[0.231] = 0.789
	puts a.key(0.78900)
# 	pp Object.objects

 	pp Object.find_all_methods_like "objects"

	ObjectSpace.each_object do |obj|
# 		pp obj
	end

	puts ObjectSpace.class

	puts ch.inspect

	puts 1.class
	puts "12".to_i.class

	qfr = Trial.add_a_child_class("TrialBaby", "")
# 	qfr.box = "BigBigBox"
	puts Trial.box
	puts qfr.box

	class Vartest
# 		class_accessor :toy
		attr_accessor :marbles
		class Kid < Vartest
			class_accessor :toy
			@@toy = :balloon
		end
		class Kad < Vartest
			class_accessor :toy
			@@toy = :train
		end
		add_a_child_class("Boy", "class_accessor :toy; @@toy=:sword")
		add_a_child_class("Girl", "class_accessor :toy; @@toy=:boat")

		def initialize
			@marbles = [:blue, :red, :green]
		end
	
		def arrange_marbles(&block)
			yield(@marbles)
		end

		def squeak
			puts 'Squeak!'
		end

	end
# 	Vartest.toy = :doll

	puts Vartest::Kid.toy
	puts Vartest::Kad.toy
	puts Vartest::Boy.toy
	puts Vartest::Girl.toy

	puts hash.size
	puts hash[hash.keys[rand(hash.size)]]
	puts hash.random

	puts TrueClass.ancestors

	p "asb".scan(/(d)?(s)(b)/)

	p :gs2 =~ /\A[a-z_][a-z_\d]*\Z/ 

	while true
		puts "swimming is good"
		break if true
		puts "not!"
	end

	tim = Vartest.new
	
	puts tim.marbles

		

	tim.arrange_marbles do |marbles|
		marbles.sort!
		tim.squeak
		puts qfr.box
	end

	puts tim.marbles

	i = 0
	catch(:dd) do
		for i in 0..10
			throw(:dd) if i==2
		end
	end

	puts i

	puts (0...0).to_a.join(" ").inspect
	puts [:a, :b].slice(0...0).inspect

	puts tim.class.ancestors.inspect

	@mutex = Mutex.new

	t2 = Thread.new do
		i = 0; 
		loop do 
			@mutex.synchronize{i+=1;  puts "sleeping", i; sleep 0.2}; break if i==2;
		end
		sleep 0.1; puts "woken up"
	end
	
	for i in 1..3
		@mutex.synchronize do
			puts 'waiting for the lazy thread'
		end
		sleep rand(0) / 10.0
	end
	puts 'thread has woken up'

	t2.join

	hash = {z: :b, y: :a}
	p hash.sort{|(k1,v1), (k2, v2)| k1<=>k2}

	gs = GSL::Vector.alloc((0..10).to_a)
	puts gs.subvector(3, 5)
	g2 = GSL::Vector.alloc((1..11).to_a)
	m = GSL::Matrix.alloc(gs, g2)
	m.fprintf($stdout, "%e\t%e\t%e\t")
	m.transpose.to_a.each{|row| puts row.join("\t")}

	p [2,3,4,5,3].pieces(4)
end
