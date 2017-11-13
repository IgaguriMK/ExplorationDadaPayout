require 'date'
require 'json'
require 'optparse'

ED_23_REREASE=DateTime.new(2017, 4, 17, 0 ,0, 0, 0.0)

def main

	options = {
		:journal_dir => home_dir =ENV["USERPROFILE"].gsub(/\\/, "/") + "/Saved Games/Frontier Developments/Elite Dangerous",
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

		opt.on('-e', '--end VALUE', 'End datetime.') { |v|
			begin
				options[:end] = DateTime.parse(v)
			rescue
				raise OptionParser::InvalidArgument, v
			end
		}

		opt.parse!(ARGV)
	end

	title = "Expliration Data Payout Estimate (#{options[:start].strftime("%Y-%m-%d %H:%M:%S")} - #{options[:end].strftime("%Y-%m-%d %H:%M:%S")})"

	puts "% #{title}"
	puts ""
	puts "| Name | Type | Mass | Payout |"
	puts "|:-----|:-----|-----:|-------:|"

	total = 0
	scans(options[:journal_dir], options[:start], options[:end]).collect do |s|
		payout = body_payout(s).floor
		puts "| %40s | %25s | %.2f | %6d |" % [
				s["BodyName"],
				s["StarType"] || s["PlanetClass"] || "Unknown",
				s["StellarMass"] || s["MassEM"] || 0,
				payout
			]
		total += payout
	end

	puts "| | | TOTAL | #{total.to_s.reverse.gsub( /(\d{3})(?=\d)/, '\1,').reverse} |"
end

def scans(journal_dir, start_date=ED_23_REREASE, end_date=DateTime.now)
	Dir.glob("#{journal_dir}/Journal*.log")
		.sort
		.flat_map { |log_path| IO.readlines(log_path) }
		.collect { |line| JSON.parse(line) }
		.select { |event| event["event"] == "Scan" }
		.select { |scan| DateTime.parse(scan["timestamp"]) >= start_date }
		.select { |scan| DateTime.parse(scan["timestamp"]) <= end_date }
end

WHITE_DWARF = ["D", "DA", "DAB", "DAO", "DAZ", "DAV", "DB", "DBZ", "DBV", "DO", "DOV", "DQ", "DC", "DCV", "DX"] 
NON_SEQUENCE = ["N", "H"]


def body_payout(scan)
	if scan["StarType"] then
		type = scan["StarType"] || "Unknown"
		mass = scan["StellarMass"] || 0

		return 0 if type == "SupermassiveBlackHole"

		return star_value(33737, mass) if WHITE_DWARF.include? type
		return star_value(54309, mass) if NON_SEQUENCE.include? type
		return star_value(2880, mass)

	elsif scan["PlanetClass"] then
		type = scan["PlanetClass"] || 0
		mass = scan["MassEM"] || 0


		bonus = 0
		if scan["TerraformState"] == "Terraformable" then
			bonus = planet_value(241607, mass) if type == "High metal content body"
			bonus = planet_value(279088, mass) if type == "Water world"
			bonus = planet_value(223971, mass)
		end

		return planet_value(52292, mass)          if type == "Metal rich body"
		return planet_value(23168, mass) + bonus  if type == "High metal content body"
		return planet_value(23168, mass)          if type == "Sudarsky class II gas giant"
		return planet_value(155581, mass) + planet_value(279088, mass) if type == "Earthlike body"
		return planet_value(155581, mass) + bonus if type == "Water world"
		return planet_value(232619, mass)         if type == "Ammonia world"
		return planet_value(3974, mass)           if type == "Sudarsky class I gas giant"
		return planet_value(720, mass) + bonus
	end

	0
end

def star_value(k, mass)
	k + (mass * k / 66.25)
end

def planet_value(k, mass)
	k + (0.5660377358490566 * k * mass ** 0.199977)
end

####

main if __FILE__ == $0
