class Wordle

  # All capital letters.
  CAPITALS = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']


  def initialize(dictionary)
    # This is our current dictionary.
    @dictionary = Wordle.create_dictionary(dictionary)
    @original_dictionary = @dictionary.clone

    # These letters should never be present in any word.
    @wrong_letters = []

    # These letters are present in the word but not in this position.
    # {letter: index:}
    @present_letters = []

    # These letters MUST be in a specific position.
    # {letter: index:}
    @correct_letters = []

    @guess = 0

    puts "Initializing dictionary with #{@dictionary.count} words"
  end

  def inspect
    'Wordle'
  end

  # Main loop function. Call for each guess.
  def next_guess()
    @guess += 1
    if @dictionary.count == 0
      puts 'No words left in the dictionary!'
      return false
    end
    word_scores = score_words
    guess, correction = ask_user(word_scores)
    update_dictionary(guess, correction)
    if correction == 'GGGGG'
      puts 'Huzzah!'
      return false
    end
    true
  end

  # Creates a word strength score for the current dictionary.
  def score_words
    letters = raw_available_characters
    letter_probabilities = probabilities(letters)
    score_dictionary(letter_probabilities)
  end

  # Presents the user with top ten word scores and
  # suggests a next guess. Takes in corrections from
  # the command line.
  def ask_user(word_scores)
    puts word_scores.count
    puts word_scores.last(10)
    guess = word_scores.last[:word]
    puts "Next guess (#{@guess}): #{guess}"
    puts 'Corrections: X = Not present, Y = Present, G = Exactly, ie XXYGX'
    correction = gets.chomp
    [guess, correction]
  end

  # Given a set of letter probabilities, scores every single
  # word in the dictionary and sorts it asc by score.
  def score_dictionary(letter_probabilities)
    scored_dictionary = []
    @dictionary.each do |word|
      score = 0.0

      # We're going to ignore letters we've already seen
      # because generally that is going to be less information.
      seen_letters = {}

      word.chars.each do |letter|
        repeat_strength = 1.0
        if seen_letters.include?(letter)
          repeat_strength = 0.5
        end
        letter = letter.downcase
        seen_letters[letter] = true
        score += (letter_probabilities[letter] * repeat_strength)
      end
      scored_dictionary << {word: word, score: score}
    end
    scored_dictionary.sort_by { |scored_word| scored_word[:score] }
  end

  # Determines the probability of each letter across all words by occurrence.
  def probabilities(letters)
    # This can also just be 5 * the number of words but whatever.
    total = letters.values.reduce(0) { |memo, v| memo + v }
    letter_probabilities = {}
    letters.each do |k,v|
      letter_probabilities[k] = v.to_f / total.to_f
    end
    letter_probabilities
  end

  # Determines the raw integer character counts for each letter
  # in each word in the dictionary.
  def raw_available_characters
    characters = {}
    @original_dictionary.each do |word|
      word.chars.each do |letter|
        letter = letter.downcase
        count = characters[letter] || 0
        characters[letter] = count + 1
      end
    end
    characters
  end

  # Updates the dictionary given the last guess and the corrections for it.
  def update_dictionary(guess, correction)
    update_known_letters(guess, correction)
    filter_dictionary
  end

  # Our shorthand for signaling corrections back from wordle.
  NOT_PRESENT = 'X'
  WRONG_INDEX = 'Y'
  CORRECT = 'G'

  # Updates what we know about the word.
  def update_known_letters(guess, correction)
    [*0..4].each do |i|
      case correction[i]
      when NOT_PRESENT
        @wrong_letters << guess[i]
      when WRONG_INDEX
        @present_letters << {letter: guess[i], index: i}
      when CORRECT
        @correct_letters << {letter: guess[i], index: i}
      end
    end
  end

  # Filters the dictionary based on what we know already.
  def filter_dictionary
    @dictionary.filter! do |word|
      none_wrong?(word) && any_present_but_none_exactly?(word) && all_correct?(word)
    end
  end

  # Are all of the letters in the word not in the not present list?
  def none_wrong?(word)
    word.chars.each do |letter|
      if @wrong_letters.include?(letter)
        return false
      end
    end
    true
  end

  # Are all of the letters in the word present in the present list, but not
  # at the exact index?
  def any_present_but_none_exactly?(word)
    return true if @present_letters.count == 0
    any_present?(word) && none_exactly?(word)
  end

  def any_present?(word)
    @present_letters.each do |present|
      unless word.chars.include?(present[:letter])
        return false
      end
    end
    true
  end

  def none_exactly?(word)
    @present_letters.each do |present|
      # We actually don't care to keep anything that has the right letter
      # but it was marked as being in the wrong place.
      if word[present[:index]] == present[:letter]
        return false
      end
    end

    true
  end

  # Are all of the words exactly in the right place?
  def all_correct?(word)
    all_correct = true
    @correct_letters.each do |correct|
      unless word[correct[:index]] == correct[:letter]
        all_correct = false
      end
    end
    all_correct
  end

  # Creates a dictionary from an arbitrary file.
  # Ignores words that start with a capital letter.
  def self.create_dictionary(dictionary_filename)
    dictionary = []
    puts "Using dictionary #{dictionary_filename}"
    File.open(File.expand_path(dictionary_filename), 'r') do |file|
      file.each do |word|
        next if word.start_with?(*CAPITALS)
        word = word.chomp
        if word.length == 5
          dictionary << word.downcase
        end
      end
    end
    dictionary.uniq
  end

end

GUESSES = 6

# '/usr/share/dict/words'
dictionary = '~/words_alpha.txt'
worlde = Wordle.new(dictionary)

[*1..GUESSES].each do |i|
  unless worlde.next_guess()
    break
  end
end