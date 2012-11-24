# -*- encoding: utf-8 -*-
require File.expand_path('../../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes.rb', __FILE__)

# TODO: Add missing String#[]= specs:
#   String#[re, idx] = obj

ruby_version_is ""..."1.9" do
  describe "String#[]= with Fixnum index" do
    it "sets the code of the character at idx to char modulo 256" do
      a = "hello"
      a[0] = ?b
      a.should == "bello"
      a[-1] = ?a
      a.should == "bella"
      a[-1] = 0
      a.should == "bell\x00"
      a[-5] = 0
      a.should == "\x00ell\x00"

      a = "x"
      a[0] = ?y
      a.should == "y"
      a[-1] = ?z
      a.should == "z"

      a[0] = 255
      a[0].should == 255
      a[0] = 256
      a[0].should == 0
      a[0] = 256 * 3 + 42
      a[0].should == 42
      a[0] = -214
      a[0].should == 42
    end

    it "sets the code to char % 256" do
      str = "Hello"

      str[0] = ?a + 256 * 3
      str[0].should == ?a
      str[0] = -200
      str[0].should == 56
    end

    it "raises an IndexError without changing self if idx is outside of self" do
      a = "hello"

      lambda { a[20] = ?a }.should raise_error(IndexError)
      a.should == "hello"

      lambda { a[-20] = ?a }.should raise_error(IndexError)
      a.should == "hello"

      lambda { ""[0] = ?a  }.should raise_error(IndexError)
      lambda { ""[-1] = ?a }.should raise_error(IndexError)
    end

    it "calls to_int on index" do
      str = "hello"
      str[0.5] = ?c
      str.should == "cello"

      obj = mock('-1')
      obj.should_receive(:to_int).and_return(-1)
      str[obj] = ?y
      str.should == "celly"
    end

    it "doesn't call to_int on char" do
      obj = mock('x')
      obj.should_not_receive(:to_int)
      lambda { "hi"[0] = obj }.should raise_error(TypeError)
    end

    it "raises a TypeError when self is frozen" do
      a = "hello"
      a.freeze

      lambda { a[0] = ?b }.should raise_error(TypeError)
    end

  end
end

describe "String#[]= with Fixnum index" do
  it "replaces the char at idx with other_str" do
    a = "hello"
    a[0] = "bam"
    a.should == "bamello"
    a[-2] = ""
    a.should == "bamelo"
  end

  it "taints self if other_str is tainted" do
    a = "hello"
    a[0] = "".taint
    a.tainted?.should == true

    a = "hello"
    a[0] = "x".taint
    a.tainted?.should == true
  end

  it "raises an IndexError without changing self if idx is outside of self" do
    str = "hello"

    lambda { str[20] = "bam" }.should raise_error(IndexError)
    str.should == "hello"

    lambda { str[-20] = "bam" }.should raise_error(IndexError)
    str.should == "hello"

    lambda { ""[-1] = "bam" }.should raise_error(IndexError)
  end

  ruby_version_is ""..."1.9" do
    it "raises an IndexError when setting the zero'th element of an empty String" do
      lambda { ""[0] = "bam"  }.should raise_error(IndexError)
    end
  end

  # Behaviour verfieid correct by matz in
  # http://redmine.ruby-lang.org/issues/show/1750
  ruby_version_is "1.9" do
    it "allows assignment to the zero'th element of an empty String" do
      str = ""
      str[0] = "bam"
      str.should == "bam"
    end
  end

  it "raises IndexError if the string index doesn't match a position in the string" do
    str = "hello"
    lambda { str['y'] = "bam" }.should raise_error(IndexError)
    str.should == "hello"
  end

  ruby_version_is ""..."1.9" do
    it "raises a TypeError when self is frozen" do
      a = "hello"
      a.freeze

      lambda { a[0] = "bam" }.should raise_error(TypeError)
    end
  end

  ruby_version_is "1.9" do
    it "raises a RuntimeError when self is frozen" do
      a = "hello"
      a.freeze

      lambda { a[0] = "bam" }.should raise_error(RuntimeError)
    end
  end

  it "calls to_int on index" do
    str = "hello"
    str[0.5] = "hi "
    str.should == "hi ello"

    obj = mock('-1')
    obj.should_receive(:to_int).and_return(-1)
    str[obj] = "!"
    str.should == "hi ell!"
  end

  it "calls #to_str to convert other to a String" do
    other_str = mock('-test-')
    other_str.should_receive(:to_str).and_return("-test-")

    a = "abc"
    a[1] = other_str
    a.should == "a-test-c"
  end

  it "raises a TypeError if other_str can't be converted to a String" do
    lambda { "test"[1] = []        }.should raise_error(TypeError)
    lambda { "test"[1] = mock('x') }.should raise_error(TypeError)
    lambda { "test"[1] = nil       }.should raise_error(TypeError)
  end

  with_feature :encoding do
    it "raises a TypeError if passed a Fixnum replacement" do
      lambda { "abc"[1] = 65 }.should raise_error(TypeError)
    end

    it "raises an IndexError if the index is greater than character size" do
      lambda { "あれ"[4] = "a" }.should raise_error(IndexError)
    end

    it "calls #to_int to convert the index" do
      index = mock("string element set")
      index.should_receive(:to_int).and_return(1)

      str = "あれ"
      str[index] = "a"
      str.should == "あa"
    end

    it "raises a TypeError if #to_int does not return an Fixnum" do
      index = mock("string element set")
      index.should_receive(:to_int).and_return('1')

      lambda { "abc"[index] = "d" }.should raise_error(TypeError)
    end

    it "raises an IndexError if #to_int returns a value out of range" do
      index = mock("string element set")
      index.should_receive(:to_int).and_return(4)

      lambda { "ab"[index] = "c" }.should raise_error(IndexError)
    end

    it "replaces a character with a multibyte character" do
      str = "ありがとu"
      str[4] = "う"
      str.should == "ありがとう"
    end

    it "replaces a multibyte character with a character" do
      str = "ありがとう"
      str[4] = "u"
      str.should == "ありがとu"
    end

    it "replaces a multibyte character with a multibyte character" do
      str = "ありがとお"
      str[4] = "う"
      str.should == "ありがとう"
    end
  end
