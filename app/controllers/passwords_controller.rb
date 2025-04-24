class PasswordsController < ApplicationController

  require 'open-uri'
  require 'stringio'
  require 'mini_magick'


  ### CONSTANTS ###

  LETTERS = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q",
           "r","s","t","u","v","w","x","y","z"]

  ALPHA_NUMER = {'a' => 1,'b' => 2,'c' => 3,'d' => 4,'e' => 5,'f' => 6,'g' => 7, 'h' => 8,'i' => 9,
                'j' => 10,'k' => 11,'l' => 12,'m' => 13,'n' => 14,'o' => 15,'p' => 16,'q' => 17,
                'r' => 18,'s' => 19,'t' => 20,'u' => 21,'v' => 22,'w' => 23,'x' => 24,'y' => 25,
                'z' => 26}

  ALPHA_NUMER_STRINGS = {'a' => '1','b' => '2','c' => '3','d' => '4','e' => '5','f' => '6',
                        'g' => '7','h' => '8','i' => '9','j' => '10','k' => '11','l' => '12',
                        'm' => '13','n' => '14','o' => '15','p' => '16','q' => '17','r' => '18',
                        's' => '19','t' => '20','u' => '21','v' => '22','w' => '23','x' => '24',
                        'y' => '25','z' => '26'}

  SAMPLE_TEXT = "The Lord is my shepherd, I shall not want."

  ##################


  # Building Blocks Functions #

  def calculate_anchor(year)
    if year % 400 < 100
      anchor = 2
    elsif (year - 100) % 400 < 100
      anchor = 0
    elsif (year - 200) % 400 < 100
      anchor = 5
    elsif (year - 300) % 400 < 100
      anchor = 3
    end
    return anchor
  end

  def doomsday(year)
    anchor = calculate_anchor(year)
    year_str = year.to_s
    y = (year_str[-2..]).to_i
    a = y / 12
    b = y % 12
    c = (y % 12) / 4

    doomsday = ((a+b+c) % 7 + anchor) % 7
    return doomsday
  end

  def mod7_mod10(num)
    """Convert a mod 7 number into mod 10"""
    mod7_str = num.to_s
    power = 0
    partial_sums = []

    (mod7_str.length - 1).downto(0) do |digit|
      partial_sum = mod7_str[digit].to_i * (7**power)
      partial_sums << partial_sum
      power += 1
    end
  
    mod10 = partial_sums.sum
    return mod10
  end

  # def download_image(url, save_as="image.jpg"):
  #   urllib.request.urlretrieve(url, save_as)
  # end

  
  ### Decoding Functions ###

    
  def text_to_number_first(text)
    number_string = ""
    text.chars.each do |char|
      if char.match?(/\A[a-zA-Z]+\z/)
        number_string += ALPHA_NUMER_STRINGS[char.downcase]
      end
    end
    return number_string
  end

  # def image_to_number_first(im)
  #   width, height = im.size
  #   mid = height // 2
  #   number_str = ""
  #   for x in range(width):
  #     r,g,b = im.getpixel((x, mid))
  #     number_str += str(r+g+b)
  #   return number_str
  # end

  def number_to_years(number_string, n)
    years = number_string.chars.each_slice(n).map(&:join)
    years
  end

  def years_list_to_doomsdays(years_list)
    doomsdays = []
    years_list.each do |year_str|
      year = year_str.to_i
      doomsdays.append(doomsday(year))
    # print(f"These are the doomsdays: {doomsdays}")
    end
    return doomsdays
  end


  def ddays_modded_joined(ddays_list)
    """
    Since the ddays only range from 0 to 6, we will modify the numbers, ensuring
    variety in all digits. We will do so by (1) joining the ddays into 3-digit
    numbers, and (2) converting these 3-digit mod7 numbers into mod10. Also, we
    will take this list of numbers and convert in into a joined string of numbers
    """
    # Convert each element to a string
    ddays_strings = ddays_list.map(&:to_s)
  
    # Join all elements into a single string
    ddays_joined_str = ddays_strings.join
  
    # Split into 3-digit segments
    ddays_3s = number_to_years(ddays_joined_str, 3) # list of 3-digit string numbers
  
    # Convert each 3-digit mod7 number into mod10
    mod10_list = ddays_3s.map { |mod7| mod7_mod10(mod7.to_s) }
  
    # Join the modified numbers into a final string
    mod10_list.join
  end
  

  def number_str_to_ascii(number_string)
    # Split the string into 2-digit numbers
    doubles = number_string.chars.each_slice(2).map(&:join).map(&:to_i)

    # Remove numbers greater than 93
    doubles.reject! { |number| number > 93 }

    # Convert remaining numbers to ASCII codes by adding 33
    ascii_codes = doubles.map { |number| number + 33 }

    ascii_codes
  end

  def ascii_codes_to_password(ascii_codes)
    # Convert ASCII codes to characters and join into a string
    ascii_codes.map(&:chr).join
  end


  # Execution of Decoding #


  def decode(input, complexity)
    # Given a sample body of text or image, use a special set of pre-dictated
    # rules to reveal the secret code. The complexity is the number of digits
    # in the years computed in the early steps.
  
    first_number_string = if input.is_a?(String)
                            text_to_number_first(input)
                          else
                            image_to_number_first(input)
                          end
  
    years_list = number_to_years(first_number_string, complexity)
    doomsdays = years_list_to_doomsdays(years_list)
    modded_joined = ddays_modded_joined(doomsdays)
    ascii_codes = number_str_to_ascii(modded_joined)
  
    password = ascii_codes_to_password(ascii_codes)
    password
  end
    

  # def decode_url(url: str, complexity: int) -> str:
  #   download_image(url, "image.jpg")
  #   img = Image.open("image.jpg")
  #   password = decode(img, complexity)
  #   return password
  # end


  def generate_password
    @complexity = params.fetch("query_complexity").to_i
    @complexity_class = @complexity.class
    @input_type = params.fetch("query_type")

    if @input_type == "Text"
      text_body = params.fetch("query_content_text")
      @password = decode(text_body, @complexity)
    end

    # @password = "Good job"

    render({:template => "submission"})

    # redirect_to("/password")
  end

  # def show
  #   @password = generate_password
  #   render({:template => "submission"})
  # end

end


########### Image Testing ###########

def password_from_image_pixels(url)
  # fetch into memory
  data = URI.open(url).read
  io = StringIO.new(data)

  img = MiniMagick::Image.read(io)   
  pixels = img.get_pixels        

  # from here, I can do some computation on the pixels and such.
  # This data will be passed on to other functions like image_to_number or something
end

#####################################


# Debugging Help #

# SAMPLE_IMAGE = Image.open("ronald_reagan.jpg")
# print(decode(SAMPLE_IMAGE, 220))

###

# image_url = "https://www.baseball-reference.com/req/202408150/images/headshots/e/e463317c_sabr.jpg"

# decode_url(image_url, 100)
