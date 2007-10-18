# Helper module for making labelled form.
module LabelledFormHelper
  # Create a form for a given model object.  Labels and errors are automatically included.
  # The +form_builder+ is a LabelledFormBuilder, which handles all standard form helper
  # methods.  All the field and select sections are decorated with a label, except for
  # +hidden_field+.  The +no_label_for+ option can be provide to suppress labels
  # on other methods as well by giving a string or regex.
  #
  # Example:
  #   <% labelled_form_for :person, @person, :url => { :action => "update" } do |f| %>
  #     <%= f.text_field :first_name %>
  #     <%= f.text_field :last_name %>
  #     <%= f.text_area :biography %>
  #     <%= f.check_box :admin %>
  #   <% end %>
  def labelled_form_for(object_name, *args, &proc) # :yields: form_builder
    options = Hash === args.last ? args.pop : {}
    options = options.merge(:builder => LabelledFormBuilder)

    object = *args
    object = instance_variable_get("@#{object_name}") unless object
    if object.respond_to?(:errors) && object.errors.on(:base)
      messages = object.errors.on(:base)
      messages = messages.to_sentence if messages.respond_to? :to_sentence
      concat(%Q@<span class="error_message">#{h(messages)}</span>@, proc.binding)
    end

    form_for(object_name, object, options, &proc)
  end

  # Form build for +form_for+ method which includes labels with almost all form fields.  All
  # unknown method calls are passed through to the underlying template hoping to hit a form helper
  # method.
  class LabelledFormBuilder
    def initialize(object_name, object, template, options, proc) # :nodoc:
      @object_name, @object, @template, @options, @proc = object_name, object, template, options, proc        
    end
    
    # Pass methods to underlying template hoping to hit some homegrown form helper method.
    # Including an option with the name +label+ will have the following effect:
    # [+true+]           include a label (the default).
    # [+false+]          exclude the label.
    # [any other value]  the label to use.
    def method_missing(selector, method, *args, &block)
      args << {} unless args.last.kind_of?(Hash)
      options = args.last
      options.merge!(:object => @object)
      r = ''

      unless selector == :hidden_field || @options[:no_label_for] && @options[:no_label_for] == selector
        label_value = options.delete(:label)
        if (label_value.nil? || label_value != false) && !options.delete(:no_label)
          label_options = options.include?(:class) ? {:class => options[:class]} : {}
          label_options[:label_value] = label_value unless label_value.kind_of? TrueClass
          r << label(method, label_options)
        end
      end

      r << @template.send(selector, @object_name, method, *args, &block)
    end

    # Returns a submit button.  This button has style class +submit+.  If given a +type+ option +button+
    # a button element will be rendered instead of input element.  This button element will contain a
    # span element with the given value.
    # [+value+]   the text on the button
    # [+options+] HTML attributes
    def submit(value = 'Submit', options = {})
      if options[:class]
        options[:class] += ' submit'
      else
        options[:class] = 'submit'
      end

      if options[:type].to_s == 'button'
        %Q@
          <button #{options2attributes(options.merge(:type => 'submit'))}>
            <span>#{h value}</span>
          </button>
        @
      else
        %Q@<input #{options2attributes({:type => 'submit', :value => t(value)}.merge(options))}/>@
      end
    end

    # Returns a label for a given attribute.  The +for+ attribute point to the same
    # +id+ attribute generated by the form helper tags.
    # [+method_name+] model object attribute name
    # [+options+]     HTML attributes
    def label(method_name, options = {})
      column = @object.class.respond_to?(:columns_hash) && @object.class.columns_hash[method_name.to_s]
      
      label_value = options.delete(:label_value)      
      label_value ||= column ? column.human_name : method_name.to_s.humanize
      %Q@
        <label for="#{@object_name}_#{method_name}" #{options2attributes(options)}>
          <span class="field_name">#{t label_value}</span>
          #{error_messages(method_name)}
        </label>
      @
    end

    # Error messages for given field, concatenated with +to_sentence+.
    def error_messages(method_name)
      if @object.respond_to?(:errors) && @object.errors.on(method_name)
        messages = @object.errors.on(method_name)
        messages = messages.kind_of?(Array) ? messages.map{|m|t(m)}.to_sentence : t(messages)
        %Q@<span class="error_message">#{messages}</span>@
      end
    end
    
    # Scope a piece of the form to an associated object.
    def with_association(association, &proc) # :yields:
      with_object(association, @object ? @object.send(association) : nil, &proc)
    end
    
    # Scope a piece of the form to another object.
    def with_object(object_name, object = nil)
      object ||= instance_variable_get("@#{object_name}")
      old_object, old_object_name = @object, @object_name
      @object_name, @object = object_name, object
      yield self
    ensure
      @object, @object_name = old_object, old_object_name
    end      
    
  private
    def h(*args); CGI::escapeHTML(*args); end
    
    def options2attributes(options)
      options.map { |k,v| "#{k}=\"#{h v.to_s}\"" }.join(' ')
    end
    
    def t(text)
      Object.const_defined?(:Localization) ? Localization._(text) : text
    end
  end
end