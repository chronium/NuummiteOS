struct Int
  alias Signed = Int8 | Int16 | Int32 | Int64
  alias Unsigned = UInt8 | UInt16 | UInt32 | UInt64
  alias Primitive = Signed | Unsigned

  private DIGITS_DOWNCASE = "0123456789abcdefghijklmnopqrstuvwxyz"
  private DIGITS_UPCASE = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  private DIGITS_BASE62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def chr
    unless 0 <= self <= Char::MAX_CODEPOINT
      raise "#{self} out of char range"
    end
    unsafe_chr
  end

  def ~
    self ^ -1
  end

  def /(other : Int)
    check_div_argument other
    div = unsafe_div other
    mod = unsafe_mod other
    div -= 1 if other > 0 ? mod < 0 : mod > 0
    div
  end

  def tdiv(other : Int)
    check_div_argument other
    unsafe_div other
  end

  def %(other : Int)
    if other == 0
      raise DivisionByZero.new
    elsif (self ^ other) >= 0
      self.unsafe_mod other
    else
      me = self.unsafe_mod other
      me == 0 ? me : me + other
    end
  end

  def remainder(other : Int)
    if other == 0
      raise DivisionByZero.new
    else
      unsafe_mod other
    end
  end

  def >>(count : Int)
    if count < 0
      self << count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shr count
    else
      self.class.zero
    end
  end

  def <<(count : Int)
    if count < 0
      self >> count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shl(count)
    else
      self.class.zero
    end
  end

  def **(exponent : Int) : self
    if exponent < 0
      raise ArgumentError.new "cannot raise an integer to a negative integer power"
    end
    result = self.class.new 1
    k = self
    while exponent > 0
      result *= k if exponent & 0b1 != 0
      k *= k
      exponent = exponent.unsafe_shr 1
    end
    result
  end

  def ===(char : Char)
    self === char.ord
  end

  def bit(bit)
    self >> bit & 1
  end

  def gcd(other : Int)
    self == 0 ? other.abs : (other % self).gcd self
  end

  def lcm(other : Int)
    (self * other).abs / gcd other
  end

  def abs
    self >= 0 ? self : -self
  end

  def times(&block : self ->)
    i = self ^ self
    while i < self
      yield i
      i += 1
    end
    self
  end

  def upto(to, &block : self ->)
    x = self
    while x <= to
      yield x
      x += 1
    end
    self
  end

  def downto(to, &block : self ->)
    x = self
    while x >= to
      yield x
      x -= 1
    end
    self
  end

  def to(to, &block : self ->)
    if self < to
      upto(to) { |i| yield i }
    elsif self > to
      downto(to) { |i| yield i }
    else
      yield self
    end
    self
  end

  def modulo(other)
    self % other
  end

  def divisible_by?(num : Int)
    self % num == 0
  end

  def even?
    divisible_by? 2
  end

  def odd?
    !even?
  end

  def succ
    self + 1
  end

  def pred
    self - 1
  end

  def ceil
    self
  end

  def floor
    self
  end

  def round
    self
  end

  def trunc
    self
  end

  def hash
    self
  end

  def to_s
    to_s 10
  end

  def to_s(io : IO)
    to_s 10, io
  end

  def to_s(base : Int, upcase : Bool = false)
    raise ArgumentError.new("Invalid base #{base}") unless 2 <= base <= 36 || base == 62
    raise ArgumentError.new("upcase must be false for base 62") if upcase && base == 62
    case self
    when 0
      return "0"
    when 1
      return "1"
    end
    internal_to_s(base, upcase) do |ptr, count|
      String.new ptr, count, count
    end
  end

  def to_s(base : Int, io : IO, upcase : Bool = false)
    raise ArgumentError.new("Invalid base #{base}") unless 2 <= base <= 36 || base == 62
    raise ArgumentError.new("upcase must be false for base 62") if upcase && base == 62
    case self
    when 0
      io << '0'
      return
    when 1
      io << '1'
      return
    end
    internal_to_s(base, upcase) do |ptr, count|
      # Only support ASCII characters
      io.write Slice.new ptr, count
    end
  end

  private def internal_to_s(base, upcase = false)
    chars = uninitialized UInt8[65]
    ptr_end = chars.to_unsafe + 64
    ptr = ptr_end
    num = self
    neg = num < 0
    digits = (base == 62 ? DIGITS_BASE62 : (upcase ? DIGITS_UPCASE : DIGITS_DOWNCASE)).to_unsafe
    while num != 0
      ptr -= 1
      ptr.value = digits[num.remainder(base).abs]
      num = num.tdiv base
    end
    if neg
      ptr -= 1
      ptr.value = '-'.ord.to_u8
    end
    count = (ptr_end - ptr).to_i32
    yield ptr, count
  end

  private def check_div_argument(other)
    if other == 0
      raise DivisionByZero.new
    end
    {% begin %}
      if self < 0 && self == {{@type}}::MIN && other == -1
        raise ArgumentError.new "overflow: {{@type}}::MIN / -1"
      end
    {% end %}
  end
end

struct Int8
  MIN = -128_i8
  MAX =  127_i8

  def self.new(value)
    value.to_i8
  end

  def -
    0_i8 - self
  end

  def clone
    self
  end
end

struct Int16
  MIN = -32768_i16
  MAX =  32767_i16

  def self.new(value)
    value.to_i16
  end

  def -
    0_i16 - self
  end

  def clone
    self
  end
end

struct Int32
  MIN = -2147483648_i32
  MAX =  2147483647_i32

  def self.new(value)
    value.to_i32
  end

  def -
    0 - self
  end

  def clone
    self
  end
end

struct Int64
  MIN = -9223372036854775808_i64
  MAX =  9223372036854775807_i64

  def self.new(value)
    value.to_i64
  end

  def -
    0_i64 - self
  end

  def clone
    self
  end
end

struct UInt8
  MIN = 0_u8
  MAX = 255_u8

  def self.new(value)
    value.to_u8
  end

  def abs
    self
  end

  def clone
    self
  end
end

struct UInt16
  MIN = 0_u16
  MAX = 65535_u16

  def self.new(value)
    value.to_u16
  end

  def abs
    self
  end

  def clone
    self
  end
end

struct UInt32
  MIN = 0_u32
  MAX = 4294967295_u32

  def self.new(value)
    value.to_u32
  end

  def abs
    self
  end

  def clone
    self
  end
end

struct UInt64
  MIN = 0_u64
  MAX = 18446744073709551615_u64

  def self.new(value)
    value.to_u64
  end

  def abs
    self
  end

  def clone
    self
  end
end
