class SchedulesController < ApiController
  def show
    tradesman_id = params[:id]
    schedules = Schedule.where(tradesman_id: tradesman_id)
    
    # Optional date filter
    if params[:date].present?
      schedules = schedules.where(date: params[:date])
    end
    
    # Optional date range filter
    if params[:start_date].present? && params[:end_date].present?
      schedules = schedules.where(date: params[:start_date]..params[:end_date])
    end
    
    schedules = schedules.order(:date, :start_time)
    
    render json: schedules.map { |s|
      {
        schedule_id: s.id,
        tradesman_id: s.tradesman_id,
        date: s.date,
        start_time: s.start_time,
        end_time: s.end_time,
        status: s.status,
        created_at: s.created_at,
        updated_at: s.updated_at
      }
    }
  end
  
  def create
    schedule_params = params.permit(:tradesman_id, :date, :start_time, :end_time, :status).to_h.symbolize_keys
    
    # Validate required fields
    if schedule_params[:tradesman_id].blank? || schedule_params[:date].blank? || 
       schedule_params[:start_time].blank? || schedule_params[:end_time].blank?
      return render_error("tradesman_id, date, start_time, and end_time are required", :bad_request)
    end
    
    # Set default status if not provided
    schedule_params[:status] ||= 'available'
    
    schedule = Schedule.new(schedule_params)
    
    if schedule.save
      render json: {
        schedule_id: schedule.id,
        tradesman_id: schedule.tradesman_id,
        date: schedule.date,
        start_time: schedule.start_time,
        end_time: schedule.end_time,
        status: schedule.status
      }, status: :created
    else
      render_error("Failed to create schedule: #{schedule.errors.full_messages.join(', ')}")
    end
  end
  
  def update
    schedule = Schedule.find_by(id: params[:id])
    
    if schedule.nil?
      render_error("Schedule not found", :not_found)
    else
      schedule_params = params.permit(:date, :start_time, :end_time, :status).to_h.symbolize_keys
      
      if schedule.update(schedule_params)
        render json: {
          schedule_id: schedule.id,
          tradesman_id: schedule.tradesman_id,
          date: schedule.date,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          status: schedule.status
        }
      else
        render_error("Failed to update schedule: #{schedule.errors.full_messages.join(', ')}")
      end
    end
  end
  
  def destroy
    schedule = Schedule.find_by(id: params[:id])
    
    if schedule.nil?
      render_error("Schedule not found", :not_found)
    else
      schedule.destroy
      render json: { message: "Schedule deleted successfully" }
    end
  end
  
  def bulk_create
    tradesman_id = params[:tradesman_id]
    return render_error("tradesman_id is required", :bad_request) unless tradesman_id
    
    schedules_data = params[:schedules] || []
    return render_error("schedules array is required", :bad_request) if schedules_data.empty?
    
    created_schedules = []
    errors = []
    
    schedules_data.each_with_index do |schedule_data, index|
      schedule_params = schedule_data.permit(:date, :start_time, :end_time, :status).to_h.symbolize_keys
      schedule_params[:tradesman_id] = tradesman_id
      schedule_params[:status] ||= 'available'
      
      schedule = Schedule.new(schedule_params)
      
      if schedule.save
        created_schedules << {
          schedule_id: schedule.id,
          date: schedule.date,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          status: schedule.status
        }
      else
        errors << { index: index, errors: schedule.errors.full_messages }
      end
    end
    
    if errors.empty?
      render json: {
        message: "Successfully created #{created_schedules.count} schedule(s)",
        schedules: created_schedules
      }, status: :created
    else
      render json: {
        message: "Created #{created_schedules.count} schedule(s), #{errors.count} failed",
        schedules: created_schedules,
        errors: errors
      }, status: :partial_content
    end
  end
end

