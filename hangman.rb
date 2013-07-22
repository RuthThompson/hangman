module YesOrNo
	def yes_or_no?(string)
		string = string.dup.chomp.downcase.strip
		['yes', 'no', 'y', 'n'].include?(string)
	end	
	
	def yes?(string)
		string = string.dup.chomp.downcase.strip
		return true if string == 'yes' || string == 'y'
		false
	end
	
	def no?(string)
		string = string.dup.chomp.downcase.strip
		return true if string == 'no' || string == 'n'
		false
	end
	
	def verify(value)
		have_answer = false
		until have_answer
			puts "I have #{value}.  Is that correct?"
			answer = gets.chomp
			have_answer = yes_or_no?(answer)
		end
		return yes?(answer)
	end
end

class Hangman

	include YesOrNo
	
	def initialize()
		@judge = nil
		@guesser = nil
		@guesses_left = nil
		@board = nil
	end
	
	def play
		start_game
		until over?
			
			guess = @guesser.guess_letter(@board)
			letter_locations = @judge.judge_letter(guess, @guesser.name)
			if letter_locations.length == 0
				@guesses -= 1
			else
				@board.update(letter_locations, guess )
			end
			puts
			puts "#{@guesser.name} has #{@guesses} wrong guesses left"
			puts
		end
		closing_remarks
	end
	
	private
	
	def closing_remarks
		if won?
			puts "#{@guesser.name} guessed the secret word!  There will be no hanging. " 
		elsif lost?
			puts "#{@guesser.name} hangs."
			puts "The word was #{@judge.say_word}"
		end
		play_again
	end
	
	def play_again
		have_answer = false
		until have_answer
			puts "Would you like to play again?"
			answer = gets.chomp
			have_answer = yes_or_no?(answer)
		end
		if yes?(answer)
			self.play
		end
	end
	
	def over?
		won? || lost?
	end
	
	def won?
		@board.won?
	end
	
	def lost?
		@guesses == 0
	end
		
	def get_player(player)
		player_type = player_type(player)
		player_name = player_name(player)
		if player_type == 'computer'
			player = ComputerPlayer.new(player_name)
		elsif
			player = HumanPlayer.new(player_name)
		end
		player
	end
	
	def player_name(player)
		have_player_name = false
		until have_player_name
			puts "What is #{player}'s name?"
			player_name = gets.chomp.strip
			have_player_name = verify(player_name)
		end
		player_name
	end
	
	def player_type(player)
		have_player_type = false
		until have_player_type
			puts "Is #{player} a human or a computer?"
			player_type = gets.chomp.strip.downcase
			if ['human', 'computer'].include?(player_type)
				have_player_type = true
			end
		end
		player_type
	end
		
	def start_game( options = {} )
		defaults = {
			:guesses => 10
		}
		
		options = defaults.merge(options)
		
		@judge = get_player('the judge')
		@guesser = get_player('the hangman')
		
		@guesses = options[:guesses]
		letters = @judge.reset_word.word_length
		@board = Board.new(letters)
	end
	
end

class Board
	
	attr_reader :current
	
	def initialize(num)
		@current = []
		num.times { @current << nil }
	end
	
	def display
		board = @current.map { |spot| spot.nil? ? "_" : spot } 
		puts "Secret Word: #{board.join(' ')}"
		@current
	end
	
	def length
		@current.length
	end
	
	def update(indices, letter)
		indices.each do |index|
			@current[index] = letter
		end
	end
	
	def won?
		!@current.include?(nil)
	end
	
end


class ComputerPlayer

	@@computers = 0
	
	def self.computers
		@@computers
	end
	
	def self.computers=(num)
		@@computers = num
	end
	
	attr_accessor(:name)
	
	def initialize(name = nil, dictionary = 'dictionary.txt')
		ComputerPlayer.computers += 1
		name = "Computer #{ComputerPlayer.computers}" if name.nil? 
		@name = name
		@dictionary = load_dictionary(dictionary)
		@remaining_dictionary = nil
		@guessed_letters = []
		@word = nil
	end
	
	def reset_word
		@word = @dictionary.keys.sample
		self
	end
	
	def word_length
		reset_word if @word.nil?
		@word.length
	end
	
	def guess_letter(board)
		board.display
		@guessed_letters << get_next_best_letter(board)
		@guessed_letters[-1]
	end
	
	
	def remaining_dictionary(board)
		if @remaining_dictionary == nil
			@remaining_dictionary = @dictionary.select do |word, t|
				word.length == board.length
			end
		end
		@remaining_dictionary = @remaining_dictionary.select { |wrd, t| word_possible?(wrd, board) }
		@remaining_dictionary
	end	
	
	def word_possible?(word, board)
		possible = true
		board.current.each_with_index do |spot, index|
			if spot.nil?
				possible = false if @guessed_letters.include?(word[index]) 
			else
				possible = false if word[index] != spot
			end
		end
		possible
	end
	
	def get_next_best_letter(board)
		remaining_dictionary = self.remaining_dictionary(board)
		letters = Hash.new(0)
		remaining_dictionary.each do |word, t|
			word.each_char do |char|
				letters[char] +=1 unless @guessed_letters.include?(char) 	
			end
		end
		letters.sort_by { |letter, count| count }.pop[0]
	end
	
	def judge_letter(letter, name = nil )
		indices = []
		@word.split('').each_with_index do |l, index|
			indices << index if l == letter
		end
		indices
	end
	
	def say_word
		@word
	end
	
	private
	
	def load_dictionary(dictionary)
		Hash[File.readlines(dictionary).map{ |word| [word.chomp, true] }]
	end
	
end

class HumanPlayer

	@@humans = 0
	
	def self.humans
		@@humans
	end
	
	def self.humans=(num)
		@@humans = num
	end
	
	include YesOrNo
	
	attr_accessor(:name)
	
	def initialize(name = nil)
		HumanPlayer.humans += 1
		name = "Human #{HumanPlayer.humans}" if name.nil? 
		@name = name
	end
	
	def say_word
		puts "What was your word?"
		gets.chomp.strip
	end
	
	def reset_word
		print "#{self.name} think of a word.  " 
		self
	end
	
	def word_length 
		have_len = false
		until have_len
			puts "How many letters does your word have?"
			len = gets.chomp.to_i
			have_len = len.to_s.length > 0
		end
		len			
	end
	
	def guess_letter(board)
		board.display
		have_letter = false
		until have_letter
			puts "#{self.name} guess a letter"
			letter = gets.chomp.downcase
			have_letter = letter.between?("a", "z")
		end
		letter		
	end
	
	def judge_letter(letter, name = "The other player")
		return [] unless letter_in_word?(letter, name) 
		have_spots = false
		until have_spots
			puts "#{self.name}, at what indices does '#{letter}' occur in your word? (please separate multiple values by commas (eg '0, 4, 5')"
			spots = gets.chomp.split(',').map {|index| index.strip.to_i } 
			have_spots = verify(spots.map(&:to_s).join(', '))
		end
		spots
	end
	
	private
	
	def letter_in_word?(letter, name = "The other player")
		have_answer = false
		until have_answer
			puts "#{self.name}, #{name} picked #{letter}.  Is #{letter} in your word?"
			answer = gets.chomp
			have_answer = yes_or_no?(answer)
		end
		yes?(answer)
	end
	

end


a = Hangman.new.play