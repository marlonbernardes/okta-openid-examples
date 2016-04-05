class EventsApiController < ApiController

  def index
    render json: Event.all
  end

  def create
    evt = Event.new
    evt.title = params[:title]
    evt.start = params[:start]
    evt.end = params[:end]
    evt.type = params[:type]
    evt.save
    render json: Event.all
  end

end
