module Secret
    CHOICES = %w(red green yellow blue violet white)

    CORRECT = "√"
    WRONG_LOCATION = "•"
    INCORRECT = "x"

    def is_code_valid?(guess)
        # don't use format_code() first
        # if it wasn't formatted, then it isn't valid
        unless guess.is_a? Array
            return false
        end

        # correct length?
        unless guess.length == 4 then
            p guess
            puts "Please guess exactly 4 choices"
            return false
        end
        
        # correct colors?
        colors_are_valid = guess.reduce(true) do |result, element|
            break unless result
            result = CHOICES.include?(element)
        end

        unless colors_are_valid
            p guess
            puts "Please choose only the following colors: #{CHOICES}"
            return false
        end

        # if we made it this far, guess should be fine
        return true
    end

    def format_code(code)
        code = code.downcase.gsub(/[^a-z ]/i, "").split(" ")
        exit if code[0] == 'exit'
        code
    end

    def generate_code
        secret = []
        4.times { secret.push(CHOICES[rand(6)]) }
        secret
    end


end

module Display

    CORRECT = "√"
    WRONG_LOCATION = "•"
    INCORRECT = "x"

    INSTRUCTIONS = "Welcome to mastermind!\n" \
                   "In this game, you will have twelve turns to guess the secret code.\n" \
                   "The code is 4 colors long. After each guess, you will receive a hint.\n" \
                   "The hints will be: \n" \
                   "    #{CORRECT} : Correct color and location\n" \
                   "    #{WRONG_LOCATION} : Correct color, but wrong location\n" \
                   "    #{INCORRECT} : Wrong color OR you guessed more of this color\n" \
                   "        than there is in the code.\n\n" \
                   "Your choices are: \e[41m red \e[0m, \e[42m green \e[0m, \e[43m yellow \e[0m, " \
                   "\e[44m blue \e[0m, \e[45m violet \e[0m, or \e[47m\e[30m white \e[0m\e[0m" \
                   "\n\nNow, please eneter your guess below."

    SCREEN = [
        "\n", #turn 1
        "\n", #turn 2
        "\n", #turn 3
        "\n", #turn 4
        "\n", #turn 5
        "\n", #turn 6
        "\n", #turn 7
        "\n", #turn 8
        "\n", #turn 9
        "\n", #turn 10
        "\n", #turn 11
        "\n", #turn 12
        "\n", #3 line buffer
        "\n", 
        "\n",
        INSTRUCTIONS,
        "\n"
    ]
    def get_turn_output(guess, hints, turn_number)
        output = ""
        output += get_colorized_code(guess)
        output += " "
        output += hints
        output += " [#{turn_number}]"
        output += "\n"
        output
    end

    def get_colorized_code(code)
        color_hash = { "red" => "\e[41m   \e[0m",
                 "green" => "\e[42m   \e[0m",
                 "yellow" =>  "\e[43m   \e[0m",
                 "blue" =>  "\e[44m   \e[0m",
                 "violet" =>  "\e[45m   \e[0m",
                 "white" =>  "\e[47m   \e[0m" }

        colorized_code = ""
        code.each do |color|
            colorized_code += color_hash["#{color}"]
        end

        colorized_code
    end

    def resize_terminal
        system("printf '\e[8;30;90t'")
    end

    def show_message(message, screen)
        screen[-1] = message
        puts screen
        screen
    end

    def update_screen(screen)
        system("clear")
        puts screen
    end

end

