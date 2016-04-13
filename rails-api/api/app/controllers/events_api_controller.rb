class EventsApiController < ApiController

  def index
    render json: user_events
  end

  def create
    evt = Event.new
    evt.title = params[:title]
    evt.start = params[:start]
    evt.end = params[:end]
    evt.group = params[:group]
    evt.save
    render json: user_events
  end

  def user_events
    user_groups = session[:user_groups]
    Event.all.select {|evt| evt.group.blank? || user_groups.include?(evt.group) }
  end

end
