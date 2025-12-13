require "test_helper"
require "securerandom"

class AppointmentTest < ActiveSupport::TestCase
  def required_attrs_for(klass)
    attrs = {}

    klass.columns.each do |c|
      next if %w[id created_at updated_at].include?(c.name)
      next if c.null
      next unless c.default.nil?

      attrs[c.name] =
        case c.type
        when :string then "#{c.name}-#{SecureRandom.hex(6)}"
        when :text then "text-#{SecureRandom.hex(6)}"
        when :integer, :bigint then 1
        when :float, :decimal then 1.0
        when :boolean then true
        when :date then Date.today
        when :datetime, :time then Time.current
        else
          "#{c.name}-#{SecureRandom.hex(6)}"
        end
    end

    if klass.column_names.include?("password_digest")
      attrs.delete("password_digest")
      attrs["password"] = "password123"
      attrs["password_confirmation"] = "password123"
    end

    attrs
  end

  def create_with_required_fk!(klass, seen = {})
    key = klass.name
    return klass.create!(required_attrs_for(klass)) if seen[key]
    seen[key] = true

    attrs = required_attrs_for(klass)

    klass.reflect_on_all_associations.select { |a| a.macro == :belongs_to }.each do |assoc|
      fk = assoc.foreign_key.to_s
      next unless klass.column_names.include?(fk)

      parent = create_with_required_fk!(assoc.klass, seen)
      attrs[fk] = parent.id
    end

    klass.create!(attrs)
  end

  test "appointments table exists" do
    assert Appointment.table_exists?
  end

  test "can query appointments without error" do
    assert_nothing_raised do
      Appointment.limit(5).to_a
    end
  end

  test "can create and destroy an appointment record" do
    appt = nil

    assert_difference("Appointment.count", +1) do
      appt = create_with_required_fk!(Appointment)
    end

    assert Appointment.exists?(appt.id)

    assert_difference("Appointment.count", -1) do
      appt.destroy!
    end

    assert_not Appointment.exists?(appt.id)
  end
end
