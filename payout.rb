require 'date'
require 'json'
require 'optparse'

ED_23_REREASE=DateTime.new(2017, 4, 17, 0 ,0, 0, 0.0)

def main

	options = {
		:journal_dir => "./Journals",
		:start => ED_23_REREASE,
		:end => DateTime.now
	}
	OptionParser.new do |opt|
		opt.on('-d', '--dir VALUE', 'Journal directory.') { |v|
			if v[-1] == '/' then
				options[:journal_dir] = v.chop
			else
				options[:journal_dir] = v
			end
		}

		opt.on('-s', '--start VALUE', 'Start datetime.') { |v|
			begin
				options[:start] = DateTime.parse(v)
			rescue
				raise OptionParser::InvalidArgument, v
			end
		}

		opt.parse!(ARGV)
	end

	p scans(options[:journal_dir], options[:start], options[:end])
end

def scans(journal_dir, start_date=ED_23_REREASE, end_date=DateTime.now)
	Dir.glob("#{journal_dir}/Journal*.log")
		.flat_map { |log_path| IO.readlines(log_path) }
		.collect { |line| JSON.parse(line) }
		.select { |event| event["event"] == "Scan" }
		.select { |scan| DateTime.parse(scan["timestamp"]) >= start_date }
		.select { |scan| DateTime.parse(scan["timestamp"]) <= end_date }
end

WHITE_DWARF = [D, DA, DAB, DAO, DAZ, DAV, DB, DBZ, DBV, DO, DOV, DQ, DC, DCV, DX] 

def body_payout(scan)
	
end

####

main if __FILE__ == $0