class Mastermind
    include Secret
    include Display

    def initialize(true_if_human)
        @hints = Array.new(4)
        @history = []
        @is_human = true_if_human
        true_if_human ? @secret = get_user_code : @secret = generate_code

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

    def is_game_won?
        @hints == [CORRECT, CORRECT, CORRECT, CORRECT]
    end

    def is_human?
        @is_human
    end

    private
    def get_user_code
        puts "Please enter a four part code."
        puts "Your choices are: \e[41m red \e[0m, \e[42m green \e[0m, \e[43m yellow \e[0m, " \
            "\e[44m blue \e[0m, \e[45m violet \e[0m, or \e[47m\e[30m white \e[0m\e[0m" \
            "\n\nNow, please eneter your guess below."
        puts "Remember, you can repeat colors in the code if you like."
        code = format_code(gets.chomp)

        unless is_code_valid?(code)
            puts "Invalid response. Try again."
            code = get_user_code
        end

        @secret = code
    end

    def check_guess(guess)
        hinted_color_count = Hash.new(0)
        @hints = Array.new(4)

        # update @hints with correct locations first
        hinted_color_count = check_correct(guess, hinted_color_count)
        # update @hints with wrong locations after we know how many are correct
        hinted_color_count = check_wrong_location(guess, hinted_color_count)
        # update @hints with incorrect marker after
        @hints = @hints.map { |hint| hint ? hint : INCORRECT }

        @hints
    end

    def check_correct(guess, hinted_color_count)
        guess.each_with_index do |element, index|
            if @secret[index] == element then
                @hints[index] = CORRECT
                hinted_color_count[element] += 1
            end
        end

        hinted_color_count
    end

    def check_wrong_location(guess, hinted_color_count)
        guess.each_with_index do |element, index|
            next if @hints[index]
            if @secret.include? element then
                if hinted_color_count[element] < @secret.count(element) then
                    @hints[index] = WRONG_LOCATION
                    hinted_color_count[element] += 1
                end
            end
        end

        hinted_color_count
    end


end

class Guesser
    include Secret

    def initialize(true_if_human)
        @is_human = true_if_human
        @guess_history = []
    end

    public
    def guess
        @is_human ? guess_as_player : guess_as_computer
    end

    def is_human?
        @is_human
    end

    def give_computer_hints(guess, hints)
        hint_array = hints.delete(" ")
                          .delete("|")
                          .delete("[")
                          .delete("]")
                          .split("")

        @guess_history.push({ guess: guess, hint: hint_array })
    end
    
    private
    def guess_as_player
        puts "Valid choices are: #{CHOICES}"
        guess = format_code(gets.chomp)

        unless is_code_valid?(guess)
            puts "Invalid response. Try again."
            guess = guess_as_player
        end

        guess
    end

    def guess_as_computer
        if @guess_history.length == 0
            generate_code
        else
            #create a guess from hints
            last_guess = @guess_history[-1][:guess]
            last_hints = @guess_history[-1][:hint]
            next_guess = Array.new(4)
            valid_colors = []

            last_hints.each_with_index do |hint, index|
                if hint == CORRECT then
                    next_guess[index] = last_guess[index]
                elsif hint == WRONG_LOCATION then
                    valid_colors.push(last_guess[index])
                end
            end

            next_guess = next_guess.map do |color|
                if color == nil
                    if valid_colors.length == 0 then
                        color = CHOICES[rand(CHOICES.length)]
                    else
                        color = valid_colors.shuffle.pop
                    end
                else
                    color
                end
            end

            next_guess
        end
    end

end

class Game
    include Display

    def initialize
        resize_terminal
        @team = get_team

        @history = []
        @mastermind = Mastermind.new(@team == "mastermind")
        @guesser = Guesser.new(@team == "guesser")
        @screen = SCREEN.map(&:clone)
        update_screen(@screen)
    end

    def get_team
        puts "Would you like to play as the Mastermind or the Guesser?"
        team = gets.chomp.downcase.gsub(/[^a-z ]/i, "")

        team = get_team unless team == "mastermind" || team == "guesser"

        team
    end

    
    def play
        guessed_correctly = false

        while @history.length < 12
            play_turn
            update_screen(@screen)
            guessed_correctly = @mastermind.is_game_won?
            break if guessed_correctly
        end

        guessed_correctly ? game_win : game_lose
    end

    private
    def play_turn
        guess = @guesser.guess

        hints = @mastermind.get_hints(guess)
        @history.push(@mastermind.get_turn_output(guess, hints, @history.length + 1))
        @history.each_with_index do |turn, index|
            @screen[index] = turn
        end

        @guesser.give_computer_hints(guess, hints) if @team == "mastermind"
    end

    def game_win
        show_message("\e[32mYou guessed correctly in #{@history.length} turns!\e[0m", @screen)
    end
    
    def game_lose
        show_message("\e[31mSorry, you didn't guess in time.\e[0m", @screen)
    end
end

game = Game.new
game.play