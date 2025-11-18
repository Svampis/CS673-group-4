class SchedulesController < ApiController
  def show
    tradesman_id = params[:id]
    schedules = Schedule.find_by_tradesman_id(tradesman_id)
    
    render json: schedules.map { |s|
      {
        schedule_id: s.schedule_id,
        date: s.date,
        start_time: s.start_time,
        end_time: s.end_time,
        status: s.status
      }
    }
  end
end

