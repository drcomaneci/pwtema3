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
				puts "Pasul #{index} a fost sarit datorita unui test anterior esuat\n"
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

#create some random users & messages
$users = []
$messages = []
3.times {
	$users << random_str($prng.rand(10) + 5)
	$messages << random_str($prng.rand(30) + 5)
}

$users = $users.sort
$user1, $user2 = $users.sort
$msg1, $msg2 = $messages
$max_wait_time = 5

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
				browser.div(:id=>"users").wait_until_present($max_wait_time)
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
				browser.div(:id=>"users").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru primul user in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"user_#{$user1}").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru al doilea user in prima instanta", 1, true) { |browser|
				browser.div(:id=>"user_#{$user2}").wait_until_present($max_wait_time)
				true
			}

tests << Test.new("Creare Discutie", "Testul valideaza faptul ca se poate crea o discutie intre doi utilizatori.").
			add_step("Se acceseaza reset_db.php pentru a goli baza de date", 1, true) { |browser|
				browser.goto "http://localhost/reset_db.php"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se acceseaza pagina principala a aplicatiei", 2, true) { |browser|
				browser.goto "http://localhost/"
				browser.title.include?("404") ? false : true
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
				browser.div(:id=>"users").wait_until_present($max_wait_time)
				true
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
				browser.div(:id=>"users").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru primul user in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"user_#{$user1}").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru al doilea user in prima instanta", 1, true) { |browser|
				browser.div(:id=>"user_#{$user2}").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se face click pe al doilea user pentru a initia o discutie", 3, true) { |browser|
				browser.div(:id=>"user_#{$user2}").click
				true
			}.
			add_step("Se verifica existenta div-ului chats", 1, true) { |browser|
				browser.div(:id=>"chats").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se verifica existenta div-ului pentru discutia specifica", 3, true) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				true
			}
			.add_step("Se verifica ca exista un div participants in interiorul div-ului pentru discutie si ca acela contine numele utilizatorilor", 2, true) { |browser|
				participants = browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"participants").text
				participants.include?($user1) && participants.include?($user2)
			}
			.add_step("Se verifica ca div-ul last_message sa existe in interior-ul div-ului pentru discutie si sa fie gol (nu exista inca un ultim mesaj)", 2, true) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"last_message").text == ""
			}.
			add_step("Se verifica existenta div-ului chats in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"chats").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se verifica existenta div-ului pentru discutia specifica in a doua instanta", 3, true, 1) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				true
			}
			.add_step("Se verifica ca exista un div participants in interiorul div-ului pentru discutie si ca acela contine numele utilizatorilor in a doua instanta", 2, true, 1) { |browser|
				participants = browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"participants").text
				participants.include?($user1) && participants.include?($user2)
			}
			.add_step("Se verifica ca div-ul last_message sa existe in interior-ul div-ului pentru discutie si sa fie gol (nu exista inca un ultim mesaj) in a doua instanta", 2, true, 1) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"last_message").text == ""
			}

