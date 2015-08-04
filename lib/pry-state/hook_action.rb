require 'pry-state/printer'

class HookAction
  IGNORABLE_LOCAL_VARS = [:__, :_, :_ex_, :_pry_, :_out_, :_in_, :_dir_, :_file_]

  CONTROLLER_INSTANCE_VARIABLES = [:@_request, :@_response, :@_routes]
  RSPEC_INSTANCE_VARIABLES = [:@__inspect_output, :@__memoized]
  IGNORABLE_INSTANCE_VARS = CONTROLLER_INSTANCE_VARIABLES + RSPEC_INSTANCE_VARIABLES

  def initialize binding, pry
    @binding, @pry = binding, pry
  end

  def act
    (binding.eval('instance_variables') - IGNORABLE_INSTANCE_VARS).each do |var|
      eval_and_print var, var_color: 'green'
    end

    (binding.eval('local_variables') - IGNORABLE_LOCAL_VARS).each do |var|
      eval_and_print var, var_color: 'cyan'
    end
  end

  private
  attr_reader :binding, :pry

  def eval_and_print var, var_color: 'green', value_color: 'white'
    value = binding.eval(var.to_s)
    if value_changed? var, value
      var_color = "bright_#{var_color}"; value_color = 'bright_yellow'
    end
    Printer.trunc_and_print var, value, var_color, value_color
    stick_value! var, value # to refer the value in next
  end

  def value_changed? var, value
    prev_state[var] and prev_state[var] != value
  end

  def stick_value! var, value
    prev_state[var] = value
  end

  def prev_state
    # init a hash to store state to be used in next session
    # in finding diff
    pry.config.extra_sticky_locals[:pry_state_prev] ||= {}
  end

end
