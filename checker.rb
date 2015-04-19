require 'watir-webdriver'

class TestStep
	attr_accessor :points, :stop_on_fail, :validation_block, :description
	attr_accessor :browser_instance
	
	def initialize(description, points, stop_on_fail, browser_instance = 0, &validation_block)
		self.points = points
		self.stop_on_fail = stop_on_fail
		self.validation_block = validation_block
		self.description = description
		self.browser_instance = browser_instance
	end
	
	def run(browser)
		begin 
			@result = validation_block.call(browser)
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			@result = false
		end
		
		@result
	end
	
	def result
		@result
	end
	
	def to_s
		"#{description} \t[#{points}] #{stop_on_fail ? "Mandatory": ""}"
	end
end

class Test
	attr_accessor :name, :description, :steps
	attr_accessor :browser_instances
	def initialize(name, description)
		self.name = name
		self.description = description
		self.steps = []
		self.browser_instances = {}
	end
	
	def get_browser(num)
		self.browser_instances[num] ||= Watir::Browser.new :chrome
	end
	
	def add_step(description, points, stop_on_fail, browser_instance = 0, &validation_block)
		self.steps << TestStep.new(description, points, stop_on_fail, browser_instance, &validation_block)
		self
	end
	
	def run
		num_points = 0
		total_points = 0
		skip_the_rest = false
		self.steps.each_with_index{ |step, index|
			if !skip_the_rest
				result = step.run(get_browser(step.browser_instance))
			else
				result = false
			end
			
			puts "[#{index}] #{step.to_s} #{result ? "PASS" : "FAIL"}\n"
			
			num_points += step.points if result
			total_points += step.points
			if ( (step.stop_on_fail & !result) || skip_the_rest)
				skip_the_rest = true
				puts "Testul #{index} a fost sarit datorita unui test anterior esuat\n"
			end
		}
		self.browser_instances.values.each{|browser|
			browser.close
		}
		[num_points, total_points]
	end
	
	def to_s
		"====== #{name} ======\n#{description}\n\n"
	end
end

puts "Checker Tema 3 PWeb\n"

tests = []
$prng = Random.new(Time.now.to_i)
def random_str(size)
	o = [('a'..'z')].map { |i| i.to_a }.flatten
	string = (0...size).map { o[$prng.rand(o.length)] }.join
end
$user1 = random_str($prng.rand(10))
$user2 = random_str($prng.rand(10))

tests << Test.new("Inregistrare Utilizator", "Testul valideaza faptul ca un utilizator se poate inregistra in aplicatia web.").
			add_step("Se acceseaza reset_db.php pentru a goli baza de date", 1, true) { |browser|
				browser.goto "http://localhost/reset_db.php"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se acceseaza pagina principala a aplicatiei", 2, true) { |browser|
				browser.goto "http://localhost/"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se verifica ca nu exista div-ul users/nu e vizibil", 1, true) { |browser|
				!browser.div(:id=>"users").present?
			}.
			add_step("Se introduce un nume de utilizator in campul username", 2, true) { |browser|
				browser.text_field(:id=> "username").set($user1)
				true
			}.
			add_step("Se apasa tasta enter", 1, true) { |browser|
				browser.send_keys(:enter)
				true
			}.
			add_step("Se asteapta aparitia div-ului users", 1, true) { |browser|
				browser.div(:id=>"users").wait_until_present(2)
				true
			}.
			add_step("Se verifica ca nu exista nici un utilizator in lista", 2, false) { |browser|
				browser.div(:id=>"users").divs.size == 0
			}.
			add_step("Se creaza o noua instanta de Chrome si se acceseaza aplicatia", 2, true, 1) { |browser|
				browser.goto "http://localhost/"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se introduce un alt nume de utilizator in campul username", 2, true, 1) { |browser|
				browser.text_field(:id=> "username").set($user2)
				true
			}.
			add_step("Se apasa tasta enter", 1, true, 1) { |browser|
				browser.send_keys(:enter)
				true
			}.
			add_step("Se asteapta aparitia div-ului users in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"users").wait_until_present(2)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru primul user in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"user_#{$user1}").wait_until_present(2)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru al doilea user in prima instanta", 1, true) { |browser|
				browser.div(:id=>"user_#{$user2}").wait_until_present(2)
				true
			}

num_points = 0
total_points = 0
tests.each_with_index{|test, index|
	puts "Test #{index}. \n"
	puts test.to_s
	points = test.run
	num_points += points[0]
	total_points += points[1]
	puts "Rezultat : #{points[0]}/#{points[1]}"
}

puts "\n\nRezultat Final : #{num_points} / #{total_points} = #{((num_points.to_f/total_points.to_f)*100.0).round(2)} %"