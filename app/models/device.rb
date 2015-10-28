require 'open-uri'
require 'geohash'

class Device < ActiveRecord::Base

  include Workflow
  workflow do
    state :active do
      event :archive, :transitions_to => :archived
    end
    state :archived do
      event :activate, :transitions_to => :active
    end
  end

  # belongs_to :owner
  belongs_to :kit
  belongs_to :owner, class_name: 'User'

  has_many :devices_tags, dependent: :destroy
  has_many :tags, through: :devices_tags
  has_many :components, as: :board
  has_many :sensors, through: :components


  validates_presence_of :name, :owner, on: :create
  validates_uniqueness_of :name, scope: :owner_id, on: :create
  validate :banned_name
  # validates_presence_of :mac_address, :name

  validates_uniqueness_of :mac_address, allow_nil: true, on: :create
  validates_format_of :mac_address, with: /\A([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\z/, allow_nil: true

  default_scope { with_active_state.includes(:owner) }

  include PgSearch
  multisearchable :against => [:name, :description, :city, :country_name]#, associated_against: { owner: { :username }

  before_save :calculate_geohash
  after_validation :do_geocoding
  # after_initialize :set_default_name

  store_accessor :location,
    :address,
    :city,
    :postal_code,
    :state,
    :state_code,
    :country,
    :country_code

  store_accessor :meta,
    :elevation,
    :exposure,
    :firmware_version,
    :smart_cal,
    :debug_push,
    :enclosure_type

  before_save :set_elevation

  # reverse_geocoded_by :latitude, :longitude
  reverse_geocoded_by :latitude, :longitude do |obj, results|
    if geo = results.first
      obj.address = geo.address
      obj.city = geo.city
      obj.postal_code = geo.postal_code
      obj.state = geo.state
      obj.state_code = geo.state_code
      obj.country = geo.country
      obj.country_code = geo.country_code
    end
  end
  # these get overridden the device is a kit

  def find_component_by_sensor_id sensor_id
    components.where(sensor_id: sensor_id).first
  end

  def find_sensor_id_by_key sensor_key
    kit.sensor_map[sensor_key.to_s] rescue nil
  end

  def find_sensor_key_by_id sensor_id
    kit.sensor_map.invert[sensor_id] rescue nil
  end

  def user_tags
    tags.map(&:name)
  end

  def user_tags=(tag_names)
    self.tags = tag_names.split(",").map do |n|
      Tag.find_by!(name: n.strip)
    end
  end

  def self.with_user_tags(tag_name)
    Tag.find_by!(name: tag_name.split('|').map(&:strip)).devices
  end

  # temporary kit getter/setter
  def kit_version
    if self.kit_id
      if self.kit_id == 2
        "1.0"
      elsif self.kit_id == 3
        "1.1"
      end
    end
  end

  def kit_version=(kv)
    if kv == "1.0"
      self.kit_id = 2
    elsif kv == "1.1"
      self.kit_id = 3
    end
  end

  # delegate :username, :to => :owner, :prefix => true

  def owner_username
    owner.username if owner
  end

  def country_name
    if country_code =~ /\w{2}/
      ISO3166::Country.new(country_code).name
    end
  end

  def system_tags
    [
      exposure, # indoor / outdoor
      ('new' if created_at > 1.week.ago), # new
      ((last_recorded_at.present? and last_recorded_at > 10.minutes.ago) ? 'online' : 'offline') # state
    ].reject(&:blank?).sort
  end

  def to_s
    name
  end

  def added_at
    created_at
  end

  def last_reading_at
    last_recorded_at
  end

  def firmware
    if firmware_version.present?
      "sck:#{firmware_version}"
    end
  end

  def components
    kit ? kit.components : super
  end

  def sensors
    kit ? kit.sensors : super
  end

  def status
    data.present? ? state : 'new'
  end

  def state
    if data.present?
      'has_published'
    elsif mac_address.present?
      'never_published'
    else
      'not_configured'
    end
  end

  def formatted_data
    s = {
      recorded_at: last_recorded_at,
      added_at: last_recorded_at,
      # calibrated_at: updated_at,
      location: {
        ip: nil,
        exposure: exposure,
        elevation: elevation.try(:to_i) ,
        latitude: latitude,
        longitude: longitude,
        geohash: geohash,
        city: city,
        country_code: country_code,
        country: country
      },
      sensors: []
    }

    sensors.sort_by(&:name).each do |sensor|
      sa = sensor.attributes
      sa = sa.merge(
        value: (data ? data["#{sensor.id}"] : nil),
        raw_value: (data ? data["#{sensor.id}_raw"] : nil),
        prev_value: (old_data ? old_data["#{sensor.id}"] : nil),
        prev_raw_value: (old_data ? old_data["#{sensor.id}_raw"] : nil)
      )
      s[:sensors] << sa
    end

    return s
  end

private

  def calculate_geohash
    # include ActiveModel::Dirty
    # if latitude.changed? or longitude.changed?
    if latitude.is_a?(Float) and longitude.is_a?(Float)
      self.geohash = GeoHash.encode(latitude, longitude)
    end
  end

  def banned_name
    if name.present? and (Smartcitizen::Application.config.banned_words.include? name.downcase)
      # name.split.map(&:downcase).map(&:strip)).any?
      errors.add(:name, "is reserved")
    end
  end

  # def set_default_name
  #   self.name ||= "My SCK"
  # end

  def set_elevation
    begin
      if elevation.blank? and (latitude and longitude)
        response = open("https://maps.googleapis.com/maps/api/elevation/json?locations=#{latitude},#{longitude}&key=#{ENV['google_api_key']}").read
        self.elevation = JSON.parse(response)['results'][0]['elevation'].to_i
      end
    rescue Exception => e
      # notify_airbrake(e)
    end
  end

  def do_geocoding
    reverse_geocode if (latitude_changed? or longitude_changed?) and city.blank?
  end

end


# REDIS
# online_kits = [12,13,4,546,45,4564,46,75,68,97] - TTL 15 minutes? // last_recorded_at
# online? - online_kits.include?(id)
# offline? - !online_kits.include?(id)

# exposure - indoor / outdoor
# search by name, city & description
# date range - granulation hour/day/week/month/year/lifetime
# filter by:
#   online
#   offline
#   kit type
#   firmware version
#   ...