end

describe "String#[]= with String index" do
  it "replaces fewer characters with more characters" do
    str = "abcde"
    str["cd"] = "ghi"
    str.should == "abghie"
  end

  it "replaces more characters with fewer characters" do
    str = "abcde"
    str["bcd"] = "f"
    str.should == "afe"
  end

  it "replaces characters with no characters" do
    str = "abcde"
    str["cd"] = ""
    str.should == "abe"
  end

  it "raises an IndexError if the search String is not found" do
    str = "abcde"
    lambda { str["g"] = "h" }.should raise_error(IndexError)
  end

  with_feature :encoding do
    it "replaces characters with a multibyte character" do
      str = "ありgaとう"
      str["ga"] = "が"
      str.should == "ありがとう"
    end

    it "replaces multibyte characters with characters" do
      str = "ありがとう"
      str["が"] = "ga"
      str.should == "ありgaとう"
    end

    it "replaces multibyte characters with multibyte characters" do
      str = "ありがとう"
      str["が"] = "か"
      str.should == "ありかとう"
    end
  end
end

describe "String#[]= with a Regexp index" do
  it "replaces the matched text with the rhs" do
    str = "hello"
    str[/lo/] = "x"
    str.should == "helx"
  end

  it "raises IndexError if the regexp index doesn't match a position in the string" do
    str = "hello"
    lambda { str[/y/] = "bam" }.should raise_error(IndexError)
    str.should == "hello"
  end

  describe "with 3 arguments" do
    it "uses the 2nd of 3 arguments as which capture should be replaced" do
      str = "aaa bbb ccc"
      str[/a (bbb) c/, 1] = "ddd"
      str.should == "aaa ddd ccc"
    end

    it "allows the specified capture to be negative and count from the end" do
      str = "abcd"
      str[/(a)(b)(c)(d)/, -2] = "e"
      str.should == "abed"
    end

    it "raises IndexError if the specified capture isn't available" do
      str = "aaa bbb ccc"
      lambda { str[/a (bbb) c/,  2] = "ddd" }.should raise_error(IndexError)
      lambda { str[/a (bbb) c/, -2] = "ddd" }.should raise_error(IndexError)
    end
  end

  with_feature :encoding do
    it "replaces characters with a multibyte character" do
      str = "ありgaとう"
      str[/ga/] = "が"
      str.should == "ありがとう"
    end

    it "replaces multibyte characters with characters" do
      str = "ありがとう"
      str[/が/] = "ga"
      str.should == "ありgaとう"
    end

    it "replaces multibyte characters with multibyte characters" do
      str = "ありがとう"
      str[/が/] = "か"
      str.should == "ありかとう"
    end
  end
