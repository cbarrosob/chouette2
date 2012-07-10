class CleanUp
  include ActiveModel::Validations  
  include ActiveModel::Conversion  
  extend ActiveModel::Naming
  
    
  attr_accessor :expected_date, :keep_lines, :keep_stops , :keep_companies, :keep_networks
  attr_accessor :time_table_count,:vehicle_journey_count,:journey_pattern_count,:route_count,:line_count
  attr_accessor :stop_count,:company_count,:network_count
  
  validates_presence_of :expected_date

  def initialize(attributes = {})
    attributes.each do |name, value|  
      send("#{name}=", value)  
    end  
  end  
    
  def persisted?  
    false  
  end 

  def notice
    notice = Array.new
    notice << t('clean_ups.success_tm', :count => clean_up.time_table_count.to_s)
    if (clean_up.vehicle_journey_count > 0) 
      notice << t('clean_ups.success_vj', :count => clean_up.vehicle_journey_count.to_s)
    end   
    if (clean_up.journey_pattern_count > 0) 
      notice << t('clean_ups.success_jp', :count => clean_up.journey_pattern_count.to_s)
    end   
    if (clean_up.route_count > 0) 
      notice << t('clean_ups.success_r', :count => clean_up.route_count.to_s)
    end   
    if (clean_up.line_count > 0) 
      notice << t('clean_ups.success_l', :count => clean_up.line_count.to_s)
    end   
    if (clean_up.company_count > 0) 
      notice << t('clean_ups.success_c', :count => clean_up.company_count.to_s)
    end   
    if (clean_up.network_count > 0) 
      notice << t('clean_ups.success_n', :count => clean_up.network_count.to_s)
    end   
    if (clean_up.stop_count > 0) 
      notice << t('clean_ups.success_sa', :count => clean_up.stop_count.to_s)
    end 
    notice  

  end

  def clean
    
    # find and remove time_tables 
    tms = Chouette::TimeTable.expired_on(Date.parse(expected_date))
    self.time_table_count = tms.size
    tms.each do |tm|
      tm.destroy
    end
    # remove vehiclejourneys without timetables
    self.vehicle_journey_count = 0
    Chouette::VehicleJourney.find_each do |vj|
      if vj.time_tables.size == 0
        self.vehicle_journey_count += 1
        vj.destroy
      end
    end
    # remove journeypatterns without vehicle journeys
    self.journey_pattern_count = 0
    Chouette::JourneyPattern.find_each do |jp|
      if jp.vehicle_journeys.size == 0
        self.journey_pattern_count += 1
        jp.destroy
      end
    end
    # remove routes without journeypatterns 
    self.route_count = 0
    Chouette::Route.find_each do |r|
      if r.journey_patterns.size == 0
        self.route_count += 1
        r.destroy
      end
    end
    # if asked remove lines without routes
    self.line_count = 0
    if keep_lines == "0" 
      Chouette::Line.find_each do |l|
        if l.routes.size == 0
          self.line_count += 1
          l.destroy
        end
      end
    end
    # if asked remove stops without children (recurse) 
    self.stop_count = 0
    if keep_stops == "0" 
      Chouette::StopArea.find_each(:conditions => { :area_type => "BoardingPosition" }) do |bp|
        if bp.stop_points.size == 0
          self.stop_count += 1
          bp.destroy
        end
      end
      Chouette::StopArea.find_each(:conditions => { :area_type => "Quay" }) do |q|
        if q.stop_points.size == 0
          self.stop_count += 1
          q.destroy
        end
      end
      Chouette::StopArea.find_each(:conditions => { :area_type => "CommercialStopPoint" }) do |csp|
        if csp.children.size == 0
          self.stop_count += 1
          csp.destroy
        end
      end
      Chouette::StopArea.find_each(:conditions => { :area_type => "StopPlace" }) do |sp|
        if sp.children.size == 0
          self.stop_count += 1
          sp.destroy
        end
      end
      Chouette::StopArea.find_each(:conditions => { :area_type => "ITL" }) do |itl|
        if itl.routing_stops.size == 0
          self.stop_count += 1
          itl.destroy
        end
      end
    end
    # if asked remove companies without lines or vehicle journeys
    self.company_count = 0
    if keep_companies == "0" 
      Chouette::Company.find_each do |c|
        if c.lines.size == 0
          self.company_count += 1
          c.destroy
        end
      end
    end
    
    # if asked remove networks without lines
    self.network_count = 0
    if keep_networks == "0" 
      Chouette::Network.find_each do |n|
        if n.lines.size == 0
          self.network_count += 1
          n.destroy
        end
      end
    end
    
  end
  
end