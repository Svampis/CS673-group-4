class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_default_format
  before_action :parse_json_body, if: -> { request.post? || request.put? }
  
  private
  
  def set_default_format
    request.format = :json
  end
  
  def parse_json_body
    return unless request.content_type&.include?('application/json')
    
    begin
      body = request.body.read
      request.body.rewind
      @parsed_body = JSON.parse(body) if body.present?
      params.merge!(@parsed_body) if @parsed_body.is_a?(Hash)
    rescue JSON::ParserError
      # Ignore JSON parse errors, let params handle it
    end
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end

