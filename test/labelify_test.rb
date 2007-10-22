require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'

require 'active_support'
require 'action_view/helpers/tag_helper'
require 'action_view/helpers/form_helper'
require 'action_view/helpers/form_tag_helper'
require 'action_controller/assertions/selector_assertions'

require File.dirname(__FILE__) + '/../lib/labelify'

class LabelifyTest < Test::Unit::TestCase
  include Labelify
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionController::Assertions::SelectorAssertions
  
  def setup
    @person = flexmock('person', :name => 'Tester')
    
    @error_on_name = flexmock do |mock|
      mock.should_receive(:on).with(:base).and_return(nil)
      mock.should_receive(:on).with(:name).and_return(['name error'])
    end
    @person_with_error_on_name = flexmock('person_with_error_on_name', :name => '', :errors => @error_on_name)

    @multiple_errors_on_name_and_base = flexmock do |mock|
      mock.should_receive(:on).with(:base).and_return(['base error1', 'base error2'])
      mock.should_receive(:on).with(:name).and_return(['name error1', 'name error2'])
    end
    @person_with_multiple_errors_on_name_and_base = flexmock('person_with_multiple_errors_on_name_and_base', :name => '', :errors => @multiple_errors_on_name_and_base)
    
    @error_on_base = flexmock do |mock|
      mock.should_receive(:on).with(:base).and_return(['base error'])
      mock.should_receive(:on).with(:name).and_return(nil)
    end
    @person_with_error_on_base = flexmock('person_with_error_on_base', :name => '', :errors => @error_on_base)

    @person_with_human_field_name = flexmock('person_with_human_field_name',
      :name => '', :class => flexmock(
        :columns_hash => {"name" => flexmock(:human_name => 'human name')}
      )
    )
    
    @address = flexmock('address', :city => 'Amsterdam')
    @person_with_address = flexmock('person_with_address', :name => 'Tester', :address => @address)
    
    @erbout = ''
  end
  
  def test_should_render_empty_form
    labelled_form_for(:person) {}
    assert_equal %q{<form method="post"></form>}, @erbout
  end
  
  def test_should_render_form_with_method_get
    labelled_form_for(:person, :html => {:method => 'get'}) {}
    assert_equal %q{<form method="get"></form>}, @erbout
  end
  
  def test_should_render_form_with_url
    labelled_form_for(:person, :url => 'test_url') {}
    assert_select 'form[method="post"][action="test_url"]'
  end
  
  def test_should_render_form_with_name_field
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name)
    end
    
    assert_select 'label[for="person_name"]'
    assert_select 'input#person_name[type="text"]'
    
    element = css_select('#person_name')
    assert_equal 'person[name]', element.first["name"]
    assert_equal @person.name, element.first["value"]
  end
  
  def test_should_not_render_label_with_false
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name, :label => false)
    end
    
    assert_select 'label[for="person_name"]', 0
  end
  
  def test_should_not_render_label_with_no_label
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name, :no_label => true)
    end
    
    assert_select 'label[for="person_name"]', 0
  end
  
  def test_should_not_render_label_with_no_label_for
    labelled_form_for(:person, :no_label_for => :text_field) do |f|
      @erbout << f.text_field(:name)
    end
    
    assert_select 'label[for="person_name"]', 0
  end
  
  def test_should_render_alternative_label
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name, :label => 'alt')
    end
    
    assert_select 'label[for="person_name"]', 'alt'
  end
  
  def test_should_render_class_for_field
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name, :class => 'required')
    end
    
    assert_select 'input#person_name.required'
  end
  
  def test_should_render_input_submit_with_class_submit
    labelled_form_for(:person) do |f|
      @erbout << f.submit('save', :class => 'button')
    end
    
    assert_select 'input[type="submit"].submit.button'
    assert_equal 'save', css_select('input[type="submit"].submit.button').first["value"]
  end
  
  def test_should_render_button_of_type_submit
    labelled_form_for(:person) do |f|
      @erbout << f.submit('save', :type => :button, :class => 'save-button')
    end
    
    assert_select 'button[type="submit"].submit.save-button', 'save'
  end
  
  def test_should_render_label
    labelled_form_for(:person) do |f|
      @erbout << f.label(:name) 
    end
    
    assert_select 'label[for="person_name"] span.field_name', 'Name'
  end
  
  def test_should_render_label_with_value
    labelled_form_for(:person) do |f|
      @erbout << f.label(:name, :label_value => 'test label')
    end
    
    assert_select 'label[for="person_name"] span.field_name', 'test label'
  end
  
  def test_should_render_label_with_human_name
    labelled_form_for(:person, @person_with_human_field_name) do |f|
      @erbout << f.label(:name)
    end

    assert_select 'label[for="person_name"] span.field_name', 'human name'
  end
  
  def test_should_not_render_error_message
    labelled_form_for(:person) do |f|
      @erbout << f.text_field(:name)
    end

    assert_select 'label[for="person_name"] .error_message', 0
  end
  
  def test_should_render_error_message_for_name
    labelled_form_for(:person, @person_with_error_on_name) do |f|
      @erbout << f.text_field(:name)
    end

    assert_select 'label[for="person_name"] .error_message', 'name error'
  end
  
  def test_should_render_multiple_errors_messages
    labelled_form_for(:person, @person_with_multiple_errors_on_name_and_base) do |f|
      @erbout << f.text_field(:name)
    end

    assert_select '.error_message', 'base error1 and base error2'
    assert_select 'label[for="person_name"] .error_message', 'name error1 and name error2'
  end
  
  def test_should_render_error_message_for_base
    labelled_form_for(:person_with_error_on_base) do |f|
      @erbout << f.text_field(:name)
    end

    assert_select '.error_message', 'base error'
  end

  def test_should_render_associate_fields
    labelled_form_for(:person, @person_with_address) do |f|
      f.with_association(:address) do |a|
        @erbout << a.text_field(:city)
      end
    end
    
    assert_select 'label[for="address_city"]', 1
    assert_equal @address.city, css_select('input[type="text"]').first['value']
  end
  
  def test_should_render_object_fields
    labelled_form_for(:person, @person_with_address) do |f|
      f.with_object(:address) do |a|
        @erbout << a.text_field(:city)
      end
    end

    assert_select 'label[for="address_city"]', 1
    assert_equal @address.city, css_select('input[type="text"]').first['value']
  end
  
  def test_should_allow_helpers_with_block
    labelled_form_for(:person, @person) do |f|
      @erbout << f.make_span_for_block(:name) do
        'body'
      end
    end
    
    assert_select 'form span.span_for_block', 'body'
  end
  
  def test_should_allow_my_text_field_helper
    labelled_form_for(:person) do |f|
      @erbout << f.my_text_field(:name)
    end

    assert_select 'label[for="person_name"]', 1
    assert_select 'input[type="my-text"]', 1
    assert_equal @person.name, css_select('input').first['value']
  end
  
  def test_should_be_able_to_use_as_default_form_builder
    before = ActionView::Base.default_form_builder
    ActionView::Base.default_form_builder = Labelify::FormBuilder
    
    begin
      form_for(:person) do |f|
        @erbout << f.text_field(:name)
      end

      assert_select 'label[for="person_name"]', 1
      assert_select 'input#person_name', 1
    end
    
    ActionView::Base.default_form_builder = before
  end
  
private
  def make_span_for_block(object, name, options = {})
    content_tag(:span, yield, :class => 'span_for_block')
  end
  
  def my_text_field(object, method, options)
    tag(:input, :value => options[:object].send(method), :type => 'my-text')
  end
  
  def url_for(arg)
    arg.empty? ? nil : arg
  end
  
  def concat(text, binding)
    raise unless binding
    @erbout << text
  end
  
  def response_from_page_or_rjs
    HTML::Document.new(@erbout).root
  end
end