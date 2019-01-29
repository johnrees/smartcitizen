# This is an SCK (referred to as a 'Kit' in the frontend).
# It's called Device and not Kit or SCK because it's expected that the platform
# will support different kinds of hardware in the future (phones, arduino etc).

require 'open-uri'
require 'geohash'

class Device < ActiveRecord::Base

  default_scope { with_active_state.includes(:owner) }

  include Workflow
  include ArchiveWorkflow
  include PgSearch
  include CountryMethods

  multisearchable :against => [:name, :description, :city, :country_name], if: :active?

  belongs_to :kit
  belongs_to :owner, class_name: 'User'

  has_many :devices_tags, dependent: :destroy
  has_many :tags, through: :devices_tags
  has_many :components, as: :board
  has_many :sensors, through: :components

  validates_presence_of :name, :owner, on: :create
  #validates_uniqueness_of :name, scope: :owner_id, on: :create

  validates_uniqueness_of :device_token, allow_nil: true

  validates_format_of :mac_address,
    with: /\A([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\z/, allow_nil: true

  before_save :nullify_other_mac_addresses, if: :mac_address
  before_save :calculate_geohash
  after_validation :do_geocoding

  store_accessor :location,
    :address,
    :city,
    :postal_code,
    :state_name,
    :state_code,
    :country_code

  store_accessor :meta,
    :elevation,
    :exposure,
    :firmware_version,
    :smart_cal,
    :debug_push,
    :enclosure_type

  alias_attribute :added_at, :created_at
  alias_attribute :last_reading_at, :last_recorded_at

  before_save :set_state

  reverse_geocoded_by :latitude, :longitude do |obj, results|
    # Nominatim has a quota of 1 req / second
    if geo = results.first
      obj.address = geo.address
      obj.city = geo.city
      obj.postal_code = geo.postal_code
      obj.state_name = geo.state
      obj.state_code = geo.state_code
      obj.country_code = geo.country_code
    end
  end

  def sensor_keys
    # will be changed when different kinds of device added
    %w(temp bat co hum light nets no2 noise panel)
  end

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

  def owner_username
    owner.username if owner
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

  def archive
    update_attributes({mac_address: nil, old_mac_address: mac_address})
  end

  def unarchive
    unless Device.unscoped.where(mac_address: old_mac_address).exists?
      update_attributes({mac_address: old_mac_address, old_mac_address: nil})
    end
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

  def soft_state
    if data.present?
      'has_published'
    elsif mac_address.present? || device_token.present?
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
        country: country_name,
        timezone_utc_offset: utc_offset
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

  def self.geocode_all_without_location
    Device.where(location: "{}").where.not(latitude: nil).each do |device|
      device.reverse_geocode
      device.save validate: false
      sleep(1)
    end
  end

  def set_version_if_required! identifier
    if identifier and (identifier == "1.1" or identifier == "1.0") # and !device.kit_id
      if self.kit_version.blank? or self.kit_version != identifier
        self.kit_version = identifier
        self.save validate: false
      end
    end
  end

  def remove_mac_address_for_newly_registered_device!
    update_attributes(old_mac_address: mac_address, mac_address: nil)
  end

  private

    def set_state
      self.state = self.soft_state
    end

    def calculate_geohash
      # include ActiveModel::Dirty
      # if latitude.changed? or longitude.changed?
      if latitude.is_a?(Float) and longitude.is_a?(Float)
        self.geohash = GeoHash.encode(latitude, longitude)
      end
    end

    def do_geocoding
      reverse_geocode if (latitude_changed? or longitude_changed?) or city.blank?
      get_timezone if (latitude_changed? or longitude_changed?)
    end

    def get_timezone
      timezone = Timezone.lookup(latitude, longitude)

      if timezone
        self.utc_offset = timezone.utc_offset
      end
    end

    def nullify_other_mac_addresses
      if mac_address_changed?
        Device.unscoped.where(mac_address: mac_address).map(&:remove_mac_address_for_newly_registered_device!)
      end
    end

end