tests << Test.new("Discutie intre doua persoane", "Testul valideaza faptul doi utilizatori pot schimba mesaje intre ei.").
			add_step("Se acceseaza reset_db.php pentru a goli baza de date", 1, true) { |browser|
				browser.goto "http://localhost/reset_db.php"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se acceseaza pagina principala a aplicatiei", 1, true) { |browser|
				browser.goto "http://localhost/"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se introduce un nume de utilizator in campul username", 1, true) { |browser|
				browser.text_field(:id=> "username").set($user1)
				true
			}.
			add_step("Se apasa tasta enter", 1, true) { |browser|
				browser.send_keys(:enter)
				true
			}.
			add_step("Se asteapta aparitia div-ului users", 1, true) { |browser|
				browser.div(:id=>"users").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se creaza o noua instanta de Chrome si se acceseaza aplicatia", 1, true, 1) { |browser|
				browser.goto "http://localhost/"
				browser.title.include?("404") ? false : true
			}.
			add_step("Se introduce un alt nume de utilizator in campul username", 1, true, 1) { |browser|
				browser.text_field(:id=> "username").set($user2)
				true
			}.
			add_step("Se apasa tasta enter", 1, true, 1) { |browser|
				browser.send_keys(:enter)
				true
			}.
			add_step("Se asteapta aparitia div-ului users in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"users").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru primul user in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"user_#{$user1}").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se asteapta aparitia div-ului pentru al doilea user in prima instanta", 1, true) { |browser|
				browser.div(:id=>"user_#{$user2}").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se face click pe al doilea user pentru a initia o discutie", 1, true) { |browser|
				browser.div(:id=>"user_#{$user2}").click
				true
			}.
			add_step("Se verifica existenta div-ului chats", 1, true) { |browser|
				browser.div(:id=>"chats").wait_until_present($max_wait_time)
				true
			}.
			add_step("Se verifica existenta div-ului pentru discutia specifica", 1, true) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				true
			}
			.add_step("Se verifica ca div-ul last_message sa existe in interior-ul div-ului pentru discutie si sa fie gol (nu exista inca un ultim mesaj)", 2, true) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"last_message").text == ""
			}.
			add_step("Se verifica existenta div-ului chats in a doua instanta", 1, true, 1) { |browser|
				browser.div(:id=>"chats").wait_until_present($max_wait_time)
				true
			}
			.add_step("Se verifica existenta div-ului pentru discutia specifica in a doua instanta", 3, true, 1) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").wait_until_present($max_wait_time)				
				true
			}
			.add_step("Se verifica ca div-ul last_message sa existe in interior-ul div-ului pentru discutie si sa fie gol (nu exista inca un ultim mesaj) in a doua instanta", 2, true, 1) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"last_message").text == ""
			}
			.add_step("Se verifica ca exista un div participants in interiorul div-ului chat_area pentru discutie si ca acela contine numele utilizatorilor in a prima instanta", 3, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				participants = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"participants").text
				participants.include?($user1) && participants.include?($user2)
			}
			.add_step("Se verifica existenta div-ului messages in interiorul div-ului chat_area_#{$user1}_#{$user2} si ca acesta nu contine nici un mesaje", 4, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				messages.divs.size == 0
			}
			.add_step("Se verifica existenta div-ului my_message in interiorul div-ului chat_area_#{$user1}_#{$user2} si ca acesta contine un input de tip text", 2, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				my_message = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"my_message")
				my_message.text_field(:id=>"my_message_field").present?
			}
			.add_step("Se verifica existenta div-ului additional_participants in interiorul div-ului chat_area_#{$user1}_#{$user2} si ca acesta contine un buton pentru adaugat un participant la discutie", 2, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				additional = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"additional_participants")
				additional.button(:id=>"add_participant").present?
			}
			.add_step("Se adauga un mesaj de la #{$user1} in chat_area_#{$user1}_#{$user2} si se verifica ca acesta apare in div-ul messages", 4, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				my_message = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"my_message")
				message_field = my_message.text_field(:id=>"my_message_field")
				message_field.send_keys($msg1)
				message_field.send_keys(:enter)
				
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				msg1 = messages.div(:id=>"msg_1")
				msg1.wait_until_present($max_wait_time)
				msg1.div(:id=>"content").present? && msg1.div(:id=>"timestamp").present? && msg1.div(:id=>"from").present?
			}
			.add_step("Se verifica continutul mesajului anterior", 5, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				msg1 = messages.div(:id=>"msg_1")
				msg1.div(:id=>"content").text.include?($msg1) && msg1.div(:id=>"from").text.include?($user1)
			}
			.add_step("Se verifica aparitia mesajului si in a doua instanta", 8, true, 1) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)				
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				messages.div(:id=>"msg_1").wait_until_present($max_wait_time)
			}
			.add_step("Se verifica continutul mesajului in a doua instanta", 8, true, 1) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				msg1 = messages.div(:id=>"msg_1")
				msg1.div(:id=>"content").text.include?($msg1) && msg1.div(:id=>"from").text.include?($user1)
			}
			.add_step("Se adauga un mesaj de la #{$user2} in chat_area_#{$user1}_#{$user2} si se verifica ca acesta apare in div-ul messages", 4, true, 1) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				my_message = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"my_message")
				message_field = my_message.text_field(:id=>"my_message_field")
				message_field.send_keys($msg2)
				message_field.send_keys(:enter)
				
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				msg1 = messages.div(:id=>"msg_2")
				msg1.wait_until_present($max_wait_time)
				msg1.div(:id=>"content").present? && msg1.div(:id=>"timestamp").present? && msg1.div(:id=>"from").present?
			}
			.add_step("Se verifica aparitia mesajului in prima instanta", 8, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)				
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				messages.div(:id=>"msg_2").wait_until_present($max_wait_time)
			}
			.add_step("Se verifica continutul mesajului in prima instanta", 8, true) { |browser|
				browser.div(:id=>"chat_area_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				messages = browser.div(:id=>"chat_area_#{$user1}_#{$user2}").div(:id=>"messages")
				msg1 = messages.div(:id=>"msg_2")
				msg1.div(:id=>"content").text.include?($msg2) && msg1.div(:id=>"from").text.include?($user2)
			}
			.add_step("Se verifica continutul ultimului mesaj din chat_#{$user1}_#{$user2}", 12, true) { |browser|
				browser.div(:id=>"chat_#{$user1}_#{$user2}").wait_until_present($max_wait_time)
				last_message = browser.div(:id=>"chat_#{$user1}_#{$user2}").div(:id=>"last_message")
				last_message.text.include?($user2) && last_message.text.include?($msg2)
			}

multi_user_discussion = Test.new("Discutie intre 3 persoane", "Testul valideaza faptul trei utilizatori pot schimba mesaje intre ei.")
							.add_step("Se acceseaza reset_db.php pentru a goli baza de date", 1, true) { |browser|
								browser.goto "http://localhost/reset_db.php"
								browser.title.include?("404") ? false : true
							}
$users.size.times { |i|
	multi_user_discussion
		.add_step("Se acceseaza pagina principala a aplicatiei in instanta #{i}", 1, true, i) { |browser|
			browser.goto "http://localhost/"
			browser.title.include?("404") ? false : true
		}
		.add_step("Se introduce un nume de utilizator #{$users[i]} in campul username in instanta #{i}", 1, true, i) { |browser|
			browser.text_field(:id=> "username").set($users[i])
			true
			}
		.add_step("Se apasa tasta enter in instanta #{i}", 1, true, i) { |browser|
			browser.send_keys(:enter)
			true
			}
		.add_step("Se asteapta aparitia div-ului users in instanta #{i}", 1, true, i) { |browser|
			browser.div(:id=>"users").wait_until_present($max_wait_time)
			true
		}
}

$users.size.times { |i|
	multi_user_discussion
		.add_step("Se verifica aparitia utilizatorilor corespunzatori in instanta #{i}", 1, true, i) { |browser|
			$users.each {|user|
				if (user != $users[i])
					browser.div(:id=>"user_#{user}").wait_until_present($max_wait_time)
				end
			}
			true
		}
}

multi_user_discussion
	.add_step("Se face click pe al doilea user din prima instanta pentru a initia o discutie", 1, true, 0) { |browser|
		users = browser.div(:id=>"users")
		users.wait_until_present($max_wait_time)
		users.div(:id=>"user_#{$users[1]}").click
		true
	}
	.add_step("Se apasa pe butonul de add participants si se selecteaza utilizatorul al 3-lea", 5, true, 0) { |browser|
		chat_area = browser.div(:id=>"chat_area_#{$users[0]}_#{$users[1]}")
		chat_area.wait_until_present($max_wait_time)
		chat_area.input(:type=> "button", :id=>"add_participant").click
		browser.div(:id=>"user_#{$users[2]}").click
		true
	}

$users.size.times { |i|
	multi_user_discussion
	.add_step("Se verifica existenta div-ului pentru discutia specifica in instanta #{i}", 3, true, i) { |browser|
		browser.div(:id=>"chat_area_#{$users[0]}_#{$users[1]}_#{$users[2]}").wait_until_present($max_wait_time)
		true
	}
	.add_step("Se verifica existenta div-ului pentru discutia specifica in instanta #{i}", 3, true, i) { |browser|
		browser.div(:id=>"chat_area_#{$users[0]}_#{$users[1]}_#{$users[2]}").wait_until_present($max_wait_time)
		true
	}
	.add_step("Se trimite un mesaj din instanta #{i}", 3, true, i) { |browser|
		message_field = browser.div(:id=>"chat_area_#{$users[0]}_#{$users[1]}_#{$users[2]}").input(:type => "text", :id=>"my_message_field")
		message_field.send_keys($messages[i])
		message_field.send_keys(:enter)
		true
	}
}

$users.size.times { |i|
	multi_user_discussion
	.add_step("Se verifica aparitia mesajelor in instanta #{i} in ordinea corespunzatoare", 5, true, i) { |browser|
		messages_div = browser.div(:id=>"chat_area_#{$users[0]}_#{$users[1]}_#{$users[2]}").div(:id=>"messages")
		messages_div.wait_until_present($max_wait_time)
		result = true
		$messages.each_with_index {|msg, i|
			result = result && (messages_div.div(:id => "msg_#{i + 1}").text.include?($messages[i]))
		}
		result
	}
}

tests << multi_user_discussion
			
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