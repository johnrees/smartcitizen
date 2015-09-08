class LegacyDevice < MySQL

  self.table_name = 'devices'
  belongs_to :user, class_name: 'LegacyUser'

  attr_accessor :posts

  # should be moved to sck class
  KEYS = {
    '10': 'bat',
    '17': 'bat',
    '16': 'co',
    '9': 'co',
    '13': 'hum',
    '5': 'hum',
    '14': 'light',
    '6': 'light',
    '21': 'nets',
    '15': 'no2',
    '8': 'no2',
    '7': 'noise',
    '11': 'panel',
    '18': 'panel',
    '12': 'temp',
    '4': 'temp'
  }

  def as_json include_posts=true
    hash = {}
    cols = %w(id title description location city country exposure elevation title location geo_lat geo_long created last_insert_datetime)
    cols.map{ |c| hash[c] = self[c].to_s }

    if include_posts
      if device = Device.find(id) and device.data
        posts = {}
        posts['timestamp'] = device.data[''].to_s.gsub("T", " ").gsub("Z", " UTC")
        device.data.select{|d| Float(d) rescue false }.each do |key,value|
          # Rails.logger.info KEYS
          posts[KEYS[key.to_sym]] = value
        end
        posts['insert_datetime'] = device.last_recorded_at.to_s
        hash['posts'] = [posts]
      else
        hash['posts'] = false
      end
    end

    hash
  end

  def as_day date
    h = as_json(true)
    # h['posts'] = []
    h['posts'][0].except!('insert_datetime').except!('timestamp')
    h['posts'][0]['date'] = "#{date} UTC"
    return h
  end

  def as_hour date
    h = as_day(date)
    h['posts'] = Kairos.legacy_query({rollup: '1h', device_id: id, sensor_ids: Device.find(id).kit.sensors.pluck(:id)  })
    # h['posts'][0]['hour'] = "11"
    return h
  end

end