end

describe "String#[]= with a Range index" do
  it "replaces the contents with a shorter String" do
    str = "abcde"
    str[0..-1] = "hg"
    str.should == "hg"
  end

  it "replaces the contents with a longer String" do
    str = "abc"
    str[0...4] = "uvwxyz"
    str.should == "uvwxyz"
  end

  it "replaces a partial string" do
    str = "abcde"
    str[1..3] = "B"
    str.should == "aBe"
  end

  with_feature :encoding do
    it "replaces characters with a multibyte character" do
      str = "ありgaとう"
      str[2..3] = "が"
      str.should == "ありがとう"
    end

    it "replaces multibyte characters with characters" do
      str = "ありがとう"
      str[2...3] = "ga"
      str.should == "ありgaとう"
    end

    it "replaces multibyte characters with multibyte characters" do
      str = "ありがとう"
      str[2..2] = "か"
      str.should == "ありかとう"
    end

    it "deletes a multibyte character" do
      str = "ありとう"
      str[2..3] = ""
      str.should == "あり"
    end

    it "inserts a multibyte character" do
      str = "ありとう"
      str[2...2] = "が"
      str.should == "ありがとう"
    end
  end
end

describe "String#[]= with Fixnum index, count" do
  it "starts at idx and overwrites count characters before inserting the rest of other_str" do
    a = "hello"
    a[0, 2] = "xx"
    a.should == "xxllo"
    a = "hello"
    a[0, 2] = "jello"
    a.should == "jellollo"
  end

  it "counts negative idx values from end of the string" do
    a = "hello"
    a[-1, 0] = "bob"
    a.should == "hellbobo"
    a = "hello"
    a[-5, 0] = "bob"
    a.should == "bobhello"
  end

  it "overwrites and deletes characters if count is more than the length of other_str" do
    a = "hello"
    a[0, 4] = "x"
    a.should == "xo"
    a = "hello"
    a[0, 5] = "x"
    a.should == "x"
  end

  it "deletes characters if other_str is an empty string" do
    a = "hello"
    a[0, 2] = ""
    a.should == "llo"
  end

  it "deletes characters up to the maximum length of the existing string" do
    a = "hello"
    a[0, 6] = "x"
    a.should == "x"
    a = "hello"
    a[0, 100] = ""
    a.should == ""
  end

  it "appends other_str to the end of the string if idx == the length of the string" do
    a = "hello"
    a[5, 0] = "bob"
    a.should == "hellobob"
  end

  it "taints self if other_str is tainted" do
    a = "hello"
    a[0, 0] = "".taint
    a.tainted?.should == true

    a = "hello"
    a[1, 4] = "x".taint
    a.tainted?.should == true
  end

  it "raises an IndexError if |idx| is greater than the length of the string" do
    lambda { "hello"[6, 0] = "bob"  }.should raise_error(IndexError)
    lambda { "hello"[-6, 0] = "bob" }.should raise_error(IndexError)
  end

  it "raises an IndexError if count < 0" do
    lambda { "hello"[0, -1] = "bob" }.should raise_error(IndexError)
    lambda { "hello"[1, -1] = "bob" }.should raise_error(IndexError)
  end

  it "raises a TypeError if other_str is a type other than String" do
    lambda { "hello"[0, 2] = nil  }.should raise_error(TypeError)
    lambda { "hello"[0, 2] = []   }.should raise_error(TypeError)
    lambda { "hello"[0, 2] = 33   }.should raise_error(TypeError)
  end

  with_feature :encoding do
    it "replaces characters with a multibyte character" do
      str = "ありgaとう"
      str[2, 2] = "が"
      str.should == "ありがとう"
    end

    it "replaces multibyte characters with characters" do
      str = "ありがとう"
      str[2, 1] = "ga"
      str.should == "ありgaとう"
    end

    it "replaces multibyte characters with multibyte characters" do
      str = "ありがとう"
      str[2, 1] = "か"
      str.should == "ありかとう"
    end

    it "deletes a multibyte character" do
      str = "ありとう"
      str[2, 2] = ""
      str.should == "あり"
    end

    it "inserts a multibyte character" do
      str = "ありとう"
      str[2, 0] = "が"
      str.should == "ありがとう"
    end

    it "raises an IndexError if the character index is out of range of a multibyte String" do
      lambda { "あれ"[3] = "り" }.should raise_error(IndexError)
    end
  end
end
