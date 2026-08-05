class RotpIdGeneratorService
  include ServicePattern

  def initialize(operating_name, onboarded_at, attempt)
    @operating_name = operating_name
    @onboarded_at = onboarded_at
    @attempt = attempt
  end

  def call
    build_rotp_id
  end

private

  attr_reader :operating_name, :onboarded_at, :attempt

  def seed
    @seed ||= "#{operating_name}|#{onboarded_at}-#{attempt}"
  end

  def build_rotp_id
    sprintf(
      "RoTP-%<year>s%<l1>s%<num>s%<l2>s%<l3>s%<month>s",
      year: year,
      l1: letter_one,
      num: number,
      l2: letter_two,
      l3: letter_three,
      month: month
    )
  end

  def digest
    @digest ||= Digest::SHA256.hexdigest(seed)
  end

  def extract_chunk(index)
    start = index * 8
    digest[start, 8].to_i(16)
  end

  def number
    chunk = extract_chunk(0)
    value = chunk % 10
    value.to_s
  end

  def letter_one
    letter_from_chunk(extract_chunk(1))
  end

  def letter_two
    letter_from_chunk(extract_chunk(3))
  end

  def letter_three
    letter_from_chunk(extract_chunk(4))
  end

  def letter_from_chunk(chunk)
    (65 + (chunk % 26)).chr
  end

  def year
    onboarded_at.strftime("%y")
  end

  def month
    onboarded_at.strftime("%m")
  end
end
