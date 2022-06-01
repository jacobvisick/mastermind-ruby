module Secret
    CHOICES = %w(red green yellow blue violet white)

    CORRECT = "√"
    WRONG_LOCATION = "•"
    INCORRECT = "x"

    def is_guess_valid?(guess)
        # don't use format_guess() first
        # if it wasn't formatted, then it isn't valid
        unless guess.is_a? Array
            return false
        end

        # correct length?
        unless guess.length == 4 then
            p guess
            puts "Guess 4 choices"
            return false
        end
        
        # correct colors?
        choices_are_valid = guess.reduce(true) do |result, element|
            break unless result
            result = CHOICES.include?(element)
        end

        unless choices_are_valid
            p guess
            puts "Please choose only the following colors: #{CHOICES}"
            return false
        end

        # if we made it this far, guess should be fine
        return true
    end

    def format_guess(guess)
        guess = guess.downcase.gsub(/[^a-z ]/i, "").split(" ")
    end

    def get_colorized_code(code)

        color_hash = { "red" => "\e[41m   \e[0m",
                 "green" => "\e[42m   \e[0m",
                 "yellow" =>  "\e[43m   \e[0m",
                 "blue" =>  "\e[44m   \e[0m",
                 "violet" =>  "\e[45m   \e[0m",
                 "white" =>  "\e[47m   \e[0m" }

        output = ""
        code.each do |color|
            output += color_hash["#{color}"]
        end

        output
    end


    def get_turn_output(guess, hints)
        output = ""
        output += get_colorized_code(guess)
        output += " "
        output += hints
        output += "\n"
        output
    end
end

class Mastermind
    include Secret

    def initialize
        @secret = generate_secret
        @hints = Array.new(4)
        @history = []

        # TODO: REMOVE WHEN NOT TESTING
        puts "Secret code: " + get_colorized_code(@secret)
    end

    public
    def get_hints(guess)
        hints = check_guess(guess)
        output = "  ["
        hints.each { |hint| output += " #{hint} |" }
        output = output[0...-1] + "]"
    end


    private
    def generate_secret
        secret = []
        4.times { secret.push(CHOICES[rand(6)]) }
        secret
    end

    def check_guess(guess)
        guess.each_with_index do |element, index|
            # first check if right color & index
            if @secret[index] == element then 
                @hints[index] = CORRECT 
            # then check if right color at all
            elsif @secret.include? element then 
                # TODO: only include this marker
                # in the correct quantity
                @hints[index] = WRONG_LOCATION 
            else
                # otherwise it's wrong
                @hints[index] = INCORRECT
            end
        end

        @hints
    end

end

class Guesser
    include Secret

    def initialize
        
    end
    
    def ask_for_guess
        puts "Guess? Valid choices are: #{CHOICES}"
        guess = format_guess(gets.chomp)

        unless is_guess_valid?(guess)
            puts "Invalid response. Try again."
            guess = ask_for_guess
        end

        guess
    end

end

class Game
    # This is mostly just for control flow during testing
    # Much of this will change when Guesser/Mastermind are
    # fleshed out
    #
    # TODO:
    # - flush terminal after each turn so that each turn is played
    #   at the bottom and guess history just builds downward from top
    # - Move all of the display magic into its own module and let
    #   the Guesser/Mastermind classes just handle data/logic

    def initialize
        @history = []
        @mastermind = Mastermind.new
        @guesser = Guesser.new
    end

    def play_turn
        guess = @guesser.ask_for_guess
        hints = @mastermind.get_hints(guess)
        @history.push(@mastermind.get_turn_output(guess, hints))
        @history.each do |turn|
            print turn
        end
    end
end

game = Game.new
game.play_turn
game.play_turn