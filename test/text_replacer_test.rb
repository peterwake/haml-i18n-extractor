require 'test_helper'

module Haml
  class TextReplacerTest < MiniTest::Unit::TestCase

    def test_it_initializes_with_the_line_it_is_going_to_replace_and_the_match_to_replace
      Haml::I18n::Extractor::TextReplacer.new("this is whatever", "this is whatever", :plain, "/path/to/doesntmatter.haml")
    end

    def test_but_it_raises_if_passed_a_wrong_line_type
      begin
        replacer = Haml::I18n::Extractor::TextReplacer.new("regular text", "regular text", :this_is_not_defined, "/path/to/doesntmatter.haml")
        assert false, 'should raise'
      rescue Haml::I18n::Extractor::NotDefinedLineType
        assert true, 'raised NotDefinedLineType'
      end
    end

    def test_it_wont_replace_if_whole_line_is_a_expression
      replacer = Haml::I18n::Extractor::TextReplacer.new('#{whole_line_expression}',
                                                         '#{whole_line_expression}',
                                                         :plain, '/path/to/doesntmatter.haml')
      assert_equal replacer.result.should_be_replaced, false
    end

    def test_it_wont_replace_if_whole_line_in_tag_is_a_expression
      replacer = Haml::I18n::Extractor::TextReplacer.new('%span #{whole_line_expression}',
                                                         '#{whole_line_expression}',
                                                         :tag, '/path/to/doesntmatter.haml')
      assert_equal replacer.result.should_be_replaced, false
    end

    def test_it_wont_replace_if_whole_line_in_tag_is_a_expression
      replacer = Haml::I18n::Extractor::TextReplacer.new('#{whole_line_expression}',
                                                         "\"\#{whole_line_expression}\"",
                                                         :script, '/path/to/doesntmatter.haml')
      assert_equal replacer.result.should_be_replaced, false
    end

    def test_it_wont_replace_attributes_if_replacement_place_is_content
      replacer = Haml::I18n::Extractor::TextReplacer.new('%span{title: "Height, cm"} Height',
                                                         'Height',
                                                         :tag, '/path/to/doesntmatter.haml', {}, place: :content)
      assert_equal({:modified_line => '%span{title: "Height, cm"}= t(\'.height\')',
                    :t_name => "height", :replaced_text => "Height", :path => "/path/to/doesntmatter.haml"},
                   replacer.replace_hash)
    end

    def test_it_can_replace_title_attribute
      replacer = Haml::I18n::Extractor::TextReplacer.new('%span{title: "Height, cm"}= "Height, cm"',
                                                         'Height, cm',
                                                         :tag, '/path/to/doesntmatter.haml', {},
                                                         place: :attribute, attribute_name: :title)
      assert_equal({:modified_line => '%span{title: t(\'.height_cm\')}= "Height, cm"',
                    :t_name => "height_cm", :replaced_text => "Height, cm", :path => "/path/to/doesntmatter.haml"},
                   replacer.replace_hash)
    end

    # some text replacement examples
    def test_it_can_replace_the_body_of_haml_with_t_characters
      replacer = Haml::I18n::Extractor::TextReplacer.new("this is whatever", "this is whatever", :plain, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash, {:modified_line => "= t('.this_is_whatever')",
                                           :t_name => "this_is_whatever", :replaced_text => "this is whatever", :path => "/path/to/doesntmatter.haml"}
    end

    def test_it_can_replace_the_body_of_haml_with_t_characters_example
      replacer = Haml::I18n::Extractor::TextReplacer.new("%span Admin Dashboard", "Admin Dashboard", :tag, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash, {:modified_line => "%span= t('.admin_dashboard')",
                                           :t_name => "admin_dashboard", :replaced_text => "Admin Dashboard", :path => "/path/to/doesntmatter.haml"}
    end

    def test_it_wont_replace_already_replaced_t_characters_if_they_are_not_ruby_evaled
      replacer = Haml::I18n::Extractor::TextReplacer.new("%span t('.admin_dashboard')", "t('.admin_dashboard')", :tag, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash, {:modified_line => "%span t('.admin_dashboard')",
                                           :t_name => "admin_dashboard", :replaced_text => "t('.admin_dashboard')", :path => "/path/to/doesntmatter.haml"}
    end

    def test_it_wont_replace_already_replaced_t_characters_that_are_ruby_evaled
      replacer = Haml::I18n::Extractor::TextReplacer.new("%span= t('.admin_dashboard')", "t('.admin_dashboard')", :script, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash, {:modified_line => "%span= t('.admin_dashboard')",
                                           :t_name => "admin_dashboard", :replaced_text => "t('.admin_dashboard')", :path => "/path/to/doesntmatter.haml"}
    end

    # keyname restrictions
    def test_it_limits_the_characters_of_the_t_namespace_it_provides_to_limit_key_name
      replacer = Haml::I18n::Extractor::TextReplacer.new("this is whatever" * 80, "this is whatever" * 80, :plain, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash[:modified_line].size, Haml::I18n::Extractor::Helpers::StringHelpers::LIMIT_KEY_NAME + 8 # = t('.')
    end

    def test_it_does_not_allow_weird_characters_in_the_keyname
      weird_line = "t<>hi:s = (is \"' `ch@ract.er ~ ma?dne{}s[]s!"
      replacer = Haml::I18n::Extractor::TextReplacer.new(weird_line, weird_line, :plain, "/path/to/doesntmatter.haml")
      assert_equal replacer.replace_hash, {:modified_line => "= t('.this_is_chracter_madness')",
                                           :t_name => "this_is_chracter_madness", :replaced_text => weird_line, :path => "/path/to/doesntmatter.haml"}
    end

  end
end
