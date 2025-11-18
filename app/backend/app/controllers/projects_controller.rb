class ProjectsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :user_projects, :project_details]
  
  def new
    # Display the form for creating a new project
  end
  
  def index
    # List all projects for a user
  end
  
  def show
    # Show a specific project
  end
  
  def create
    # Get user_id from params
    user_id = params[:user_id]
    
    if user_id.blank?
      return render json: { error: "User ID is required" }, status: :unauthorized
    end
    
    # Create project
    project_params = params.permit(:title, :description, :trade_type, :budget, :location, :preferred_date).to_h.symbolize_keys
    project_params[:user_id] = user_id
    
    project = Project.new(project_params)
    
    if project.save
      render json: {
        message: "Project created successfully",
        project: project.to_hash
      }, status: :created
    else
      render json: { error: "Failed to create project" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: "Server error: #{e.message}" }, status: :internal_server_error
  end
  
  def user_projects
    user_id = params[:user_id]
    
    if user_id.blank?
      return render json: { error: "User ID is required" }, status: :bad_request
    end
    
    projects = Project.find_by_user_id(user_id)
    
    render json: projects.map(&:to_hash)
  end
  
  def project_details
    project_id = params[:id]
    project = Project.find_by_id(project_id)
    
    if project
      render json: project.to_hash
    else
      render json: { error: "Project not found" }, status: :not_found
    end
  end
end
