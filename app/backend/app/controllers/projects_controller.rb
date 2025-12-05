class ProjectsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :user_projects, :project_details, :update, :publish]
  
  def new
    # Display the form for creating a new project
  end
  
  def index
    # List all projects for a user (homeowner/contractor)
  end
  
  def listing
    # List all open projects for tradesmen to bid on
  end
  
  def show
    # Show a specific project
  end
  
  def create
    # Get user_id from params (can be at top level)
    user_id = params[:user_id]
    
    if user_id.blank?
      return render json: { error: "User ID is required" }, status: :unauthorized
    end
    
    # Find user
    user = User.find_by(id: user_id)
    if user.nil?
      return render json: { error: "User not found" }, status: :not_found
    end
    
    # Handle params that may be nested under :project or at top level
    # Prefer nested params if they exist, otherwise use top-level
    source_params = params[:project].present? ? params[:project] : params
    
    # Create project
    project_params = source_params.permit(:title, :description, :trade_type, :budget, :location, :preferred_date).to_h.symbolize_keys
    
    # Convert budget to decimal if it's a string
    if project_params[:budget].is_a?(String)
      project_params[:budget] = project_params[:budget].to_f
    end
    
    # Normalize trade_type to lowercase
    if project_params[:trade_type].present?
      trade_type = project_params[:trade_type].downcase.strip
      # Normalize common variations
      trade_type = 'hvac worker' if trade_type == 'hvac'
      project_params[:trade_type] = trade_type
    end
    
    # Handle empty preferred_date
    project_params[:preferred_date] = nil if project_params[:preferred_date].blank?
    # Convert preferred_date to Date if it's a string
    if project_params[:preferred_date].is_a?(String) && project_params[:preferred_date].present?
      begin
        project_params[:preferred_date] = Date.parse(project_params[:preferred_date])
      rescue ArgumentError
        project_params[:preferred_date] = nil
      end
    end
    
    # Set homeowner_id or contractor_id based on user role
    if user.role == 'contractor'
      contractor = user.contractor
      if contractor.nil?
        return render json: { error: "Contractor profile not found" }, status: :not_found
      end
      project_params[:contractor_id] = user.id
    elsif user.role == 'homeowner'
      homeowner = user.homeowner
      if homeowner.nil?
        return render json: { error: "Homeowner profile not found" }, status: :not_found
      end
      project_params[:homeowner_id] = homeowner.id
    else
      return render json: { error: "Only homeowners and contractors can create projects" }, status: :forbidden
    end
    
    # Set default status
    project_params[:status] = 'open' unless project_params[:status]
    
    project = Project.new(project_params)
    
    if project.save
      render json: {
        message: "Project created successfully",
        project: project_to_hash(project)
      }, status: :created
    else
      render json: { 
        error: "Failed to create project",
        errors: project.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: "Server error: #{e.message}" }, status: :internal_server_error
  end
  
  def user_projects
    user_id = params[:user_id]
    
    if user_id.blank?
      return render json: { error: "User ID is required" }, status: :bad_request
    end
    
    user = User.find_by(id: user_id)
    if user.nil?
      return render json: { error: "User not found" }, status: :not_found
    end
    
    # Find projects based on user role
    if user.role == 'contractor'
      projects = Project.where(contractor_id: user.id)
    elsif user.role == 'homeowner'
      homeowner = user.homeowner
      projects = homeowner ? Project.where(homeowner_id: homeowner.id) : []
    else
      projects = []
    end
    
    render json: projects.map { |p| project_to_hash(p) }
  end
  
  def project_details
    project_id = params[:id]
    project = Project.find_by(id: project_id)
    
    if project
      render json: project_to_hash(project)
    else
      render json: { error: "Project not found" }, status: :not_found
    end
  end
  
  def update
    project = Project.find_by(id: params[:id])
    
    if project.nil?
      render json: { error: "Project not found" }, status: :not_found
    else
      project_params = params.permit(:title, :description, :trade_type, :budget, :location, 
                                      :preferred_date, :bidding_increments, :status).to_h.symbolize_keys
      
      # Handle preferred_date conversion
      if project_params[:preferred_date].is_a?(String) && project_params[:preferred_date].present?
        begin
          project_params[:preferred_date] = Date.parse(project_params[:preferred_date])
        rescue ArgumentError
          project_params[:preferred_date] = nil
        end
      end
      project_params[:preferred_date] = nil if project_params[:preferred_date].blank?
      
      if project.update(project_params)
        render json: {
          message: "Project updated successfully",
          project: project_to_hash(project)
        }
      else
        render json: { 
          error: "Failed to update project",
          errors: project.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
  
  def publish
    project = Project.find_by(id: params[:id])
    
    if project.nil?
      render json: { error: "Project not found" }, status: :not_found
    else
      project.update(status: 'open')
      
      render json: {
        message: "Project published successfully",
        project_id: project.id,
        status: project.status
      }
    end
  end
  
  private
  
  def project_to_hash(project)
    {
      id: project.id,
      project_id: project.id,  # Frontend expects project_id
      title: project.title,
      description: project.description,
      trade_type: project.trade_type,
      budget: project.budget,
      location: project.location,
      preferred_date: project.preferred_date,
      status: project.status,
      bidding_increments: project.bidding_increments,
      timespan: project.timespan,
      requirements: project.requirements,
      contractor_id: project.contractor_id,
      homeowner_id: project.homeowner_id,
      assigned_id: project.assigned_id,
      created_at: project.created_at,
      updated_at: project.updated_at,
      bid_count: project.bids.count
    }
  end
end
